-- =============================================================================
-- Phase 3 (part) — settings write enforcement + audit-log immutability.
--
-- business_settings and receipt_settings had RLS that only checked tenant, so
-- any authenticated member could change business/receipt configuration via the
-- API. Gate writes with RESTRICTIVE per-WRITE-command policies; SELECT is left
-- to the existing permissive policy so the app can still READ settings (e.g. a
-- cashier reading receipt_settings to print a receipt).
--
-- audit_logs: make append-only. The client only ever INSERTs audit rows; a
-- permissive UPDATE policy let any member tamper with the trail. DELETE already
-- has no policy (denied). Dropping the UPDATE policy closes the tampering gap.
-- (SECURITY DEFINER writers bypass RLS, so server-side logging is unaffected.)
--
-- DEFERRED (documented):
--   • recipe_lines — would gate on recipes.manage / ingredients.manage, but
--     those permission codes are NOT seeded in the server permissions table, so
--     has_permission() would return false for everyone but owners and block all
--     recipe management. Seed those permissions + role_permissions first.
--   • employees edit/suspend — the existing UPDATE policy intentionally allows
--     self-profile edits (auth_user_id = auth.uid()); gating by employees.edit
--     would break self-edits, and separating edit vs suspend (is_active) needs
--     OLD/NEW which RLS WITH CHECK can't see. Needs a dedicated design.
--   • branches — already restrictive (insert owner/tenant-scoped, no update/
--     delete policy); low value, deferred.
--
-- ROLLBACK: DROP each policy below; recreate audit_logs_update as
--   FOR UPDATE USING (business_id = get_my_business_id())
--   WITH CHECK (business_id = get_my_business_id()).
-- =============================================================================

-- ── business_settings → settings.edit_business (writes only) ────────────────
DROP POLICY IF EXISTS business_settings_perm_insert ON public.business_settings;
CREATE POLICY business_settings_perm_insert ON public.business_settings
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (has_permission('settings.edit_business'));

DROP POLICY IF EXISTS business_settings_perm_update ON public.business_settings;
CREATE POLICY business_settings_perm_update ON public.business_settings
  AS RESTRICTIVE FOR UPDATE TO authenticated
  WITH CHECK (has_permission('settings.edit_business'));

DROP POLICY IF EXISTS business_settings_perm_delete ON public.business_settings;
CREATE POLICY business_settings_perm_delete ON public.business_settings
  AS RESTRICTIVE FOR DELETE TO authenticated
  USING (has_permission('settings.edit_business'));

-- ── receipt_settings → settings.edit_receipt (writes only) ──────────────────
DROP POLICY IF EXISTS receipt_settings_perm_insert ON public.receipt_settings;
CREATE POLICY receipt_settings_perm_insert ON public.receipt_settings
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (has_permission('settings.edit_receipt'));

DROP POLICY IF EXISTS receipt_settings_perm_update ON public.receipt_settings;
CREATE POLICY receipt_settings_perm_update ON public.receipt_settings
  AS RESTRICTIVE FOR UPDATE TO authenticated
  WITH CHECK (has_permission('settings.edit_receipt'));

DROP POLICY IF EXISTS receipt_settings_perm_delete ON public.receipt_settings;
CREATE POLICY receipt_settings_perm_delete ON public.receipt_settings
  AS RESTRICTIVE FOR DELETE TO authenticated
  USING (has_permission('settings.edit_receipt'));

-- ── audit_logs: append-only (remove the permissive UPDATE) ──────────────────
DROP POLICY IF EXISTS audit_logs_update ON public.audit_logs;
