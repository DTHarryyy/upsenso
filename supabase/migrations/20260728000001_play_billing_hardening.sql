-- =============================================================================
-- M7.1 → Google Play Billing hardening.
--
-- Three independent fixes to the Play grant path, all additive:
--
--   §1 apply_play_subscription gains a stale-token guard. expire_play_subscription
--      has had one since launch, but apply did not — so a delayed RTDN for a
--      superseded token (the leftover of an upgrade) re-applied the OLD plan
--      over the new one. A tenant who upgraded Starter → Growth could be
--      silently downgraded back to Starter minutes later, with no user action
--      and nothing in the app to explain it.
--
--   §2 Explicit REVOKE of client DML on the billing tables. Today a client cannot
--      write to `subscriptions` only because no policy grants it; Supabase's
--      stock DML grants to `authenticated` are still in place, so one accidental
--      permissive policy would turn self-granting on. This makes the denial
--      structural — the privilege itself is gone.
--
--   §3 billing_webhook_events gains a `status`. The RTDN handler claimed its
--      idempotency row before doing the work, so a failure mid-processing meant
--      the Pub/Sub retry was answered "duplicate" and the notification was lost
--      for good — one Google 5xx could silently drop a renewal or a refund.
--
--   §4 billing_settings stops being world-readable. `cloud_gate_enforced` tells
--      any signed-in user whether the paywall is currently being enforced, which
--      is precisely the thing not to advertise.
--
-- Depends on: 20260707000001_billing_foundation.sql, 20260723000001, 20260723000002.
--
-- ROLLBACK (safe, no data loss):
--   -- §1: re-run 20260723000002_play_grant_fns.sql (CREATE OR REPLACE restores it)
--   GRANT SELECT, INSERT, UPDATE, DELETE ON public.subscriptions TO authenticated;
--   GRANT SELECT, INSERT, UPDATE, DELETE ON public.billing_payments TO authenticated;
--   ALTER TABLE public.billing_webhook_events DROP COLUMN status;
--   GRANT SELECT ON public.billing_settings TO authenticated;
--   CREATE POLICY billing_settings_select ON public.billing_settings
--     FOR SELECT TO authenticated USING (true);
-- =============================================================================

-- ── §1 Stale-token guard on apply ───────────────────────────────────────────
-- Mirrors expire_play_subscription's guard (20260723000002 §2). A token that the
-- verify path has already retired (is_current = false) must never re-apply its
-- plan over whatever replaced it. Ignoring is recorded, not silent: a plan that
-- appears to "flap" needs a trail.
CREATE OR REPLACE FUNCTION public.apply_play_subscription(
  p_business       uuid,
  p_plan           text,
  p_version        int,
  p_period         text,          -- 'monthly' | 'annual'
  p_expiry         timestamptz,   -- Google's authoritative expiryTime
  p_state          text,          -- 'active' | 'canceled'
  p_product_id     text,
  p_purchase_token text,
  p_actor          text DEFAULT 'google_play'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_plan     public.plans%ROWTYPE;
  v_limits   public.plan_limits%ROWTYPE;
  v_sub      public.subscriptions%ROWTYPE;
  v_snapshot jsonb;
  v_grace    timestamptz;
  v_price    numeric;
  v_status   text;
  v_retired  boolean;
BEGIN
  IF p_period NOT IN ('monthly', 'annual') THEN
    RAISE EXCEPTION 'INVALID_PERIOD: %', p_period;
  END IF;
  IF p_expiry IS NULL THEN
    RAISE EXCEPTION 'MISSING_EXPIRY';
  END IF;

  SELECT * INTO v_sub FROM public.subscriptions s WHERE s.business_id = p_business;

  -- Retired token trying to re-apply over a newer one → ignore. Checked before
  -- any write, and only when it is NOT the subscription's current token (a
  -- re-verify of the live purchase must still refresh the expiry).
  IF p_purchase_token IS NOT NULL
     AND v_sub.play_purchase_token IS DISTINCT FROM p_purchase_token THEN
    SELECT (t.is_current = false) INTO v_retired
      FROM public.play_purchase_tokens t
     WHERE t.purchase_token = p_purchase_token;

    IF COALESCE(v_retired, false) THEN
      PERFORM public.record_subscription_event(
        p_business, 'play_apply_ignored_stale_token', p_actor,
        jsonb_build_object(
          'plan_code', p_plan, 'product_id', p_product_id,
          'current_token_differs', true));
      RETURN jsonb_build_object(
        'business_id', p_business, 'note', 'stale token — ignored');
    END IF;
  END IF;

  SELECT * INTO v_plan FROM public.plans p
   WHERE p.code = p_plan AND p.version = p_version;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'UNKNOWN_PLAN: % v%', p_plan, p_version;
  END IF;

  SELECT * INTO v_limits FROM public.plan_limits pl
   WHERE pl.plan_code = p_plan AND pl.plan_version = p_version;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'MISSING_PLAN_LIMITS: % v%', p_plan, p_version;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = p_business) THEN
    RAISE EXCEPTION 'UNKNOWN_BUSINESS: %', p_business;
  END IF;

  -- RTDN-lag buffer past Google's expiry (see 20260723000002 header).
  v_grace := p_expiry + make_interval(days => 2);

  -- Same plan keeps the locked signup price (§4.9); a plan change re-locks at list.
  IF v_sub.business_id IS NOT NULL AND v_sub.plan_code = p_plan
     AND v_sub.grandfathered_price IS NOT NULL
     AND v_sub.grandfathered_price > 0 THEN
    v_price := v_sub.grandfathered_price;
  ELSE
    v_price := v_plan.price_monthly;
  END IF;

  v_status := CASE WHEN p_state = 'canceled' THEN 'canceled' ELSE 'active' END;

  v_snapshot := jsonb_build_object(
    'plan_code', p_plan, 'plan_version', p_version,
    'price_monthly', v_price,
    'cloud_enabled', v_limits.cloud_enabled,
    'max_branches', v_limits.max_branches,
    'max_seats', v_limits.max_seats,
    'max_devices', v_limits.max_devices,
    'feature_flags', v_limits.feature_flags,
    'source', 'google_play');

  INSERT INTO public.subscriptions
    (business_id, plan_code, plan_version, billing_period, entitlement_snapshot,
     status, current_period_start, current_period_end, grace_until,
     grandfathered_price, provider, play_product_id, play_purchase_token, updated_at)
  VALUES
    (p_business, p_plan, p_version, p_period, v_snapshot,
     v_status, COALESCE(v_sub.current_period_start, now()), p_expiry, v_grace,
     v_price, 'google_play', p_product_id, p_purchase_token, now())
  ON CONFLICT (business_id) DO UPDATE SET
    plan_code            = EXCLUDED.plan_code,
    plan_version         = EXCLUDED.plan_version,
    billing_period       = EXCLUDED.billing_period,
    entitlement_snapshot = EXCLUDED.entitlement_snapshot,
    status               = EXCLUDED.status,
    current_period_end   = EXCLUDED.current_period_end,
    grace_until          = EXCLUDED.grace_until,
    grandfathered_price  = EXCLUDED.grandfathered_price,
    provider             = 'google_play',
    play_product_id      = EXCLUDED.play_product_id,
    play_purchase_token  = EXCLUDED.play_purchase_token,
    updated_at           = now();

  PERFORM public.record_subscription_event(
    p_business, 'play_subscription_applied', p_actor,
    jsonb_build_object(
      'plan_code', p_plan, 'plan_version', p_version, 'billing_period', p_period,
      'expiry', p_expiry, 'state', p_state, 'product_id', p_product_id));

  RETURN jsonb_build_object(
    'business_id', p_business, 'plan_code', p_plan, 'status', v_status,
    'current_period_end', p_expiry);
END;
$$;

REVOKE ALL ON FUNCTION public.apply_play_subscription(uuid, text, int, text, timestamptz, text, text, text, text) FROM public;
REVOKE ALL ON FUNCTION public.apply_play_subscription(uuid, text, int, text, timestamptz, text, text, text, text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.apply_play_subscription(uuid, text, int, text, timestamptz, text, text, text, text) TO service_role;

-- ── §2 Structural denial of client writes to the money tables ───────────────
-- Removing the privilege, not adding a policy. Until now the only thing stopping
-- a client from writing its own subscription row was the ABSENCE of a permissive
-- policy — Supabase's stock DML grants to `authenticated` were still in place,
-- so one careless policy would have opened self-granting. After this, no policy
-- can grant what the role no longer holds.
--
-- Deliberately NOT using FORCE ROW LEVEL SECURITY. FORCE only affects the table
-- owner, and the owner here is exactly what we want unrestricted: has_cloud_access(),
-- effective_limits(), get_my_entitlement() and apply_play_subscription() are all
-- SECURITY DEFINER reads/writes over these tables. FORCE would risk breaking the
-- entitlement oracle for every tenant while buying nothing against clients.
--
-- SELECT stays for `authenticated`: the app reads its own plan and payment
-- history through the existing *_select_own policies.
REVOKE INSERT, UPDATE, DELETE ON public.subscriptions        FROM authenticated, anon;
REVOKE INSERT, UPDATE, DELETE ON public.billing_payments     FROM authenticated, anon;
REVOKE INSERT, UPDATE, DELETE ON public.subscription_events  FROM authenticated, anon;
REVOKE ALL                     ON public.play_purchase_tokens FROM authenticated, anon;
REVOKE ALL                     ON public.billing_webhook_events FROM authenticated, anon;

-- The grant path runs as service_role and must keep full reach.
GRANT SELECT, INSERT, UPDATE, DELETE ON public.subscriptions        TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.billing_payments     TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.subscription_events  TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.play_purchase_tokens TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.billing_webhook_events TO service_role;

-- ── §3 RTDN notifications stop being lost ───────────────────────────────────
-- The handler wrote its idempotency row BEFORE processing, so any later failure
-- returned 500, Pub/Sub retried, the retry saw the existing row and answered
-- "duplicate" — and the renewal or refund was dropped permanently. A single
-- Google 5xx was enough. Only a row marked `done` may short-circuit now.
--
-- Existing rows are backfilled to 'done': they were written under the old scheme,
-- where the row's existence meant "seen", and re-processing months of history
-- would re-apply stale subscription state.
ALTER TABLE public.billing_webhook_events
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'done'
    CHECK (status IN ('pending', 'done'));

COMMENT ON COLUMN public.billing_webhook_events.status IS
  'pending = claimed but not yet processed (Pub/Sub may retry); done = handled.';

-- Lets the retry sweep find work without scanning the whole ledger.
CREATE INDEX IF NOT EXISTS idx_webhook_events_pending
  ON public.billing_webhook_events (received_at)
  WHERE status = 'pending';

-- ── §4 Stop advertising whether the paywall is on ───────────────────────────
-- `USING (true)` exposed cloud_gate_enforced to every signed-in user. The client
-- has no legitimate use for it — enforcement is a server decision — and the app
-- reads trial_days from get_my_entitlement, not from here.
DROP POLICY IF EXISTS billing_settings_select ON public.billing_settings;

REVOKE ALL ON public.billing_settings FROM authenticated, anon;
GRANT SELECT, INSERT, UPDATE ON public.billing_settings TO service_role;
