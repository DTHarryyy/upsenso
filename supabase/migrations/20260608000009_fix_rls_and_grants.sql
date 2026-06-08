-- =============================================================================
-- Fix RLS violations and missing grants
-- =============================================================================
-- Two bugs found from the sync error log:
--
--  1. "permission denied for table employee_roles" on audit_log INSERT
--     Root cause: audit_admin_only SELECT policy uses current_user_role()
--     which is SECURITY INVOKER. PostgreSQL evaluates the SELECT USING clause
--     when an UPSERT resolves a conflict, so the authenticated user needs to
--     be able to run current_user_role(). Fixing current_user_role() to
--     SECURITY DEFINER and granting SELECT on the RBAC read-only tables.
--
--  2. "new row violates row-level security policy for table expenses"
--     Root cause: branch_expenses policy WITH CHECK inherits USING clause
--     which requires has_branch_access(branch_id). Business owners are NOT
--     in employee_branches, so has_branch_access() always returns false for
--     them. Also breaks when branch_id is NULL (NULL = any_uuid → false).
-- =============================================================================

-- ── 1. Grant read access on RBAC look-up tables ──────────────────────────────
-- These tables are read by SECURITY INVOKER functions called from RLS policies.
-- Without SELECT, PostgreSQL throws "permission denied" before RLS is checked.
GRANT SELECT ON public.employee_roles   TO authenticated;
GRANT SELECT ON public.roles            TO authenticated;
GRANT SELECT ON public.role_permissions TO authenticated;
GRANT SELECT ON public.permissions      TO authenticated;

-- ── 2. Make current_user_role() SECURITY DEFINER ─────────────────────────────
-- Belt-and-suspenders: even with the grants above, running as SECURITY DEFINER
-- is safer — the function is a read-only lookup that should never be affected
-- by the caller's privileges.
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT r.name
  FROM   public.employees e
  JOIN   public.employee_roles er ON er.employee_id = e.id
  JOIN   public.roles r           ON r.id           = er.role_id
  WHERE  e.auth_user_id = auth.uid()
  ORDER  BY r.priority DESC
  LIMIT  1;
$$;

-- ── 3. Fix has_branch_access() — SECURITY DEFINER + NULL safety ──────────────
-- SECURITY INVOKER caused permission errors on databases where the caller
-- lacked SELECT on employees/employee_branches via direct table access.
-- Also guard against NULL branch_id: passing NULL returns false which blocked
-- owner-level expense writes where branch_id was not set.
CREATE OR REPLACE FUNCTION public.has_branch_access(bid uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    CASE
      WHEN bid IS NULL THEN true   -- no branch restriction → allow
      ELSE EXISTS (
        SELECT 1
        FROM   public.employee_branches eb
        JOIN   public.employees e ON e.id = eb.employee_id
        WHERE  e.auth_user_id = auth.uid()
          AND  eb.branch_id   = bid
      )
    END;
$$;

-- ── 4. Fix branch_expenses policy on expenses ─────────────────────────────────
-- Old policy: (business_id = get_my_business_id()) AND has_branch_access(branch_id)
-- Problems:
--   a. WITH CHECK was NULL → inherited USING clause → owners fail because they
--      are not in employee_branches.
--   b. No explicit owner escape hatch.
-- New policy:
--   Business-isolation check PLUS one of: owner, super-admin, or branch access.
--   Explicit WITH CHECK so INSERT/UPDATE path is clear.
DROP POLICY IF EXISTS branch_expenses ON public.expenses;
CREATE POLICY branch_expenses ON public.expenses
  FOR ALL TO authenticated
  USING (
    business_id = get_my_business_id()
    AND (
      EXISTS (
        SELECT 1 FROM public.businesses
        WHERE id = expenses.business_id AND owner_id = auth.uid()
      )
      OR i_am_super_admin()
      OR has_branch_access(branch_id)
    )
  )
  WITH CHECK (
    business_id = get_my_business_id()
    AND (
      EXISTS (
        SELECT 1 FROM public.businesses
        WHERE id = expenses.business_id AND owner_id = auth.uid()
      )
      OR i_am_super_admin()
      OR has_branch_access(branch_id)
    )
  );

-- ── PostgREST schema reload ───────────────────────────────────────────────────
SELECT pg_notify('pgrst', 'reload schema');
