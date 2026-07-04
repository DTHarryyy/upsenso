-- =============================================================================
-- fraud_flags: add 'false_positive' triage status (2026-07-03 fix plan §5)
--
-- Lets an owner explicitly mark a flag as a false positive (distinct from
-- 'dismissed', which is "seen, no action"). Feeds per-rule FP-rate tuning and
-- keeps the maintenance-dismissed 2026-07-03 flags distinguishable from
-- genuine dismissals. 'false_positive' is a triage-only status, so the
-- existing freeze trigger already permits the transition; only the CHECK
-- constraint needs widening.
--
-- ROLLBACK (only safe once no row uses the new value):
--   ALTER TABLE public.fraud_flags DROP CONSTRAINT fraud_flags_status_check;
--   ALTER TABLE public.fraud_flags ADD CONSTRAINT fraud_flags_status_check
--     CHECK (status IN ('new','investigating','resolved','dismissed'));
-- =============================================================================

ALTER TABLE public.fraud_flags DROP CONSTRAINT IF EXISTS fraud_flags_status_check;
ALTER TABLE public.fraud_flags
  ADD CONSTRAINT fraud_flags_status_check
  CHECK (status IN ('new','investigating','resolved','dismissed','false_positive'));
