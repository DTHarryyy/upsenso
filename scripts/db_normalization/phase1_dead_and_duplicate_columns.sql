-- =============================================================================
-- PHASE 1 — Dead & duplicate columns   (REVIEW ONLY — DO NOT APPLY AS-IS)
-- Risk: LOW. Additive→backfill→verify→drop. Mirror each drop in Drift.
-- Evidence: node scratchpad/null_census.js on backups/reset-20260704/.
-- =============================================================================

-- 1) audit_logs.employee_id — DEAD (0/377 populated; client never writes it; the
--    actor is carried by user_id). It even holds an unused FK → employees.
--    Rollback: re-add nullable column + FK.
--    (Drop only after confirming no trigger writes it — log_permission_change
--     writes `action`, not employee_id.)
ALTER TABLE public.audit_logs DROP COLUMN IF EXISTS employee_id;
-- ROLLBACK: ALTER TABLE public.audit_logs ADD COLUMN employee_id uuid
--           REFERENCES public.employees(id);

-- 2) inventory_levels.variant_id — DEAD text duplicate of product_variant_id
--    (uuid, which owns the FK + UNIQUE(branch_id, product_variant_id)).
--    0/3 populated on the server; the client maps its local text key to
--    product_variant_id. Verify the one inventory remote-DS mapper writes
--    product_variant_id (not variant_id) before dropping.
ALTER TABLE public.inventory_levels DROP COLUMN IF EXISTS variant_id;
-- ROLLBACK: ALTER TABLE public.inventory_levels ADD COLUMN variant_id text;

-- 3) audit_logs.action → action_type (split convergence, NOT a blind drop).
--    Legacy DB triggers write `action`; the app writes `action_type`. Converge:
--    3a. backfill:
UPDATE public.audit_logs SET action_type = action
 WHERE action_type IS NULL AND action IS NOT NULL;
--    3b. update the trigger fn to write action_type (see phase4 note / migration):
--        CREATE OR REPLACE FUNCTION log_permission_change() ... NEW.action_type := ...
--    3c. only in a LATER release, once nothing writes `action`:
-- ALTER TABLE public.audit_logs DROP COLUMN action;
-- ROLLBACK: keep `action` readable for one release as the safety net.

-- NOTE — columns that look dead in the census but are NOT (do NOT drop):
--   transactions.customer_id, refunds.approved_by/approved_at/approval_method,
--   product_variants.* optional fields, receipt_settings.* optional fields.
--   These are 0-populated only because the feature (M5 CRM / refund approval) is
--   new and un-exercised. Confirmed via code usage — they are live optional cols.

-- fraud_flags.employee_id — DEAD (0/9); subject carried by subject_user_id.
-- Candidate, but keep for now: the fraud model may populate it going forward.
-- Decision deferred (documented), not dropped blind.
