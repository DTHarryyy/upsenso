-- =============================================================================
-- M7.1 Phase 1 — admin_grant_subscription + apply_subscription_addon.
--
-- The ONLY write paths into subscriptions (§8: service-role only). Both a
-- human admin (manual grant, the launch payment path) and the PayMongo
-- webhook (Phase 7) call these same functions — the entitlement engine cannot
-- tell them apart, which is exactly the §11 test: "manual grant and webhook
-- produce the same entitlement."
--
-- Grant semantics:
--   * Snapshots plans+plan_limits at THIS moment into entitlement_snapshot —
--     later catalog edits never touch this customer (§4.9 grandfathering).
--   * grandfathered_price: kept on renewal of the same plan; re-locked at the
--     current list price when the plan changes (upgrade = new deal).
--   * Renewal extends from GREATEST(now, current_period_end) — paying early
--     never loses days.
--   * Grace (§7.4): period_end + 14d (monthly) / + 30d (annual).
--   * Add-ons passed as {"device": n, "branch": n, "seat": n} REPLACE the
--     matching column when present (admin sets absolute counts);
--     apply_subscription_addon INCREMENTS (webhook purchases are deltas).
--
-- Manual grant runbook (via `npx supabase db query --linked`, one statement):
--   select public.admin_grant_subscription(
--     '<business-uuid>', 'growth', 1, 'monthly', '{}'::jsonb, 'admin');
--
-- ROLLBACK:
--   DROP FUNCTION IF EXISTS public.admin_grant_subscription(uuid, text, int, text, jsonb, text);
--   DROP FUNCTION IF EXISTS public.apply_subscription_addon(uuid, text, int, text);
-- =============================================================================

CREATE OR REPLACE FUNCTION public.admin_grant_subscription(
  p_business uuid,
  p_plan     text,
  p_version  int,
  p_period   text DEFAULT 'monthly',
  p_addons   jsonb DEFAULT '{}'::jsonb,
  p_actor    text DEFAULT 'admin'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_plan       public.plans%ROWTYPE;
  v_limits     public.plan_limits%ROWTYPE;
  v_sub        public.subscriptions%ROWTYPE;
  v_snapshot   jsonb;
  v_start      timestamptz := now();
  v_period_end timestamptz;
  v_grace      timestamptz;
  v_price      numeric;
BEGIN
  IF p_period NOT IN ('monthly', 'annual') THEN
    RAISE EXCEPTION 'INVALID_PERIOD: %', p_period;
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

  -- Renewal of a live period extends it; anything else starts from now.
  IF FOUND AND v_sub.plan_code = p_plan
     AND v_sub.current_period_end IS NOT NULL
     AND v_sub.current_period_end > v_start THEN
    v_start := v_sub.current_period_end;
  END IF;

  v_period_end := v_start + CASE p_period
    WHEN 'annual' THEN make_interval(days => 365)
    ELSE make_interval(days => 30) END;
  v_grace := v_period_end + CASE p_period
    WHEN 'annual' THEN make_interval(days => 30)
    ELSE make_interval(days => 14) END;

  -- Same plan keeps the locked signup price (§4.9); a plan change re-locks.
  IF FOUND AND v_sub.plan_code = p_plan AND v_sub.grandfathered_price IS NOT NULL
     AND v_sub.grandfathered_price > 0 THEN
    v_price := v_sub.grandfathered_price;
  ELSE
    v_price := v_plan.price_monthly;
  END IF;

  v_snapshot := jsonb_build_object(
    'plan_code', p_plan, 'plan_version', p_version,
    'price_monthly', v_price,
    'cloud_enabled', v_limits.cloud_enabled,
    'max_branches', v_limits.max_branches,
    'max_seats', v_limits.max_seats,
    'max_devices', v_limits.max_devices,
    'feature_flags', v_limits.feature_flags,
    'source', 'grant');

  INSERT INTO public.subscriptions
    (business_id, plan_code, plan_version, billing_period, entitlement_snapshot,
     device_addons, branch_addons, seat_addons, status,
     current_period_start, current_period_end, grace_until,
     grandfathered_price, updated_at)
  VALUES
    (p_business, p_plan, p_version, p_period, v_snapshot,
     COALESCE((p_addons ->> 'device')::int, 0),
     COALESCE((p_addons ->> 'branch')::int, 0),
     COALESCE((p_addons ->> 'seat')::int, 0),
     'active', now(), v_period_end, v_grace, v_price, now())
  ON CONFLICT (business_id) DO UPDATE SET
    plan_code            = EXCLUDED.plan_code,
    plan_version         = EXCLUDED.plan_version,
    billing_period       = EXCLUDED.billing_period,
    entitlement_snapshot = EXCLUDED.entitlement_snapshot,
    device_addons        = COALESCE((p_addons ->> 'device')::int, subscriptions.device_addons),
    branch_addons        = COALESCE((p_addons ->> 'branch')::int, subscriptions.branch_addons),
    seat_addons          = COALESCE((p_addons ->> 'seat')::int,  subscriptions.seat_addons),
    status               = 'active',
    current_period_start = now(),
    current_period_end   = EXCLUDED.current_period_end,
    grace_until          = EXCLUDED.grace_until,
    grandfathered_price  = EXCLUDED.grandfathered_price,
    updated_at           = now();

  PERFORM public.record_subscription_event(
    p_business, 'plan_granted', p_actor,
    jsonb_build_object(
      'plan_code', p_plan, 'plan_version', p_version, 'billing_period', p_period,
      'price', v_price, 'period_end', v_period_end, 'grace_until', v_grace,
      'addons', p_addons));

  RETURN jsonb_build_object(
    'business_id', p_business, 'plan_code', p_plan, 'status', 'active',
    'current_period_end', v_period_end, 'grace_until', v_grace, 'price', v_price);
END;
$$;

REVOKE ALL ON FUNCTION public.admin_grant_subscription(uuid, text, int, text, jsonb, text) FROM public;
REVOKE ALL ON FUNCTION public.admin_grant_subscription(uuid, text, int, text, jsonb, text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.admin_grant_subscription(uuid, text, int, text, jsonb, text) TO service_role;

-- ── Add-on purchase (delta) — webhook path for "+1 device" style buys ────────
CREATE OR REPLACE FUNCTION public.apply_subscription_addon(
  p_business uuid,
  p_addon    text,
  p_qty      int DEFAULT 1,
  p_actor    text DEFAULT 'admin'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sub    public.subscriptions%ROWTYPE;
  v_status text;
BEGIN
  IF p_addon NOT IN ('device', 'branch', 'seat') THEN
    RAISE EXCEPTION 'UNKNOWN_ADDON: %', p_addon;
  END IF;
  IF p_qty < 1 THEN
    RAISE EXCEPTION 'INVALID_QTY: %', p_qty;
  END IF;

  SELECT * INTO v_sub FROM public.subscriptions s WHERE s.business_id = p_business;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_SUBSCRIPTION: %', p_business;
  END IF;

  v_status := public.effective_sub_status(v_sub);
  IF v_status NOT IN ('trialing', 'active', 'past_due') THEN
    RAISE EXCEPTION 'ADDON_REQUIRES_PAID_PLAN: status=%', v_status;
  END IF;

  UPDATE public.subscriptions SET
    device_addons = device_addons + CASE WHEN p_addon = 'device' THEN p_qty ELSE 0 END,
    branch_addons = branch_addons + CASE WHEN p_addon = 'branch' THEN p_qty ELSE 0 END,
    seat_addons   = seat_addons   + CASE WHEN p_addon = 'seat'   THEN p_qty ELSE 0 END,
    updated_at    = now()
  WHERE business_id = p_business;

  PERFORM public.record_subscription_event(
    p_business, 'addon_applied', p_actor,
    jsonb_build_object('addon', p_addon, 'qty', p_qty));

  RETURN jsonb_build_object('business_id', p_business, 'addon', p_addon, 'qty', p_qty);
END;
$$;

REVOKE ALL ON FUNCTION public.apply_subscription_addon(uuid, text, int, text) FROM public;
REVOKE ALL ON FUNCTION public.apply_subscription_addon(uuid, text, int, text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.apply_subscription_addon(uuid, text, int, text) TO service_role;
