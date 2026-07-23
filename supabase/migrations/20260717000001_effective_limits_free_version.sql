-- =============================================================================
-- M7.1 hardening — effective_limits_for(): resolve the free/lapsed fallback
-- from the newest (preferring active) version of the free plan instead of the
-- hardcoded plan_version = 1. Previously, publishing a free v2 and retiring v1
-- would make free/lapsed tenants resolve NO limits row at all (empty result =
-- everything reads as unlimited-unknown in dependent checks).
--
-- Body is otherwise identical to 20260707000001 §10. CREATE OR REPLACE keeps
-- the existing ownership + EXECUTE grants (authenticated, service_role).
--
-- ROLLBACK: re-apply the §10 definition from 20260707000001 (only the ELSE
-- branch differs: `WHERE pl.plan_code = 'free' AND pl.plan_version = 1`).
-- =============================================================================

CREATE OR REPLACE FUNCTION public.effective_limits_for(p_business uuid)
RETURNS TABLE (
  cloud_enabled boolean, max_branches int, max_seats int, max_devices int,
  feature_flags jsonb
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sub    public.subscriptions%ROWTYPE;
  v_status text;
BEGIN
  SELECT * INTO v_sub
  FROM public.subscriptions s
  WHERE s.business_id = p_business;

  IF FOUND THEN
    v_status := public.effective_sub_status(v_sub);
  END IF;

  IF FOUND AND v_status IN ('trialing', 'active', 'past_due') THEN
    RETURN QUERY SELECT
      COALESCE((v_sub.entitlement_snapshot ->> 'cloud_enabled')::boolean, false),
      CASE WHEN v_sub.entitlement_snapshot ? 'max_branches'
           AND (v_sub.entitlement_snapshot ->> 'max_branches') IS NOT NULL
        THEN (v_sub.entitlement_snapshot ->> 'max_branches')::int + v_sub.branch_addons
        ELSE NULL END,
      CASE WHEN v_sub.entitlement_snapshot ? 'max_seats'
           AND (v_sub.entitlement_snapshot ->> 'max_seats') IS NOT NULL
        THEN (v_sub.entitlement_snapshot ->> 'max_seats')::int + v_sub.seat_addons
        ELSE NULL END,
      CASE WHEN v_sub.entitlement_snapshot ? 'max_devices'
           AND (v_sub.entitlement_snapshot ->> 'max_devices') IS NOT NULL
        THEN (v_sub.entitlement_snapshot ->> 'max_devices')::int + v_sub.device_addons
        ELSE NULL END,
      COALESCE(v_sub.entitlement_snapshot -> 'feature_flags', '{}'::jsonb);
  ELSE
    -- free / lapsed / no row at all: newest free version, preferring active.
    RETURN QUERY SELECT
      pl.cloud_enabled, pl.max_branches, pl.max_seats, pl.max_devices, pl.feature_flags
    FROM public.plan_limits pl
    JOIN public.plans p
      ON p.code = pl.plan_code AND p.version = pl.plan_version
    WHERE pl.plan_code = 'free'
    ORDER BY p.is_active DESC, pl.plan_version DESC
    LIMIT 1;
  END IF;
END;
$$;
