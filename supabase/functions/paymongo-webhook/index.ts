// M7.1 — PayMongo webhook: turns a confirmed payment into an entitlement grant.
//
// Security:
//   * HMAC-SHA256 signature verification over `${t}.${rawBody}` against
//     PAYMONGO_WEBHOOK_SECRET (constant-time compare), with a 5-minute
//     timestamp tolerance (replay defense).
//   * Idempotency via the billing_webhook_events PK — a re-delivered event is a
//     no-op.
//   * All writes go through the SECURITY DEFINER grant functions
//     (admin_grant_subscription / apply_subscription_addon) — the SAME path a
//     manual admin grant uses, so both produce identical entitlement.
//
// Deploy with `verify_jwt = false` (PayMongo can't send a Supabase JWT):
//   supabase functions deploy paymongo-webhook --no-verify-jwt
//
// Required secrets:
//   PAYMONGO_WEBHOOK_SECRET — the webhook signing secret from PayMongo
//   PAYMONGO_MODE           — "test" | "live" (selects which sig segment: te/li)
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (platform-provided)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// Constant-time hex-string compare.
function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let out = 0;
  for (let i = 0; i < a.length; i++) out |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return out === 0;
}

async function hmacHex(secret: string, message: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(message),
  );
  return [...new Uint8Array(sig)].map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

// Pulls the paid amount (centavos) out of either event shape: payment.paid
// carries it directly; checkout_session.payment.paid nests it under payments[].
function extractPaidCentavos(
  resourceAttrs: Record<string, unknown>,
): number | null {
  const direct = resourceAttrs?.amount;
  if (typeof direct === "number" && Number.isFinite(direct)) return direct;

  const payments = resourceAttrs?.payments;
  if (Array.isArray(payments) && payments.length > 0) {
    const pay = payments[0] as Record<string, unknown>;
    const payAttrs = (pay?.attributes as Record<string, unknown>) ?? {};
    const amt = payAttrs?.amount;
    if (typeof amt === "number" && Number.isFinite(amt)) return amt;
  }
  return null;
}

serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const secret = Deno.env.get("PAYMONGO_WEBHOOK_SECRET");
  const mode = Deno.env.get("PAYMONGO_MODE") ?? "test";
  if (!secret) return json({ error: "Webhook not configured" }, 500);

  const rawBody = await req.text();
  const sigHeader = req.headers.get("Paymongo-Signature") ?? "";

  // Header format: t=<unix>,te=<testsig>,li=<livesig>
  const parts = Object.fromEntries(
    sigHeader.split(",").map((kv) => kv.split("=") as [string, string]),
  );
  const t = parts["t"];
  const provided = mode === "live" ? parts["li"] : parts["te"];
  if (!t || !provided) return json({ error: "Bad signature header" }, 401);

  // Replay window: 5 minutes.
  const skew = Math.abs(Date.now() / 1000 - Number(t));
  if (!Number.isFinite(skew) || skew > 300) {
    return json({ error: "Signature timestamp out of range" }, 401);
  }

  const expected = await hmacHex(secret, `${t}.${rawBody}`);
  if (!timingSafeEqual(expected, provided)) {
    return json({ error: "Invalid signature" }, 401);
  }

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const admin = createClient(url, serviceKey);

  let event: Record<string, unknown>;
  try {
    event = JSON.parse(rawBody);
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const eventId = (event?.data as Record<string, unknown>)?.id as string;
  if (!eventId) return json({ error: "No event id" }, 400);

  // Idempotency: first writer wins; a re-delivery is a silent no-op.
  const { error: dupErr } = await admin
    .from("billing_webhook_events")
    .insert({ provider_event_id: eventId, payload: event });
  if (dupErr) {
    // Unique violation = already processed. Any other error, surface 500.
    if ((dupErr as { code?: string }).code === "23505") {
      return json({ ok: true, duplicate: true }, 200);
    }
    console.error("webhook idempotency insert failed", dupErr);
    return json({ error: "ledger error" }, 500);
  }

  const attrs =
    ((event?.data as Record<string, unknown>)?.attributes) as Record<
      string,
      unknown
    > ?? {};
  const eventType = attrs?.type as string;

  // We only act on successful payments.
  const paidTypes = ["checkout_session.payment.paid", "payment.paid"];
  if (!paidTypes.includes(eventType)) {
    return json({ ok: true, ignored: eventType }, 200);
  }

  // Dig out metadata {business_id, payment_id} from the nested resource.
  const resource = (attrs?.data as Record<string, unknown>) ?? {};
  const resourceAttrs = (resource?.attributes as Record<string, unknown>) ?? {};
  const metadata = (resourceAttrs?.metadata as Record<string, unknown>) ??
    {};
  const paymentId = metadata?.payment_id as string;

  if (!paymentId) {
    console.error("webhook missing payment_id metadata");
    return json({ ok: true, note: "no payment metadata" }, 200);
  }

  // Load our pending payment row (the source of truth for what was bought).
  const { data: payment, error: payErr } = await admin
    .from("billing_payments")
    .select(
      "id, business_id, kind, amount, plan_code, plan_version, billing_period, addon_code, addon_qty, status",
    )
    .eq("id", paymentId)
    .maybeSingle();
  if (payErr || !payment) {
    console.error("webhook payment row not found", paymentId);
    return json({ ok: true, note: "payment row missing" }, 200);
  }

  // Cross-check what PayMongo says was paid against what we quoted. A partial
  // or tampered capture must never grant a full period. Absence of an amount
  // in the payload (shape drift) logs loudly but doesn't block the grant.
  const paidCentavos = extractPaidCentavos(resourceAttrs);
  const expectedCentavos = Math.round(Number(payment.amount) * 100);
  if (paidCentavos !== null && paidCentavos !== expectedCentavos) {
    console.error(
      `webhook amount mismatch: paid ${paidCentavos} != expected ${expectedCentavos} (payment ${payment.id})`,
    );
    await admin.from("billing_payments").update({ status: "failed" }).eq(
      "id",
      payment.id,
    );
    // 200: the mismatch is deterministic — a retry would just fail again.
    return json({ ok: true, note: "amount mismatch — not granted" }, 200);
  }
  if (paidCentavos === null) {
    console.error(
      `webhook: no amount found in payload for payment ${payment.id} — granting on metadata only`,
    );
  }

  // Mark paid (idempotent).
  await admin.from("billing_payments").update({
    status: "paid",
    paid_at: new Date().toISOString(),
  }).eq("id", payment.id);

  try {
    if (payment.kind === "plan") {
      const { error } = await admin.rpc("admin_grant_subscription", {
        p_business: payment.business_id,
        p_plan: payment.plan_code,
        p_version: payment.plan_version ?? 1,
        p_period: payment.billing_period ?? "monthly",
        p_addons: {},
        p_actor: "webhook",
      });
      if (error) throw error;
    } else if (payment.kind === "addon") {
      const { error } = await admin.rpc("apply_subscription_addon", {
        p_business: payment.business_id,
        p_addon: payment.addon_code,
        p_qty: payment.addon_qty ?? 1,
        p_actor: "webhook",
      });
      if (error) throw error;
    }
  } catch (e) {
    console.error("webhook grant failed", e);
    return json({ error: "grant failed" }, 500);
  }

  return json({ ok: true }, 200);
});
