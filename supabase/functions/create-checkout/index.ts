// M7.1 — Creates a PayMongo Checkout Session for a plan or add-on purchase.
//
// The client only names WHAT it wants to buy (plan code / add-on code); the
// AMOUNT is computed here from the plans/plan_addons tables — a tampered client
// can never set its own price. The caller's business is derived server-side
// from their JWT (get_my_business_id), never trusted from the body.
//
// Test mode: with PAYMONGO_MODE=test the sk_test_ key is used and the payment
// row is stamped is_test=true — the whole flow works before live acquiring is
// activated. Going live = flip PAYMONGO_MODE + set the live key. No code change.
//
// Required secrets (supabase secrets set ...):
//   PAYMONGO_SECRET_KEY   — sk_test_... or sk_live_...
//   PAYMONGO_MODE         — "test" | "live"   (defaults to "test")
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY (platform-provided)
//   CHECKOUT_SUCCESS_URL, CHECKOUT_CANCEL_URL — where PayMongo redirects back

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

interface Body {
  kind?: "plan" | "addon";
  plan_code?: string;
  plan_version?: number;
  billing_period?: "monthly" | "annual";
  addon_code?: string;
  addon_qty?: number;
}

const DISCOUNT_MONTHS_FREE = 2; // annual = 10 months (§5.1)

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "Missing authorization" }, 401);

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const secretKey = Deno.env.get("PAYMONGO_SECRET_KEY");
  const mode = Deno.env.get("PAYMONGO_MODE") ?? "test";
  if (!secretKey) return json({ error: "Payments not configured" }, 500);

  try {
    const body = (await req.json()) as Body;
    const kind = body.kind ?? "plan";

    // Resolve the caller's business from their JWT (never from the body).
    const userClient = createClient(url, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: bizId, error: bizErr } = await userClient.rpc(
      "get_my_business_id",
    );
    if (bizErr || !bizId) return json({ error: "No active business" }, 403);

    const admin = createClient(url, serviceKey);

    // ── Compute the amount server-side ──────────────────────────────────────
    let amountPhp = 0;
    let description = "";
    const paymentRow: Record<string, unknown> = {
      business_id: bizId,
      provider: "paymongo",
      kind,
      currency: "PHP",
      status: "pending",
      is_test: mode === "test",
    };

    if (kind === "plan") {
      const version = body.plan_version ?? 1;
      const period = body.billing_period === "annual" ? "annual" : "monthly";
      const { data: plan, error } = await admin
        .from("plans")
        .select("code, version, name, price_monthly, is_active")
        .eq("code", body.plan_code ?? "")
        .eq("version", version)
        .maybeSingle();
      if (error || !plan || !plan.is_active) {
        return json({ error: "Unknown or inactive plan" }, 400);
      }
      amountPhp = period === "annual"
        ? Number(plan.price_monthly) * (12 - DISCOUNT_MONTHS_FREE)
        : Number(plan.price_monthly);
      description = `${plan.name} (${period})`;
      paymentRow.plan_code = plan.code;
      paymentRow.plan_version = plan.version;
      paymentRow.billing_period = period;
    } else if (kind === "addon") {
      const qty = Math.max(1, Number(body.addon_qty ?? 1));
      const { data: addon, error } = await admin
        .from("plan_addons")
        .select("code, name, price_monthly, is_active")
        .eq("code", body.addon_code ?? "")
        .maybeSingle();
      if (error || !addon || !addon.is_active) {
        return json({ error: "Unknown add-on" }, 400);
      }
      amountPhp = Number(addon.price_monthly) * qty;
      description = `${addon.name} ×${qty}`;
      paymentRow.addon_code = addon.code;
      paymentRow.addon_qty = qty;
    } else {
      return json({ error: "Invalid kind" }, 400);
    }
    paymentRow.amount = amountPhp;

    // Record the pending payment BEFORE hitting PayMongo so the webhook can
    // reconcile by provider_ref.
    const { data: payment, error: payErr } = await admin
      .from("billing_payments")
      .insert(paymentRow)
      .select("id")
      .single();
    if (payErr) return json({ error: "Could not record payment" }, 500);

    // ── Create the PayMongo Checkout Session ────────────────────────────────
    const successUrl = Deno.env.get("CHECKOUT_SUCCESS_URL") ??
      "https://upsenso.pages.dev/billing?status=success";
    const cancelUrl = Deno.env.get("CHECKOUT_CANCEL_URL") ??
      "https://upsenso.pages.dev/billing?status=cancel";

    const pmRes = await fetch("https://api.paymongo.com/v1/checkout_sessions", {
      method: "POST",
      headers: {
        "Authorization": `Basic ${btoa(secretKey + ":")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        data: {
          attributes: {
            payment_method_types: ["qrph", "gcash", "paymaya", "card"],
            line_items: [
              {
                name: description,
                amount: Math.round(amountPhp * 100), // centavos
                currency: "PHP",
                quantity: 1,
              },
            ],
            success_url: successUrl,
            cancel_url: cancelUrl,
            description,
            metadata: {
              business_id: String(bizId),
              payment_id: String(payment.id),
            },
          },
        },
      }),
    });

    if (!pmRes.ok) {
      const detail = await pmRes.text();
      console.error(`PayMongo checkout failed: ${pmRes.status} ${detail}`);
      await admin.from("billing_payments").update({ status: "failed" }).eq(
        "id",
        payment.id,
      );
      return json({ error: "Checkout creation failed" }, 502);
    }

    const pmData = await pmRes.json();
    const checkoutUrl = pmData?.data?.attributes?.checkout_url;
    const sessionId = pmData?.data?.id;
    if (!checkoutUrl) {
      return json({ error: "No checkout URL returned" }, 502);
    }

    await admin.from("billing_payments").update({ provider_ref: sessionId })
      .eq("id", payment.id);

    return json({ checkout_url: checkoutUrl, payment_id: payment.id }, 200);
  } catch (e) {
    console.error("create-checkout error", e);
    return json({ error: String(e) }, 500);
  }
});
