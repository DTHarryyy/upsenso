-- ════════════════════════════════════════════════════════════════════════════
-- Migration: normalize_schema_security_perf
--
-- Production-readiness pass derived from a full audit of the live remote
-- schema (functions, triggers, RLS policies) + Supabase advisor output.
--
-- This migration is non-destructive to data and conservative in scope:
--   • Drops duplicate triggers (same table, same action, same function)
--   • Drops redundant `ALL`-command RLS policies that overlap with
--     command-specific ones (advisor: multiple_permissive_policies)
--   • Moves `public`-role policies on private tables to `authenticated`
--     so anon clients can never match them (advisor: rls_anon_exposure)
--   • Removes the malformed `psv_no_write` policy whose `qual IS NULL`
--     made SELECT effectively open (advisor: rls_policy_always_true)
--   • Consolidates three near-duplicate helper functions
--     (current_business_id / get_my_business_id / my_business_id) into
--     a single canonical `my_business_id()` with delegates for backwards
--     compatibility — no caller breaks
--   • Locks down every `SECURITY DEFINER` function so `anon` can no longer
--     invoke it via PostgREST (`/rest/v1/rpc/...`)
--   • Revokes EXECUTE on trigger-only functions (`trg_fn_*_changed`,
--     `log_permission_change`, …) from every role — they exist purely
--     for triggers and should never be reachable from the API
--   • Sets an explicit `search_path` on every SECURITY DEFINER function
--     missing one (advisor: function_search_path_mutable)
--
-- Out of scope (deliberate — needs app-side coordination):
--   • RLS performance rewrite (auth.uid() → (select auth.uid()))
--   • Dropping `employees.role_name` / `user_id` denormalization
--   • Tightening `employees.business_id` to NOT NULL
--   • Removing `public.users` profile table (FK to auth.users(id))
--   • Auth dashboard settings (HaveIBeenPwned password protection)
-- ════════════════════════════════════════════════════════════════════════════

BEGIN;

-- ─── A. Drop duplicate triggers ──────────────────────────────────────────────
-- `trg_bm_updated_at` and `trg_business_modules_updated_at` both fire BEFORE
-- UPDATE on business_modules and call set_updated_at(). Two firings per UPDATE
-- is wasteful; keep the descriptively-named one.
DROP TRIGGER IF EXISTS trg_bm_updated_at ON public.business_modules;


-- ─── B. Drop redundant/insecure RLS policies ─────────────────────────────────
-- Pattern: a coarse `biz_isolation_*` ALL policy duplicates the four
-- command-specific policies. PostgreSQL evaluates ALL permissive policies
-- per command, so the duplicate doubles RLS cost on every row.

-- employees: command-specific policies cover SELECT/INSERT/UPDATE/DELETE
DROP POLICY IF EXISTS biz_isolation_employees ON public.employees;

-- employee_branches: command-specific policies already exist
DROP POLICY IF EXISTS biz_isolation_employee_branches ON public.employee_branches;

-- branches: branches_insert / branches_select exist (and use my_business_id)
DROP POLICY IF EXISTS biz_isolation_branches ON public.branches;

-- employee_permissions: three SELECT policies on `public` role overlap with
-- the authenticated-scoped `employee_permissions_select`. The role-name
-- string-matching in admin_* is also brittle ('Branch Manager' vs lower).
DROP POLICY IF EXISTS admin_read_all_permissions ON public.employee_permissions;
DROP POLICY IF EXISTS admin_write_permissions    ON public.employee_permissions;
DROP POLICY IF EXISTS employee_read_own_permissions ON public.employee_permissions;

-- permission_snapshot_versions: psv_no_write has cmd=ALL, qual=NULL,
-- with_check='false'. qual=NULL means SELECT is unconditionally permitted —
-- the policy was meant as a write-deny but actually grants SELECT to all.
-- Replace with explicit per-command deny policies (which are also unnecessary
-- since omitting INSERT/UPDATE/DELETE policies denies by default).
DROP POLICY IF EXISTS psv_no_write ON public.permission_snapshot_versions;


-- ─── C. Tighten `public`-role policies down to `authenticated` ──────────────
-- These tables hold tenant data; `public` (which includes `anon`) should
-- never appear in their policy roles. We recreate each policy verbatim
-- with the same predicate but scoped to the `authenticated` role.

-- branch_permissions
DROP POLICY IF EXISTS bp_read  ON public.branch_permissions;
DROP POLICY IF EXISTS bp_write ON public.branch_permissions;

CREATE POLICY bp_read ON public.branch_permissions
  FOR SELECT TO authenticated
  USING (business_id = my_business_id());

CREATE POLICY bp_write ON public.branch_permissions
  FOR ALL TO authenticated
  USING      ((business_id = my_business_id()) AND i_am_super_admin())
  WITH CHECK ((business_id = my_business_id()) AND i_am_super_admin());

-- business_modules: bm_read targets public; recreate as authenticated.
-- bm_owner_write is already authenticated — leave it.
DROP POLICY IF EXISTS bm_read ON public.business_modules;
CREATE POLICY bm_read ON public.business_modules
  FOR SELECT TO authenticated
  USING (business_id = my_business_id());

-- user_permissions
DROP POLICY IF EXISTS up_read  ON public.user_permissions;
DROP POLICY IF EXISTS up_write ON public.user_permissions;

CREATE POLICY up_read ON public.user_permissions
  FOR SELECT TO authenticated
  USING (
    business_id = my_business_id()
    AND (employee_id = get_my_employee_id() OR i_am_super_admin())
  );

CREATE POLICY up_write ON public.user_permissions
  FOR ALL TO authenticated
  USING      ((business_id = my_business_id()) AND i_am_super_admin())
  WITH CHECK ((business_id = my_business_id()) AND i_am_super_admin());

-- permission_snapshot_versions: psv_read was public; recreate as authenticated.
DROP POLICY IF EXISTS psv_read ON public.permission_snapshot_versions;
CREATE POLICY psv_read ON public.permission_snapshot_versions
  FOR SELECT TO authenticated
  USING (
    business_id = my_business_id()
    AND (employee_id = get_my_employee_id() OR i_am_super_admin())
  );

-- effective_permissions: ep_* policies use role 'public'. ep_read returns
-- per-employee permission state; tighten to authenticated and drop the
-- three "no_*" deny policies (default-deny via missing write policies).
DROP POLICY IF EXISTS ep_read      ON public.effective_permissions;
DROP POLICY IF EXISTS ep_no_insert ON public.effective_permissions;
DROP POLICY IF EXISTS ep_no_update ON public.effective_permissions;
DROP POLICY IF EXISTS ep_no_delete ON public.effective_permissions;

CREATE POLICY ep_read ON public.effective_permissions
  FOR SELECT TO authenticated
  USING (
    business_id = my_business_id()
    AND (employee_id = get_my_employee_id() OR i_am_super_admin())
  );


-- ─── D. Consolidate near-duplicate helper functions ──────────────────────────
-- `my_business_id` is the canonical accessor (auth_user_id + is_active +
-- owner fallback + SECURITY DEFINER + locked search_path). The other two
-- are legacy and have subtle differences (no SECURITY DEFINER on
-- current_business_id; no is_active filter on get_my_business_id) that
-- can produce inconsistent RLS decisions. Redefine them as thin
-- delegates so existing callers and policies continue to work.

CREATE OR REPLACE FUNCTION public.get_my_business_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$ SELECT public.my_business_id(); $$;

CREATE OR REPLACE FUNCTION public.current_business_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$ SELECT public.my_business_id(); $$;


-- ─── E. Set search_path on every SECURITY DEFINER function missing one ──────
-- Empty/role-mutable search_path on a SECURITY DEFINER function is a
-- privilege-escalation surface: an attacker who can create objects in a
-- schema earlier on the resolver's path can shadow built-in functions.

ALTER FUNCTION public.set_updated_at()                       SET search_path = public;
ALTER FUNCTION public.set_employee_permissions_updated_at()  SET search_path = public;
ALTER FUNCTION public.sync_employee_auth_ids()               SET search_path = public;
ALTER FUNCTION public.sync_receipt_show_tax()                SET search_path = public;
ALTER FUNCTION public.default_permissions_for_role(text)     SET search_path = public;
ALTER FUNCTION public.has_branch_access(uuid)                SET search_path = public;
ALTER FUNCTION public.has_permission(text)                   SET search_path = public;
ALTER FUNCTION public.my_branch_ids()                        SET search_path = public;
ALTER FUNCTION public.current_employee()                     SET search_path = public;
ALTER FUNCTION public.log_permission_change()                SET search_path = public, extensions;
ALTER FUNCTION public.trg_fn_branch_perm_changed()           SET search_path = public;
ALTER FUNCTION public.trg_fn_module_changed()                SET search_path = public;
ALTER FUNCTION public.trg_fn_role_perm_changed()             SET search_path = public;
ALTER FUNCTION public.trg_fn_user_perm_changed()             SET search_path = public;


-- ─── F. Lock down SECURITY DEFINER functions — strip anon access ────────────
-- PostgREST exposes every function in `public` as an RPC at
-- /rest/v1/rpc/<name>. With SECURITY DEFINER, an anon hit runs as the
-- function owner (postgres) — total privilege escalation. Revoke
-- EXECUTE from anon on everything that needs auth context to be safe.

REVOKE EXECUTE ON FUNCTION public.apply_business_template(uuid, uuid, uuid) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.bump_versions_for_business(uuid)          FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.bump_versions_for_role(uuid)              FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.compute_employee_permissions(uuid, uuid)  FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.create_employee_auth_account(text, text, uuid, uuid, uuid, uuid, text) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.current_business_id()                     FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.current_user_role()                       FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_employee_permission_overrides(uuid)   FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_my_business_context()                 FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_my_business_id()                      FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_my_employee_id()                      FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_my_permissions()                      FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.has_branch_access(uuid)                   FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.has_permission(text)                      FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.i_am_owner_of(uuid)                       FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.i_am_super_admin()                        FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.my_branch_ids()                           FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.my_business_id()                          FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.set_employee_permission_override(uuid, text, boolean) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.set_module_enabled(uuid, text, boolean)   FROM anon, public;

-- Re-grant to authenticated explicitly (REVOKE … FROM public can otherwise
-- take EXECUTE away from authenticated too, depending on prior grants).
GRANT EXECUTE ON FUNCTION public.apply_business_template(uuid, uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.bump_versions_for_business(uuid)          TO authenticated;
GRANT EXECUTE ON FUNCTION public.bump_versions_for_role(uuid)              TO authenticated;
GRANT EXECUTE ON FUNCTION public.compute_employee_permissions(uuid, uuid)  TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_employee_auth_account(text, text, uuid, uuid, uuid, uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.current_business_id()                     TO authenticated;
GRANT EXECUTE ON FUNCTION public.current_user_role()                       TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_employee_permission_overrides(uuid)   TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_business_context()                 TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_business_id()                      TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_employee_id()                      TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_permissions()                      TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_branch_access(uuid)                   TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_permission(text)                      TO authenticated;
GRANT EXECUTE ON FUNCTION public.i_am_owner_of(uuid)                       TO authenticated;
GRANT EXECUTE ON FUNCTION public.i_am_super_admin()                        TO authenticated;
GRANT EXECUTE ON FUNCTION public.my_branch_ids()                           TO authenticated;
GRANT EXECUTE ON FUNCTION public.my_business_id()                          TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_employee_permission_override(uuid, text, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_module_enabled(uuid, text, boolean)   TO authenticated;


-- ─── G. Hide trigger-only functions from PostgREST ──────────────────────────
-- These functions exist solely to be invoked from triggers. PostgREST
-- happily exposes them at /rest/v1/rpc/<name>, where being SECURITY
-- DEFINER turns each one into a privilege-escalation primitive
-- (advisor: authenticated_security_definer_function_executable).
-- Revoke EXECUTE from every external role; triggers run as the table
-- owner and don't need any GRANT.

REVOKE EXECUTE ON FUNCTION public.trg_fn_branch_perm_changed() FROM public, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_fn_module_changed()      FROM public, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_fn_role_perm_changed()   FROM public, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_fn_user_perm_changed()   FROM public, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.log_permission_change()      FROM public, anon, authenticated;

COMMIT;
