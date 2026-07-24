// M7.1 → Google Play Billing: Real-Time Developer Notifications (RTDN) handler.
//
// Google Play → Pub/Sub topic → push subscription → this function, authenticated
// by a shared secret in the URL (?secret=...). It keeps entitlement in lockstep
// with Google AFTER the first purchase: renewals extend the period, cancels/
// holds/refunds pause it. Everything funnels into the SAME write path the verify
// function uses (apply_play_subscription / expire_play_subscription).
//
// Robustness: instead of hand-mapping all 13 notification types, non-terminal
// events RE-FETCH the authoritative state (subscriptionsv2.get) and re-apply.
// Terminal events (revoked / expired / voided) expire directly — a dead token
// may 404 on lookup. Idempotent via the billing_webhook_events ledger.
//
// Deploy WITHOUT jwt verification (Pub/Sub can't send a Supabase JWT):
//   supabase functions deploy google-play-rtdn --no-verify-jwt
//
// Required secrets:
//   PLAY_RTDN_SHARED_SECRET           — matches the ?secret= on the push endpoint
//   GOOGLE_PLAY_PACKAGE_NAME, GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (platform-provided)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  decideFromState,
  getAccessToken,
  getSubscription,
  parseServiceAccount,
} from "../_shared/google_play.ts";

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let out = 0;
  for (let i = 0; i < a.length; i++) out |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return out === 0;
}

// Terminal subscription notification types → expire directly (no Google fetch).
const SUBSCRIPTION_REVOKED = 12;
const SUBSCRIPTION_EXPIRED = 13;

// deno-lint-ignore no-explicit-any
async function resolvePlan(admin: any, productId: string, basePlanId: string | null) {
  if (basePlanId) {
    const { data } = await admin
      .from("play_product_map")
      .select("plan_code, plan_version, billing_period")
      .eq("product_id", productId)
      .eq("base_plan_id", basePlanId)
      .eq("is_active", true)
      .maybeSingle();
    if (data) return data;
  }
  const { data } = await admin
    .from("play_product_map")
    .select("plan_code, plan_version, billing_period")
    .eq("product_id", productId)
    .eq("is_active", true)
    .limit(1)
    .maybeSingle();
  return data ?? null;
}

serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  // ── Authenticate the Pub/Sub push ──────────────────────────────────────────
  const expected = Deno.env.get("PLAY_RTDN_SHARED_SECRET");
  if (!expected) return json({ error: "RTDN not configured" }, 500);
  const provided = new URL(req.url).searchParams.get("secret") ?? "";
  if (!timingSafeEqual(expected, provided)) {
    return json({ error: "Unauthorized" }, 401);
  }

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const packageName = Deno.env.get("GOOGLE_PLAY_PACKAGE_NAME");
  const saJson = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON");
  if (!packageName || !saJson) {
    return json({ error: "Play billing not configured" }, 500);
  }
  const admin = createClient(url, serviceKey);

  try {
    // Pub/Sub push envelope: { message: { data(base64), messageId }, subscription }.
    const envelope = await req.json();
    const message = envelope?.message ?? {};
    const messageId = message?.messageId ?? message?.message_id;
    if (!message?.data) return json({ ok: true, note: "no data" }, 200);

    // Idempotency: first writer wins; a redelivery is a silent no-op.
    if (messageId) {
      const { error: dupErr } = await admin
        .from("billing_webhook_events")
        .insert({ provider_event_id: `play:${messageId}`, payload: envelope });
      if (dupErr) {
        if ((dupErr as { code?: string }).code === "23505") {
          return json({ ok: true, duplicate: true }, 200);
        }
        console.error("rtdn ledger insert failed", dupErr);
        return json({ error: "ledger error" }, 500);
      }
    }

    const decoded = JSON.parse(atob(message.data));
    const voided = decoded?.voidedPurchaseNotification;
    const subNote = decoded?.subscriptionNotification;
    const test = decoded?.testNotification;

    if (test) return json({ ok: true, test: true }, 200);

    // ── Refund / chargeback ─────────────────────────────────────────────────
    if (voided?.purchaseToken) {
      return await expireByToken(admin, voided.purchaseToken, "voided");
    }

    if (!subNote?.purchaseToken) {
      return json({ ok: true, note: "unhandled notification" }, 200);
    }

    const purchaseToken = subNote.purchaseToken as string;
    const productIdFromNote = (subNote.subscriptionId as string) ?? null;
    const type = Number(subNote.notificationType);

    // Resolve the tenant from the durable token index (RTDN never carries it).
    const { data: tok } = await admin
      .from("play_purchase_tokens")
      .select("business_id")
      .eq("purchase_token", purchaseToken)
      .maybeSingle();
    if (!tok) {
      // First-purchase RTDN can beat the client verify that registers the token.
      console.error(`rtdn: unknown token ${purchaseToken} (type ${type})`);
      return json({ ok: true, note: "unknown token — client verify will land" }, 200);
    }
    const bizId = tok.business_id as string;

    // Terminal → expire directly (a revoked/expired token may 404 on fetch).
    if (type === SUBSCRIPTION_REVOKED || type === SUBSCRIPTION_EXPIRED) {
      return await expireByToken(
        admin,
        purchaseToken,
        type === SUBSCRIPTION_REVOKED ? "revoked" : "expired",
      );
    }

    // Everything else → re-fetch authoritative state and re-apply.
    const sa = parseServiceAccount(saJson);
    const accessToken = await getAccessToken(sa);
    const sub = await getSubscription(accessToken, packageName, purchaseToken);
    const decision = decideFromState(sub.subscriptionState);

    if (decision === "expire") {
      return await expireByToken(admin, purchaseToken, "state_" + sub.subscriptionState);
    }
    if (decision === "ignore" || !sub.expiryTime) {
      return json({ ok: true, note: `ignored ${sub.subscriptionState}` }, 200);
    }

    const effectiveProductId = sub.productId ?? productIdFromNote ?? "";
    const planRow = await resolvePlan(admin, effectiveProductId, sub.basePlanId);
    if (!planRow) {
      console.error(`rtdn: no play_product_map for ${effectiveProductId}/${sub.basePlanId}`);
      return json({ ok: true, note: "unknown product" }, 200);
    }

    const state = decision === "grant_canceled" ? "canceled" : "active";
    const { error: grantErr } = await admin.rpc("apply_play_subscription", {
      p_business: bizId,
      p_plan: planRow.plan_code,
      p_version: planRow.plan_version,
      p_period: planRow.billing_period,
      p_expiry: sub.expiryTime,
      p_state: state,
      p_product_id: effectiveProductId,
      p_purchase_token: purchaseToken,
      p_actor: "google_play_rtdn",
    });
    if (grantErr) {
      console.error("rtdn apply_play_subscription failed", grantErr);
      return json({ error: "grant failed" }, 500);
    }
    return json({ ok: true, applied: state, type }, 200);
  } catch (e) {
    console.error("google-play-rtdn error", e);
    return json({ error: String(e) }, 500);
  }
});

// deno-lint-ignore no-explicit-any
async function expireByToken(
  admin: any,
  purchaseToken: string,
  reason: string,
): Promise<Response> {
  const { data: tok } = await admin
    .from("play_purchase_tokens")
    .select("business_id")
    .eq("purchase_token", purchaseToken)
    .maybeSingle();
  if (!tok) {
    return json({ ok: true, note: "unknown token — nothing to expire" }, 200);
  }
  const { error } = await admin.rpc("expire_play_subscription", {
    p_business: tok.business_id,
    p_purchase_token: purchaseToken,
    p_reason: reason,
    p_actor: "google_play_rtdn",
  });
  if (error) {
    console.error("rtdn expire_play_subscription failed", error);
    return json({ error: "expire failed" }, 500);
  }
  return json({ ok: true, expired: reason }, 200);
}
