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
// Also serves a config health check (`{"probe": true}`) so the Play setup can be
// validated without making a real purchase — see runProbe.
//
// Deploy WITH jwt verification (the caller is a signed-in user):
//   supabase functions deploy verify-play-purchase
//
// Required secrets (supabase secrets set ...):
//   GOOGLE_PLAY_PACKAGE_NAME          — e.g. com.ledgidy.pos
//   GOOGLE_PLAY_SERVICE_ACCOUNT_JSON  — SA key JSON w/ androidpublisher access.
//                                       Raw JSON or base64 (base64 is safer:
//                                       it survives shell/dashboard quoting).
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY (platform-provided)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  acknowledgeSubscription,
  decideFromState,
  getAccessToken,
  getSubscription,
  listSubscriptionProductIds,
  parseServiceAccount,
  PlayApiError,
  sha256Hex,
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

/// Machine-readable fault classes. The client keys its retry policy and its
/// wording off `code`, never off the free-text message.
///
/// `play_config` is the one that matters: it means WE are misconfigured, so no
/// client retry can ever succeed. Saying "retrying automatically" there would be
/// a lie that keeps a charged user waiting until Google's 3-day auto-refund.
const CODE_CONFIG = "play_config";
const CODE_TRANSIENT = "play_transient";

/// The token belongs to a subscription that a newer purchase replaced. Play
/// keeps handing the old token back for a while after a plan change, so this is
/// routine bookkeeping — the client must stay silent about it rather than
/// reporting a purchase failure over an upgrade that worked.
const CODE_SUPERSEDED = "play_superseded";

/// A stage tag on every server-side failure, so one log line names the fix
/// instead of an opaque 500. Also returned to the client for support triage.
function failure(
  stage: string,
  code: string,
  detail: string,
  status: number,
): Response {
  console.error(`verify-play-purchase [${stage}/${code}] ${detail}`);
  return json({
    error: code === CODE_CONFIG
      ? "Billing is temporarily misconfigured"
      : "Verification could not complete",
    code,
    stage,
    detail,
  }, status);
}

interface Body {
  product_id?: string;
  purchase_token?: string;

  /// Config health check: run every setup check and report, without needing a
  /// purchase. See runProbe.
  probe?: boolean;
}

interface ProbeCheck {
  stage: string;
  ok: boolean;
  detail: string;
}

/// Answers "is Play billing correctly configured?" without spending real money.
///
/// Every setup mistake this project actually hit — a truncated service-account
/// secret, a service account created in GCP but never invited to Play Console,
/// a package-name mismatch, SKUs missing from `play_product_map` — previously
/// surfaced only when a paying user tripped over it, which made each diagnostic
/// cycle cost a live transaction. This walks the same path a real verify takes,
/// stopping at the first failure since every later check depends on it.
///
/// Returns 200 even when checks fail: the caller renders the list, and a partial
/// result is the diagnosis.
// deno-lint-ignore no-explicit-any
async function runProbe(
  admin: any,
  packageName: string,
  saJson: string,
): Promise<ProbeCheck[]> {
  const checks: ProbeCheck[] = [];

  // Length only — never the key material.
  checks.push({
    stage: "secrets",
    ok: true,
    detail: `package name set, key secret ${saJson.length} chars`,
  });

  let sa;
  try {
    sa = parseServiceAccount(saJson);
    // The service account address is a targetable identifier for a credential
    // that can manage orders on the whole Play account, so it goes to the log
    // (where only we read it) and not into the response.
    console.log(`probe: service account ${sa.client_email}`);
    checks.push({
      stage: "parse_sa",
      ok: true,
      detail: "service account key parsed",
    });
  } catch (e) {
    checks.push({ stage: "parse_sa", ok: false, detail: messageOf(e) });
    return checks;
  }

  let accessToken: string;
  try {
    accessToken = await getAccessToken(sa);
    checks.push({
      stage: "google_token",
      ok: true,
      detail: "service account authenticated with Google",
    });
  } catch (e) {
    checks.push({ stage: "google_token", ok: false, detail: messageOf(e) });
    return checks;
  }

  let playProductIds: string[];
  try {
    playProductIds = await listSubscriptionProductIds(accessToken, packageName);
    checks.push({
      stage: "google_app_access",
      ok: true,
      detail: `Play returned ${playProductIds.length} subscription product(s)`,
    });
  } catch (e) {
    const hint = e instanceof PlayApiError && e.status === 404
      ? " — check GOOGLE_PLAY_PACKAGE_NAME matches the app"
      : e instanceof PlayApiError && (e.status === 401 || e.status === 403)
      ? " — invite this service account in Play Console → Users and permissions"
      : "";
    checks.push({
      stage: "google_app_access",
      ok: false,
      detail: `${messageOf(e)}${hint}`,
    });
    return checks;
  }

  // Cross-check both directions: a mapped SKU Play doesn't know is unbuyable,
  // and a Play SKU we haven't mapped can never be granted.
  const { data: mapRows, error: mapErr } = await admin
    .from("play_product_map")
    .select("product_id")
    .eq("is_active", true);
  if (mapErr) {
    checks.push({
      stage: "product_map",
      ok: false,
      detail: `play_product_map read failed: ${mapErr.code ?? "?"} ${mapErr.message ?? mapErr}`,
    });
    return checks;
  }
  const mapped = new Set<string>(
    (mapRows ?? []).map((r: { product_id: string }) => r.product_id),
  );
  const inPlay = new Set(playProductIds);
  const missingInPlay = [...mapped].filter((id) => !inPlay.has(id));
  const unmapped = [...inPlay].filter((id) => !mapped.has(id));
  // Counts in the response, ids only in the log: the full SKU list includes
  // products that aren't released yet, which is not something to hand back to
  // every tenant that asks.
  const problems: string[] = [];
  if (mapped.size === 0) problems.push("play_product_map is empty");
  if (missingInPlay.length) {
    console.error(`probe: mapped but not in Play — ${missingInPlay.join(", ")}`);
    problems.push(`${missingInPlay.length} mapped product(s) not live in Play`);
  }
  if (unmapped.length) {
    console.error(`probe: in Play but unmapped — ${unmapped.join(", ")}`);
    problems.push(`${unmapped.length} Play product(s) not mapped to a plan`);
  }
  checks.push({
    stage: "product_map",
    ok: problems.length === 0,
    detail: problems.length === 0
      ? `${mapped.size} product(s) mapped and live in Play`
      : problems.join("; "),
  });

  return checks;
}

/// The probe makes two live Google API calls against a service account shared by
/// every tenant. Unthrottled, one owner looping it exhausts that quota and
/// breaks verification for everyone — so results are cached per instance and
/// each business gets one run per window.
const PROBE_TTL_MS = 60_000;
let probeCache: { at: number; checks: ProbeCheck[] } | null = null;
const probeLastRun = new Map<string, number>();

function cachedProbe(): ProbeCheck[] | null {
  if (probeCache && Date.now() - probeCache.at < PROBE_TTL_MS) {
    return probeCache.checks;
  }
  return null;
}

/// True when this business already ran a probe inside the window.
function probeThrottled(bizId: string): boolean {
  const last = probeLastRun.get(bizId);
  const throttled = last !== undefined && Date.now() - last < PROBE_TTL_MS;
  if (!throttled) {
    probeLastRun.set(bizId, Date.now());
    // Keep the map from growing without bound on a long-lived instance.
    if (probeLastRun.size > 500) {
      for (const [k, t] of probeLastRun) {
        if (Date.now() - t >= PROBE_TTL_MS) probeLastRun.delete(k);
      }
    }
  }
  return throttled;
}

function messageOf(e: unknown): string {
  return e instanceof PlayApiError
    ? `${e.message}${e.status ? ` (upstream ${e.status})` : ""}`
    : String(e);
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

/// Is this dead token simply the leftover of a plan change?
///
/// Two independent signals, because neither alone is ordering-proof: the flag is
/// only set once the REPLACING token has been verified, and the subscription
/// pointer only moves once the new plan is granted. Whichever lands first
/// answers the question.
// deno-lint-ignore no-explicit-any
async function isSuperseded(
  admin: any,
  bizId: string,
  purchaseToken: string,
): Promise<boolean> {
  const { data: known } = await admin
    .from("play_purchase_tokens")
    .select("is_current")
    .eq("purchase_token", purchaseToken)
    .maybeSingle();
  if (known && known.is_current === false) return true;

  // The business is live on a DIFFERENT token whose paid period hasn't run out
  // — so this expired one was replaced, not lost.
  const { data: sub } = await admin
    .from("subscriptions")
    .select("play_purchase_token, current_period_end")
    .eq("business_id", bizId)
    .maybeSingle();
  if (!sub?.play_purchase_token || sub.play_purchase_token === purchaseToken) {
    return false;
  }
  const end = sub.current_period_end
    ? Date.parse(sub.current_period_end as string)
    : 0;
  return end > Date.now();
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
  // Fallback for a product with no base plan reported. Ordered, because an
  // unordered limit(1) over a product carrying both a monthly and an annual base
  // plan picks whichever row the planner happens to return — mislabelling the
  // period and putting a 10x-wrong amount in the ledger.
  const { data, error } = await admin
    .from("play_product_map")
    .select("plan_code, plan_version, billing_period")
    .eq("product_id", productId)
    .eq("is_active", true)
    .order("billing_period", { ascending: true })
    .order("plan_version", { ascending: false });
  orThrow(error, "play_product_map lookup");
  const rows = (data ?? []) as PlanRow[];
  if (rows.length > 1) {
    console.error(
      `play_product_map: ${rows.length} active rows for ${productId} with no base_plan_id — resolving to ${rows[0].billing_period}`,
    );
  }
  return rows[0] ?? null;
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
    return failure(
      "secrets",
      CODE_CONFIG,
      `missing ${!packageName ? "GOOGLE_PLAY_PACKAGE_NAME" : ""}${
        !packageName && !saJson ? " and " : ""
      }${!saJson ? "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON" : ""}`,
      500,
    );
  }

  try {
    const body = (await req.json()) as Body;
    const productId = body.product_id?.trim();
    const purchaseToken = body.purchase_token?.trim();
    const isProbe = body.probe === true;

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

    // Config health check — same auth as a real verify (owner with
    // billing.manage), no purchase token, no secrets in the response.
    if (isProbe) {
      // A cached answer is still a correct answer — configuration doesn't drift
      // second to second, and this keeps a repeat tap off Google's quota.
      let checks = cachedProbe();
      if (!checks) {
        if (probeThrottled(bizId)) {
          return json({
            ok: false,
            checks: [{
              stage: "secrets",
              ok: false,
              detail: "Checked a moment ago — try again in a minute.",
            }],
          }, 200);
        }
        checks = await runProbe(admin, packageName, saJson);
        probeCache = { at: Date.now(), checks };
      }
      return json({ ok: checks.every((c) => c.ok), checks }, 200);
    }

    if (!productId || !purchaseToken) {
      return json({ error: "Missing product_id/purchase_token" }, 400);
    }

    // ── Verify with Google (authoritative) ──────────────────────────────────
    // Each Google call carries its own stage, so a failure here names itself in
    // the logs rather than collapsing into the catch-all at the bottom.
    const sa = parseServiceAccount(saJson);
    const accessToken = await getAccessToken(sa);
    const sub = await getSubscription(accessToken, packageName, purchaseToken);

    const decision = decideFromState(sub.subscriptionState);
    if (decision === "expire" || decision === "ignore") {
      // A token we already know was replaced is not a failure — say so plainly.
      // Reporting this as a generic 409 is what made a successful upgrade pop
      // "we couldn't confirm your purchase".
      if (await isSuperseded(admin, bizId, purchaseToken)) {
        return json({
          error: "Subscription superseded",
          code: CODE_SUPERSEDED,
          state: sub.subscriptionState,
        }, 409);
      }
      return json(
        { error: "Subscription not active", state: sub.subscriptionState },
        409,
      );
    }
    if (!sub.expiryTime) return json({ error: "No expiry on subscription" }, 502);

    // Google is the ONLY source for the product id. Falling back to the client's
    // claim (`sub.productId ?? productId`) let a Starter buyer submit a Growth
    // product id whenever Google's response carried no lineItems, and be granted
    // the richer plan.
    if (!sub.productId) {
      return failure(
        "google_get_sub",
        CODE_TRANSIENT,
        `subscriptionsv2 returned no lineItems[0].productId for state ${sub.subscriptionState}`,
        502,
      );
    }
    const effectiveProductId = sub.productId;

    // ── Anti-hijack: the caller must be the buyer ───────────────────────────
    // The client passes sha256(business_id) to Play as the obfuscated account
    // id; Google echoes it back here. Without this comparison, ANY valid
    // unbound token for this package could be claimed by whoever presented it
    // first, permanently locking out the person who actually paid.
    const expectedAccountId = await sha256Hex(bizId);
    if (sub.obfuscatedAccountId && sub.obfuscatedAccountId !== expectedAccountId) {
      console.error(
        `account id mismatch for token ${purchaseToken}: Google says ${sub.obfuscatedAccountId}`,
      );
      return json({ error: "Purchase belongs to a different account" }, 403);
    }
    if (!sub.obfuscatedAccountId) {
      // Purchases made before the client began sending the id have nothing to
      // compare. Allowed, but logged — the count should trend to zero.
      console.error(
        `no obfuscatedExternalAccountId on token ${purchaseToken} (legacy purchase)`,
      );
    }

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
      linked_token: sub.linkedPurchaseToken,
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
          linked_token: sub.linkedPurchaseToken,
          is_current: true,
        })
        .eq("purchase_token", purchaseToken);
      orThrow(touchErr, "play_purchase_tokens refresh");
    }

    // Retire the subscription this one replaced. `is_current` and `linked_token`
    // were declared at launch and never written, so nothing could tell a live
    // token from an upgrade's leftover — which is how a late notification for
    // the old token silently downgraded an upgraded tenant, and how a routine
    // restore of that token surfaced as a purchase failure.
    if (sub.linkedPurchaseToken) {
      const { error: retireErr } = await admin
        .from("play_purchase_tokens")
        .update({ is_current: false })
        .eq("purchase_token", sub.linkedPurchaseToken)
        .eq("business_id", bizId);
      // Non-fatal: the grant below matters more than the bookkeeping, and the
      // stale-token guard in apply_play_subscription is the real backstop.
      if (retireErr) {
        console.error(
          `failed to retire linked token ${sub.linkedPurchaseToken}: ${retireErr.message ?? retireErr}`,
        );
      }
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
      return failure(
        "grant",
        CODE_TRANSIENT,
        `apply_play_subscription: ${grantErr.code ?? "?"} ${grantErr.message ?? grantErr}`,
        500,
      );
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

    // Acknowledge server-side (stops the 3-day auto-refund). Entitlement is
    // already granted, so a failure here must not fail the call — but it must
    // not be swallowed either: an unacknowledged purchase is the one failure
    // that silently costs real money AND blocks every later plan change.
    let acknowledged = true;
    if (sub.acknowledgementState !== "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED") {
      try {
        await acknowledgeSubscription(
          accessToken,
          packageName,
          effectiveProductId,
          purchaseToken,
        );
      } catch (e) {
        acknowledged = false;
        const stage = e instanceof PlayApiError ? e.stage : "google_ack";
        console.error(
          `verify-play-purchase [${stage}/ack_failed] GRANTED BUT NOT ` +
            `ACKNOWLEDGED token=${purchaseToken} — Google will auto-refund in ` +
            `3 days and plan changes will be blocked until then: ${e}`,
        );
      }
    }

    return json({
      ok: true,
      plan_code: planRow.plan_code,
      status: state,
      current_period_end: sub.expiryTime,
      acknowledged,
    }, 200);
  } catch (e) {
    if (e instanceof PlayApiError) {
      return failure(
        e.stage,
        e.isConfigFault ? CODE_CONFIG : CODE_TRANSIENT,
        `${e.message} (upstream status ${e.status})`,
        500,
      );
    }
    return failure("unhandled", CODE_TRANSIENT, String(e), 500);
  }
});
