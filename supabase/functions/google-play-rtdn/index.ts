// M7.1 → Google Play Billing: Real-Time Developer Notifications (RTDN) handler.
//
// Google Play → Pub/Sub topic → push subscription → this function. It keeps
// entitlement in lockstep with Google AFTER the first purchase: renewals extend
// the period, cancels/holds/refunds pause it. Everything funnels into the SAME
// write path the verify function uses (apply_play_subscription /
// expire_play_subscription).
//
// AUTHENTICATION — Google's signed OIDC push token, verified against Google's
// public JWKS. The previous scheme put a shared secret in the URL query string,
// which Supabase writes to the edge logs in plaintext on EVERY notification:
// anyone who could read logs could forge a notification, and the terminal types
// revoke a tenant's entitlement outright. The old secret is still accepted while
// PLAY_RTDN_ALLOW_LEGACY=true so the Pub/Sub subscription can be switched over
// without dropping notifications; set it to false and delete the secret after.
//
// Robustness: instead of hand-mapping all 13 notification types, events RE-FETCH
// the authoritative state (subscriptionsv2.get) and act on what Google says —
// including the terminal ones, which used to revoke on the notification's word
// alone. Idempotent via the billing_webhook_events ledger, which is only marked
// done AFTER successful processing so a failed run is retried rather than
// swallowed as a duplicate.
//
// Deploy WITHOUT jwt verification (Pub/Sub can't send a Supabase JWT):
//   supabase functions deploy google-play-rtdn --no-verify-jwt
//
// Required secrets:
//   PLAY_RTDN_PUSH_SA                 — service account email on the Pub/Sub push
//                                       subscription (--push-auth-service-account)
//   PLAY_RTDN_ALLOW_LEGACY            — "true" only during the auth cutover
//   PLAY_RTDN_SHARED_SECRET           — legacy ?secret=, delete after cutover
//   GOOGLE_PLAY_PACKAGE_NAME, GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (platform-provided)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  acknowledgeSubscription,
  decideFromState,
  getAccessToken,
  getSubscription,
  parseServiceAccount,
  PlayApiError,
  verifyGooglePushToken,
} from "../_shared/google_play.ts";
import { evaluateAndPublishPlanAlerts } from "../_shared/plan_alerts.ts";

// Plan alert delivery must never roll back or retry a valid billing mutation.
// deno-lint-ignore no-explicit-any
async function refreshPlanAlerts(admin: any, businessId: string) {
  try {
    await evaluateAndPublishPlanAlerts(admin, businessId, {
      trigger: "entitlement_changed",
    });
  } catch (error) {
    console.error(`rtdn plan-alert evaluation failed for ${businessId}`, error);
  }
}

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

/// OIDC first; the URL secret only while the Pub/Sub subscription is being
/// switched over. Both paths must be explicitly configured — an endpoint that
/// falls open when a secret is missing is worse than one that rejects.
async function authenticatePush(
  req: Request,
): Promise<{ ok: boolean; reason?: string }> {
  const pushSa = Deno.env.get("PLAY_RTDN_PUSH_SA");
  if (pushSa) {
    const result = await verifyGooglePushToken(
      req.headers.get("Authorization"),
      pushSa,
    );
    if (result.ok) return result;
    if (Deno.env.get("PLAY_RTDN_ALLOW_LEGACY") !== "true") return result;
    console.error(`rtdn: OIDC failed (${result.reason}) — trying legacy secret`);
  }

  const expected = Deno.env.get("PLAY_RTDN_SHARED_SECRET");
  if (!expected) {
    return {
      ok: false,
      reason: pushSa ? "OIDC failed and no legacy secret set" : "RTDN not configured",
    };
  }
  const provided = new URL(req.url).searchParams.get("secret") ?? "";
  return timingSafeEqual(expected, provided)
    ? { ok: true }
    : { ok: false, reason: "bad legacy secret" };
}

// Terminal subscription notification types. Still re-checked against Google —
// acting on the notification's word alone let a forged push revoke a live
// subscription, and a genuine one can arrive for a token that was replaced.
const SUBSCRIPTION_REVOKED = 12;
const SUBSCRIPTION_EXPIRED = 13;
const SUBSCRIPTION_RENEWED = 2;

// A DB failure must not be mistaken for "product not mapped" — that silently
// turned a missing GRANT into a 200 no-op and dropped the notification.
// deno-lint-ignore no-explicit-any
function orThrow(error: any, what: string): void {
  if (!error) return;
  throw new Error(`${what}: ${error.code ?? "?"} ${error.message ?? error}`);
}

// deno-lint-ignore no-explicit-any
async function resolvePlan(admin: any, productId: string, basePlanId: string | null) {
  if (basePlanId) {
    const { data, error } = await admin
      .from("play_product_map")
      .select("plan_code, plan_version, billing_period")
      .eq("product_id", productId)
      .eq("base_plan_id", basePlanId)
      .eq("is_active", true)
      .maybeSingle();
    orThrow(error, "play_product_map lookup (with base_plan_id)");
    if (data) return data;
  }
  // Ordered: an unordered limit(1) over a product with both a monthly and an
  // annual base plan returns whichever row the planner picks, mislabelling the
  // period and the ledger amount.
  const { data, error } = await admin
    .from("play_product_map")
    .select("plan_code, plan_version, billing_period")
    .eq("product_id", productId)
    .eq("is_active", true)
    .order("billing_period", { ascending: true })
    .order("plan_version", { ascending: false });
  orThrow(error, "play_product_map lookup");
  const rows = data ?? [];
  if (rows.length > 1) {
    console.error(
      `rtdn: ${rows.length} active map rows for ${productId} with no base_plan_id`,
    );
  }
  return rows[0] ?? null;
}

serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  // ── Authenticate the Pub/Sub push ──────────────────────────────────────────
  const auth = await authenticatePush(req);
  if (!auth.ok) {
    console.error(`rtdn: rejected push — ${auth.reason}`);
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

    // Idempotency. Only a ledger row marked `done` short-circuits: the row used
    // to be written BEFORE processing, so any later failure returned 500, the
    // Pub/Sub retry hit the duplicate check, and the renewal or refund was
    // dropped for good.
    //
    // A message with no id still gets a key — hashing the payload — because
    // `if (messageId)` meant those had no idempotency at all.
    const eventKey = `play:${messageId ?? await hashPayload(message.data)}`;
    const { data: prior, error: priorErr } = await admin
      .from("billing_webhook_events")
      .select("status")
      .eq("provider_event_id", eventKey)
      .maybeSingle();
    orThrow(priorErr, "billing_webhook_events lookup");
    if (prior?.status === "done") {
      return json({ ok: true, duplicate: true }, 200);
    }
    if (!prior) {
      const { error: claimErr } = await admin
        .from("billing_webhook_events")
        .insert({
          provider_event_id: eventKey,
          payload: envelope,
          status: "pending",
        });
      // A concurrent delivery of the same message won the insert; let it finish
      // rather than processing the same notification twice.
      if (claimErr) {
        if ((claimErr as { code?: string }).code === "23505") {
          return json({ ok: true, duplicate: true }, 200);
        }
        // Log the real code — a bare "ledger error" is what hid a 42501
        // permission denial behind an unbounded Pub/Sub retry loop.
        console.error(
          `rtdn ledger insert failed: ${(claimErr as { code?: string }).code} ` +
            `${claimErr.message ?? claimErr}`,
        );
        return json(
          { error: "ledger error", code: (claimErr as { code?: string }).code },
          500,
        );
      }
    }

    /// Mark the notification handled. Anything that returns before this stays
    /// `pending`, so Pub/Sub's retry reprocesses it instead of being told it
    /// already happened.
    const settle = async (body: Record<string, unknown>, status: number) => {
      if (status < 300) {
        const { error } = await admin
          .from("billing_webhook_events")
          .update({ status: "done" })
          .eq("provider_event_id", eventKey);
        if (error) {
          console.error(`rtdn: failed to mark ${eventKey} done: ${error.message}`);
        }
      }
      return json(body, status);
    };

    const decoded = JSON.parse(atob(message.data));
    const voided = decoded?.voidedPurchaseNotification;
    const subNote = decoded?.subscriptionNotification;
    const test = decoded?.testNotification;

    if (test) return await settle({ ok: true, test: true }, 200);

    const sa = parseServiceAccount(saJson);

    // ── Refund / chargeback ─────────────────────────────────────────────────
    // Confirmed against Google first: a voided notification is a revocation, and
    // taking one on trust meant anyone who could forge a push could kill a live
    // tenant's subscription.
    if (voided?.purchaseToken) {
      return await settleWith(
        settle,
        await expireConfirmed(admin, sa, packageName, voided.purchaseToken, "voided"),
      );
    }

    if (!subNote?.purchaseToken) {
      return await settle({ ok: true, note: "unhandled notification" }, 200);
    }

    const purchaseToken = subNote.purchaseToken as string;
    const type = Number(subNote.notificationType);

    // Resolve the tenant from the durable token index (RTDN never carries it).
    const { data: tok, error: tokErr } = await admin
      .from("play_purchase_tokens")
      .select("business_id")
      .eq("purchase_token", purchaseToken)
      .maybeSingle();
    orThrow(tokErr, "play_purchase_tokens lookup");
    if (!tok) {
      // A first-purchase RTDN can beat the client verify that registers the
      // token. 500 so Pub/Sub retries with backoff — by the next attempt the
      // verify has usually landed. Answering 200 here marked the event handled
      // and lost the notification for good.
      console.error(`rtdn: unknown token ${purchaseToken} (type ${type}) — will retry`);
      return json({ error: "unknown token — client verify pending" }, 500);
    }
    const bizId = tok.business_id as string;

    // Terminal types → confirm with Google, then expire. These used to revoke on
    // the notification alone, which made them the highest-value target on the
    // whole endpoint.
    if (type === SUBSCRIPTION_REVOKED || type === SUBSCRIPTION_EXPIRED) {
      return await settleWith(
        settle,
        await expireConfirmed(
          admin,
          sa,
          packageName,
          purchaseToken,
          type === SUBSCRIPTION_REVOKED ? "revoked" : "expired",
        ),
      );
    }

    // Everything else → re-fetch authoritative state and re-apply.
    const accessToken = await getAccessToken(sa);
    const sub = await getSubscription(accessToken, packageName, purchaseToken);
    const decision = decideFromState(sub.subscriptionState);

    if (decision === "expire") {
      return await settleWith(
        settle,
        await expireByToken(admin, purchaseToken, "state_" + sub.subscriptionState),
      );
    }
    if (decision === "ignore" || !sub.expiryTime) {
      return await settle({ ok: true, note: `ignored ${sub.subscriptionState}` }, 200);
    }
    if (!sub.productId) {
      // Same rule as verify: Google's product id or nothing. The old fallback to
      // the notification's subscriptionId let an unverified field pick the plan.
      console.error(`rtdn: no productId on ${purchaseToken} (${sub.subscriptionState})`);
      return json({ error: "no product id from Google" }, 500);
    }

    const effectiveProductId = sub.productId;
    const planRow = await resolvePlan(admin, effectiveProductId, sub.basePlanId);
    if (!planRow) {
      // Retrying can't map a product — that needs a row in play_product_map. Mark
      // it handled so Pub/Sub stops, and shout in the log, which is the only
      // thing that will actually get it fixed.
      console.error(
        `rtdn: NO play_product_map for ${effectiveProductId}/${sub.basePlanId} — ` +
          `business ${bizId} will not receive its plan until this is mapped`,
      );
      return await settle({ ok: true, note: "unknown product" }, 200);
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
    await refreshPlanAlerts(admin, bizId);

    // Acknowledge here too. Verify was the only place that did, and a failed ack
    // there had no server-side retry — Google auto-refunds an unacknowledged
    // purchase after three days and blocks every plan change until then.
    if (
      decision === "grant_active" &&
      sub.acknowledgementState !== "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED"
    ) {
      try {
        await acknowledgeSubscription(
          accessToken,
          packageName,
          effectiveProductId,
          purchaseToken,
        );
      } catch (e) {
        console.error(
          `rtdn: ACK FAILED for ${purchaseToken} — Google may auto-refund: ${e}`,
        );
      }
    }

    // Renewals belong in the ledger. Only the first purchase was ever recorded,
    // so a year-old subscription showed a single payment in its own history.
    if (type === SUBSCRIPTION_RENEWED) {
      await recordRenewal(
        admin,
        bizId,
        planRow,
        effectiveProductId,
        purchaseToken,
        sub,
      );
    }

    return await settle({ ok: true, applied: state, type }, 200);
  } catch (e) {
    // Stage-tagged so a Google-side config fault names itself here too, instead
    // of hiding behind an unbounded Pub/Sub retry loop.
    if (e instanceof PlayApiError) {
      console.error(`google-play-rtdn [${e.stage}] ${e.message} (upstream ${e.status})`);
      return json({ error: "play api", stage: e.stage, status: e.status }, 500);
    }
    console.error("google-play-rtdn error", e);
    return json({ error: String(e) }, 500);
  }
});

/// Idempotency key for a notification Pub/Sub delivered without a messageId.
async function hashPayload(data: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(data),
  );
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("")
    .slice(0, 32);
}

/// Run a handler's Response through `settle` so a success marks the ledger done
/// and a failure leaves it pending for Pub/Sub to retry.
async function settleWith(
  settle: (body: Record<string, unknown>, status: number) => Promise<Response>,
  res: Response,
): Promise<Response> {
  const body = await res.json().catch(() => ({}));
  return await settle(body as Record<string, unknown>, res.status);
}

/// Expire, but only after Google confirms the subscription really is gone.
///
/// A revoke/expire/void notification is the one thing on this endpoint that
/// destroys access, so it must not be taken on the sender's word. A 404 means
/// the token no longer exists at Google, which IS confirmation; any other Google
/// failure leaves entitlement alone and lets Pub/Sub retry.
async function expireConfirmed(
  // deno-lint-ignore no-explicit-any
  admin: any,
  sa: { client_email: string; private_key: string },
  packageName: string,
  purchaseToken: string,
  reason: string,
): Promise<Response> {
  try {
    const accessToken = await getAccessToken(sa);
    const sub = await getSubscription(accessToken, packageName, purchaseToken);
    if (decideFromState(sub.subscriptionState) !== "expire") {
      console.error(
        `rtdn: ${reason} notification for ${purchaseToken}, but Google says ` +
          `${sub.subscriptionState} — ignoring`,
      );
      return json({ ok: true, note: `google says ${sub.subscriptionState}` }, 200);
    }
  } catch (e) {
    if (e instanceof PlayApiError && e.status === 404) {
      // Gone at Google — the notification was truthful.
      console.error(`rtdn: ${purchaseToken} 404 at Google, expiring (${reason})`);
    } else {
      throw e;
    }
  }
  return await expireByToken(admin, purchaseToken, reason);
}

/// One ledger row per renewal, keyed by a token+period ref so a redelivery can't
/// double-count. Non-fatal: entitlement is already applied and losing a history
/// row must never fail the notification.
async function recordRenewal(
  // deno-lint-ignore no-explicit-any
  admin: any,
  bizId: string,
  planRow: { plan_code: string; plan_version: number; billing_period: string },
  productId: string,
  purchaseToken: string,
  sub: { expiryTime: string | null; basePlanId: string | null },
): Promise<void> {
  const { data: planPrice, error: priceErr } = await admin
    .from("plans")
    .select("price_monthly")
    .eq("code", planRow.plan_code)
    .eq("version", planRow.plan_version)
    .maybeSingle();
  if (priceErr || !planPrice) {
    console.error(`rtdn: no price for ${planRow.plan_code} — skipping ledger row`);
    return;
  }
  const months = planRow.billing_period === "annual" ? 10 : 1;
  const { error } = await admin.from("billing_payments").insert({
    business_id: bizId,
    provider: "google_play",
    // provider_ref is globally UNIQUE, so the token has to be in the key — two
    // tenants renewing into the same expiry would otherwise collide and the
    // second renewal would vanish.
    provider_ref: `renew:${purchaseToken}:${sub.expiryTime}`,
    kind: "plan",
    plan_code: planRow.plan_code,
    plan_version: planRow.plan_version,
    billing_period: planRow.billing_period,
    amount: Number(planPrice.price_monthly) * months,
    currency: "PHP",
    status: "paid",
    paid_at: new Date().toISOString(),
    product_id: productId,
    base_plan_id: sub.basePlanId,
  });
  // 23505 = this renewal is already in the ledger, which is the desired outcome.
  if (error && (error as { code?: string }).code !== "23505") {
    console.error(`rtdn: renewal ledger insert failed: ${error.message ?? error}`);
  }
}

// deno-lint-ignore no-explicit-any
async function expireByToken(
  admin: any,
  purchaseToken: string,
  reason: string,
): Promise<Response> {
  const { data: tok, error: tokErr } = await admin
    .from("play_purchase_tokens")
    .select("business_id")
    .eq("purchase_token", purchaseToken)
    .maybeSingle();
  orThrow(tokErr, "play_purchase_tokens lookup (expire)");
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
  await refreshPlanAlerts(admin, tok.business_id);
  return json({ ok: true, expired: reason }, 200);
}
