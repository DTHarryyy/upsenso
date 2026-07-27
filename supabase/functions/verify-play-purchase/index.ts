// M7.1 → Google Play Billing: verifies a purchase token with Google, then grants.
//
// The client sends {product_id, purchase_token}; this function is the SOLE
// grantor of Premium access (requirement #7/#8). It:
//   1. Authenticates the caller and resolves their business from the JWT
//      (get_my_business_id) — never trusted from the body — and checks
//      billing.manage (owner bypass built into has_permission).
//   2. Verifies the token against Google (subscriptionsv2.get) — a fabricated
//      or foreign token can never grant.
//   3. Resolves product→plan from play_product_map (config-driven; no hardcoded
//      SKU ids), grants via apply_play_subscription (Supabase = source of truth),
//      records the durable token→business index + a ledger row, and acknowledges
//      server-side so Google never auto-refunds.
//
// Deploy WITH jwt verification (the caller is a signed-in user):
//   supabase functions deploy verify-play-purchase
//
// Required secrets (supabase secrets set ...):
//   GOOGLE_PLAY_PACKAGE_NAME          — e.g. com.ledgidy.pos
//   GOOGLE_PLAY_SERVICE_ACCOUNT_JSON  — SA key JSON w/ androidpublisher access
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY (platform-provided)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  acknowledgeSubscription,
  decideFromState,
  getAccessToken,
  getSubscription,
  parseServiceAccount,
} from "../_shared/google_play.ts";

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
  product_id?: string;
  purchase_token?: string;
}

interface PlanRow {
  plan_code: string;
  plan_version: number;
  billing_period: string;
}

// A DB failure is NOT "product not mapped" — conflating the two is what made a
// missing service_role GRANT surface in-app as "Unknown product". Throw so the
// caller answers 500 with the real cause instead of a misleading 400.
// deno-lint-ignore no-explicit-any
function orThrow(error: any, what: string): void {
  if (!error) return;
  throw new Error(`${what}: ${error.code ?? "?"} ${error.message ?? error}`);
}

// deno-lint-ignore no-explicit-any
async function resolvePlan(
  admin: any,
  productId: string,
  basePlanId: string | null,
): Promise<PlanRow | null> {
  if (basePlanId) {
    const { data, error } = await admin
      .from("play_product_map")
      .select("plan_code, plan_version, billing_period")
      .eq("product_id", productId)
      .eq("base_plan_id", basePlanId)
      .eq("is_active", true)
      .maybeSingle();
    orThrow(error, "play_product_map lookup (with base_plan_id)");
    if (data) return data as PlanRow;
  }
  const { data, error } = await admin
    .from("play_product_map")
    .select("plan_code, plan_version, billing_period")
    .eq("product_id", productId)
    .eq("is_active", true)
    .limit(1)
    .maybeSingle();
  orThrow(error, "play_product_map lookup");
  return (data as PlanRow) ?? null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "Missing authorization" }, 401);

  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const packageName = Deno.env.get("GOOGLE_PLAY_PACKAGE_NAME");
  const saJson = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON");
  if (!packageName || !saJson) {
    return json({ error: "Play billing not configured" }, 500);
  }

  try {
    const body = (await req.json()) as Body;
    const productId = body.product_id?.trim();
    const purchaseToken = body.purchase_token?.trim();
    if (!productId || !purchaseToken) {
      return json({ error: "Missing product_id/purchase_token" }, 400);
    }

    // Caller's business + permission — derived server-side, never from the body.
    const userClient = createClient(url, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: bizId, error: bizErr } = await userClient.rpc(
      "get_my_business_id",
    );
    if (bizErr || !bizId) return json({ error: "No active business" }, 403);
    const { data: mayManage, error: permErr } = await userClient.rpc(
      "has_permission",
      { permission_code: "billing.manage" },
    );
    if (permErr || mayManage !== true) {
      return json({ error: "Not allowed to manage billing" }, 403);
    }

    const admin = createClient(url, serviceKey);

    // ── Verify with Google (authoritative) ──────────────────────────────────
    const sa = parseServiceAccount(saJson);
    const accessToken = await getAccessToken(sa);
    const sub = await getSubscription(accessToken, packageName, purchaseToken);

    const decision = decideFromState(sub.subscriptionState);
    if (decision === "expire" || decision === "ignore") {
      return json(
        { error: "Subscription not active", state: sub.subscriptionState },
        409,
      );
    }
    if (!sub.expiryTime) return json({ error: "No expiry on subscription" }, 502);

    // Google's reported product id wins over the client-claimed one.
    const effectiveProductId = sub.productId ?? productId;

    // ── Resolve product → plan (config-driven) ──────────────────────────────
    const planRow = await resolvePlan(admin, effectiveProductId, sub.basePlanId);
    if (!planRow) {
      console.error(
        `No play_product_map for ${effectiveProductId}/${sub.basePlanId}`,
      );
      return json({ error: "Unknown product" }, 400);
    }

    // Anti-hijack: a token already bound to a DIFFERENT business is refused.
    // A read failure here must NOT be read as "unbound" — that would turn the
    // hijack check into a no-op.
    const { data: existingTok, error: tokErr } = await admin
      .from("play_purchase_tokens")
      .select("business_id")
      .eq("purchase_token", purchaseToken)
      .maybeSingle();
    orThrow(tokErr, "play_purchase_tokens lookup");
    if (existingTok && existingTok.business_id !== bizId) {
      console.error(`token already bound to another business (${purchaseToken})`);
      return json(
        { error: "Purchase already registered to another account" },
        409,
      );
    }

    // Claim the token BEFORE granting. The read above is advisory only — two
    // businesses verifying the same fresh token concurrently would both see it
    // unbound and both grant. The purchase_token PRIMARY KEY is the real
    // referee: a plain insert (not upsert) makes the loser fail with 23505.
    const { error: claimErr } = await admin.from("play_purchase_tokens").insert({
      purchase_token: purchaseToken,
      business_id: bizId,
      product_id: effectiveProductId,
      base_plan_id: sub.basePlanId,
      is_current: true,
    });
    if (claimErr) {
      if ((claimErr as { code?: string }).code !== "23505") {
        orThrow(claimErr, "play_purchase_tokens claim");
      }
      // Already claimed — ours (a re-verify / restore) or someone else's.
      const { data: owner, error: ownerErr } = await admin
        .from("play_purchase_tokens")
        .select("business_id")
        .eq("purchase_token", purchaseToken)
        .maybeSingle();
      orThrow(ownerErr, "play_purchase_tokens re-read");
      if (!owner || owner.business_id !== bizId) {
        console.error(`token race lost / foreign token (${purchaseToken})`);
        return json(
          { error: "Purchase already registered to another account" },
          409,
        );
      }
      // Ours: refresh the product linkage (an upgrade reuses this path).
      const { error: touchErr } = await admin
        .from("play_purchase_tokens")
        .update({
          product_id: effectiveProductId,
          base_plan_id: sub.basePlanId,
          is_current: true,
        })
        .eq("purchase_token", purchaseToken);
      orThrow(touchErr, "play_purchase_tokens refresh");
    }

    // ── Grant (Supabase = source of truth) ──────────────────────────────────
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
      p_actor: "google_play",
    });
    if (grantErr) {
      console.error("apply_play_subscription failed", grantErr);
      return json({ error: "grant failed" }, 500);
    }

    // Ledger row for the in-app history (list price; Play holds the true receipt).
    // Non-fatal from here on: entitlement is already granted, and failing the
    // whole call would strand an acknowledged purchase over a history row.
    const { data: planPrice, error: priceErr } = await admin
      .from("plans")
      .select("price_monthly")
      .eq("code", planRow.plan_code)
      .eq("version", planRow.plan_version)
      .maybeSingle();
    if (priceErr) console.error("plans price lookup failed", priceErr);
    const monthly = Number(planPrice?.price_monthly ?? 0);
    const amount = planRow.billing_period === "annual" ? monthly * 10 : monthly;
    const { error: ledgerErr } = await admin.from("billing_payments").insert({
      business_id: bizId,
      provider: "google_play",
      provider_ref: purchaseToken,
      kind: "plan",
      plan_code: planRow.plan_code,
      plan_version: planRow.plan_version,
      billing_period: planRow.billing_period,
      product_id: effectiveProductId,
      base_plan_id: sub.basePlanId,
      purchase_token: purchaseToken,
      amount,
      currency: "PHP",
      status: "paid",
      paid_at: new Date().toISOString(),
    });
    if (ledgerErr) console.error("billing_payments insert failed", ledgerErr);

    // Acknowledge server-side (stops the 3-day auto-refund). Non-fatal.
    if (sub.acknowledgementState !== "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED") {
      try {
        await acknowledgeSubscription(
          accessToken,
          packageName,
          effectiveProductId,
          purchaseToken,
        );
      } catch (e) {
        console.error("acknowledge failed (non-fatal)", e);
      }
    }

    return json({
      ok: true,
      plan_code: planRow.plan_code,
      status: state,
      current_period_end: sub.expiryTime,
    }, 200);
  } catch (e) {
    console.error("verify-play-purchase error", e);
    return json({ error: String(e) }, 500);
  }
});
