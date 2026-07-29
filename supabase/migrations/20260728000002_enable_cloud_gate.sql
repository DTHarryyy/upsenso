-- =============================================================================
-- M7.1 → Turn the paywall on.
--
-- `billing_settings.cloud_gate_enforced` has been FALSE since the billing
-- foundation shipped (20260707000001 §1, "flipped to TRUE manually once the
-- entitlement-aware client is released"). While it is false, has_cloud_access()
-- short-circuits to TRUE for every caller, so all 25 RESTRICTIVE write policies
-- from 20260708000001 are inert. Combined with an unsigned local Drift cache,
-- that means editing `entitlement_cache` on device really does unlock cloud
-- sync. Until this flip lands, the subscription system is advisory, not enforced.
--
-- APPLY THIS SEPARATELY from 20260728000001, and only after:
--   1. 20260728000001_play_billing_hardening.sql is applied.
--   2. Both edge functions are deployed.
--   3. tool/billing_rls_checks.sql §7–§11 has been run on a preview branch.
--
-- IMPACT — measured against prod on 2026-07-28:
--   * 8 businesses are `trialing` with trial_end 2026-08-09. has_cloud_access()
--     admits 'trialing', so they are UNAFFECTED today and keep cloud sync until
--     that date, at which point they lapse to Free-local. That is the intended
--     behaviour, but it is a real cutover date — not a silent one.
--   * 1 business (5651c2ba…) is `lapsed` and loses cloud WRITES the moment this
--     applies. It is the Play license-tester account, whose test subscription
--     expires on a compressed clock, so this is expected.
--   * No business is mid-grace. Nobody is stranded by the flip itself.
--
-- Re-check before applying — these numbers age:
--   SELECT public.effective_sub_status(s) AS st, count(*)
--     FROM public.subscriptions s GROUP BY 1;
--
-- Local data is never touched: the gate blocks cloud WRITES only. SELECT stays
-- open so a lapsed tenant keeps reading its own frozen copy (20260708000001).
--
-- ROLLBACK — instant, no data loss:
--   UPDATE public.billing_settings SET cloud_gate_enforced = false, updated_at = now() WHERE id = 1;
-- =============================================================================

UPDATE public.billing_settings
   SET cloud_gate_enforced = true,
       updated_at          = now()
 WHERE id = 1;

-- Fail loudly rather than leaving the gate half-on: a missing row would mean
-- has_cloud_access()'s COALESCE(..., false) keeps returning TRUE for everyone
-- and the flip would appear to succeed while changing nothing.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.billing_settings
     WHERE id = 1 AND cloud_gate_enforced = true
  ) THEN
    RAISE EXCEPTION 'cloud gate not enforced after flip — billing_settings id=1 missing?';
  END IF;
END $$;
