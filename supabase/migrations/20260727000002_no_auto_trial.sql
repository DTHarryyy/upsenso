-- =============================================================================
-- Stop auto-granting a phantom trial (P0 — fixes the split source of truth).
--
-- FINDING (2026-07-27 audit, docs/billing-audit-plan.md §2 "S4"):
--   grant_initial_trial() (20260707000001, §13) inserted ONE row holding TWO
--   answers: plan_code = 'free' with a *Starter* entitlement_snapshot.
--     * effective_limits() reads the snapshot  → Starter caps, cloud ON
--     * the app reads plan_code                → "Free"
--   So the shell banner rendered "Free trial — N days left" while the plan card
--   simultaneously marked Free as "Current plan". Both were reading correctly;
--   the row itself disagreed with itself. All 9 businesses were in this state.
--
-- DECISION: there is no free trial. A trial only exists if we deliberately
-- create one FOR a plan later — at which point it must be honest about which
-- plan it previews (plan_code = '<paid tier>', status = 'trialing').
--
-- A new business now lands on a plain Free plan:
--   plan_code = 'free', status = 'canceled', trial_end = NULL,
--   entitlement_snapshot = free/v1's real limits (cloud OFF, 1 branch / 2 seats
--   / 1 device, no CRM, no procurement, basic reports).
--
-- Why status 'canceled' and not 'free': the subscriptions.status CHECK accepts
-- only ('trialing','active','past_due','canceled'). With current_period_end
-- NULL, effective_sub_status() reaches its final branch and returns 'free' —
-- which is the status the app actually consumes. 'canceled' is the storage
-- encoding of "no live paid window", nothing is shown to the user.
--
-- KEPT DELIBERATELY: the trigger itself, trial_claims, and
-- billing_settings.trial_days. A future plan-attached trial re-enables here
-- with no schema change.
--
-- EXISTING ROWS ARE NOT TOUCHED. Rewriting live tenants to Free would revoke
-- cloud sync from them; that is a product call, not a migration's to make.
-- Their trials lapse naturally via effective_sub_status once trial_end passes.
--
-- ROLLBACK: re-run §13 of 20260707000001_billing_foundation.sql verbatim.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.grant_initial_trial()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_snapshot jsonb;
BEGIN
  IF EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.business_id = NEW.id) THEN
    RETURN NEW;   -- idempotent (backfill / re-fire safety)
  END IF;

  -- The snapshot must describe the plan we are actually granting.
  SELECT jsonb_build_object(
           'plan_code', 'free', 'plan_version', pl.plan_version,
           'price_monthly', p.price_monthly,
           'cloud_enabled', pl.cloud_enabled,
           'max_branches', pl.max_branches, 'max_seats', pl.max_seats,
           'max_devices', pl.max_devices, 'feature_flags', pl.feature_flags,
           'source', 'signup')
  INTO v_snapshot
  FROM public.plan_limits pl
  JOIN public.plans p ON p.code = pl.plan_code AND p.version = pl.plan_version
  WHERE pl.plan_code = 'free' AND pl.plan_version = 1;

  INSERT INTO public.subscriptions
    (business_id, plan_code, plan_version, status, trial_end,
     entitlement_snapshot, grandfathered_price)
  VALUES
    (NEW.id, 'free', 1, 'canceled', NULL,
     COALESCE(v_snapshot, '{}'::jsonb), 0);

  PERFORM public.record_subscription_event(
    NEW.id, 'signup_free_plan', 'system',
    jsonb_build_object('plan_code', 'free', 'trial', false));

  RETURN NEW;
END;
$$;

-- Trigger definition is unchanged; restated so the file stands alone.
DROP TRIGGER IF EXISTS trg_grant_initial_trial ON public.businesses;
CREATE TRIGGER trg_grant_initial_trial
  AFTER INSERT ON public.businesses
  FOR EACH ROW EXECUTE FUNCTION public.grant_initial_trial();
