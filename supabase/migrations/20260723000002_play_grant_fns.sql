-- =============================================================================
-- M7.1 → Google Play Billing (Phase P3) — the Play subscription write path.
--
-- apply_play_subscription / expire_play_subscription are the ONLY functions the
-- Play flow uses to mutate subscriptions. Both are service-role only (§8),
-- called by verify-play-purchase (first purchase) and google-play-rtdn
-- (renew / cancel / hold / revoke). They mirror admin_grant_subscription's
-- snapshot + grandfathering rules, with ONE deliberate difference:
--
--   Google owns the billing date. Unlike the PayMongo model (period = now+30d),
--   current_period_end is set to Google's authoritative expiryTime, so the
--   entitlement window can never drift from what Play actually bills. Each
--   renewal RTDN just re-applies with the new expiry.
--
-- grace_until = expiryTime + 2d: a small buffer that absorbs RTDN delivery lag
-- and offline clients, so a user is never cut off a moment before we process a
-- renewal. It is NOT the PayMongo 14/30d grace — Google's own grace/hold is
-- authoritative and already reflected in expiryTime.
--
-- The engine (effective_sub_status / effective_limits / has_cloud_access) is
-- unchanged: a Play grant and an admin grant are indistinguishable to it.
--
-- ROLLBACK:
--   DROP FUNCTION IF EXISTS public.apply_play_subscription(uuid, text, int, text, timestamptz, text, text, text, text);
--   DROP FUNCTION IF EXISTS public.expire_play_subscription(uuid, text, text, text);
-- =============================================================================

CREATE OR REPLACE FUNCTION public.apply_play_subscription(
  p_business       uuid,
  p_plan           text,
  p_version        int,
  p_period         text,          -- 'monthly' | 'annual'
  p_expiry         timestamptz,   -- Google's authoritative expiryTime
  p_state          text,          -- 'active' | 'canceled' (canceled = auto-renew off, still paid to expiry)
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
BEGIN
  IF p_period NOT IN ('monthly', 'annual') THEN
    RAISE EXCEPTION 'INVALID_PERIOD: %', p_period;
  END IF;
  IF p_expiry IS NULL THEN
    RAISE EXCEPTION 'MISSING_EXPIRY';
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

  SELECT * INTO v_sub FROM public.subscriptions s WHERE s.business_id = p_business;

  -- RTDN-lag buffer past Google's expiry (see header).
  v_grace := p_expiry + make_interval(days => 2);

  -- Same plan keeps the locked signup price (§4.9); a plan change re-locks at list.
  IF FOUND AND v_sub.plan_code = p_plan AND v_sub.grandfathered_price IS NOT NULL
     AND v_sub.grandfathered_price > 0 THEN
    v_price := v_sub.grandfathered_price;
  ELSE
    v_price := v_plan.price_monthly;
  END IF;

  -- 'canceled' means auto-renew is off but the paid period still runs — the
  -- status oracle keeps it 'active' until current_period_end, then lapses with
  -- no past_due grace (matches Google: you canceled, no dunning).
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

-- ── Expire — voluntary end (grace over), refund, chargeback, hold-lapse ───────
-- Collapses the window to now(): the status oracle lands on 'lapsed' (a paid
-- account whose grace is exhausted) → cloud paused, local data untouched (§7.3).
-- Idempotent + guarded by purchase token so a stale token's late notification
-- can't clobber a newer active subscription.
CREATE OR REPLACE FUNCTION public.expire_play_subscription(
  p_business       uuid,
  p_purchase_token text,
  p_reason         text DEFAULT 'expired',
  p_actor          text DEFAULT 'google_play'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sub public.subscriptions%ROWTYPE;
BEGIN
  SELECT * INTO v_sub FROM public.subscriptions s WHERE s.business_id = p_business;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('business_id', p_business, 'note', 'no subscription');
  END IF;

  -- Only act if this notification is about the CURRENT purchase — a superseded
  -- token (post-upgrade) must not expire the live subscription.
  IF v_sub.play_purchase_token IS DISTINCT FROM p_purchase_token THEN
    PERFORM public.record_subscription_event(
      p_business, 'play_expire_ignored_stale_token', p_actor,
      jsonb_build_object('reason', p_reason, 'token_matches', false));
    RETURN jsonb_build_object('business_id', p_business, 'note', 'stale token — ignored');
  END IF;

  UPDATE public.subscriptions SET
    status             = 'canceled',
    current_period_end = now(),
    grace_until        = now(),
    updated_at         = now()
  WHERE business_id = p_business;

  PERFORM public.record_subscription_event(
    p_business, 'play_subscription_expired', p_actor,
    jsonb_build_object('reason', p_reason));

  RETURN jsonb_build_object('business_id', p_business, 'status', 'lapsed', 'reason', p_reason);
END;
$$;

REVOKE ALL ON FUNCTION public.expire_play_subscription(uuid, text, text, text) FROM public;
REVOKE ALL ON FUNCTION public.expire_play_subscription(uuid, text, text, text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.expire_play_subscription(uuid, text, text, text) TO service_role;
