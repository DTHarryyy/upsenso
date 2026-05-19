-- ============================================================
-- Employee context fixes  (single canonical version — no duplicates)
--
-- Updates the four helper functions so that employee accounts
-- (which live in public.employees, not public.users) are
-- recognised when they log in.
--
-- Root cause: handle_new_auth_user() creates a public.users row
-- for EVERY auth signup — including employees created via
-- create_employee_auth_account().  That row has NULL business_id,
-- so hasBusiness = false → router sends them to business setup.
--
-- Fix: all lookups fall back to public.employees when the
-- public.users row exists but has no business context
-- (business_id IS NULL).
-- ============================================================

-- ---------------------------------------------------------------------------
-- my_business_id()
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.my_business_id()
  RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER
  SET search_path = public AS
$$
  SELECT COALESCE(
    -- Owner / super-admin: public.users row has business_id set
    (SELECT business_id FROM public.users
      WHERE id = auth.uid() AND business_id IS NOT NULL),
    -- Employee: business context lives in public.employees
    (SELECT business_id FROM public.employees
      WHERE auth_user_id = auth.uid() AND status = 'active' LIMIT 1)
  );
$$;

-- ---------------------------------------------------------------------------
-- my_branch_id()
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.my_branch_id()
  RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER
  SET search_path = public AS
$$
  SELECT COALESCE(
    (SELECT branch_id FROM public.users
      WHERE id = auth.uid() AND business_id IS NOT NULL),
    (SELECT branch_id FROM public.employees
      WHERE auth_user_id = auth.uid() AND status = 'active' LIMIT 1)
  );
$$;

-- ---------------------------------------------------------------------------
-- i_am_super_admin()
-- Employees with role 'owner' or 'branch_manager' are treated as
-- super-admins within their business.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.i_am_super_admin()
  RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
  SET search_path = public AS
$$
  SELECT
    -- Regular business-owner account (public.users + public.roles)
    EXISTS (
      SELECT 1
      FROM  public.users u
      JOIN  public.roles r ON r.id = u.role_id
      WHERE u.id = auth.uid()
        AND LOWER(TRIM(r.name)) = 'super admin'
    )
    OR
    -- Employee with admin-level text role (pre-004 compat)
    EXISTS (
      SELECT 1
      FROM  public.employees
      WHERE auth_user_id = auth.uid()
        AND status = 'active'
        AND role IN ('owner', 'branch_manager')
    );
$$;

-- ---------------------------------------------------------------------------
-- get_my_business_context()
--
-- Priority:
--   1. public.users row WHERE business_id IS NOT NULL  (owner / super-admin)
--   2. public.employees row WHERE auth_user_id matches  (employee)
--
-- This correctly handles the fact that handle_new_auth_user() creates a
-- public.users row for employees too, but with NULL business_id.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_my_business_context()
  RETURNS TABLE (
    business_id    uuid,
    business_name  text,
    role_id        uuid,
    role_name      text,
    branch_id      uuid,
    branch_name    text,
    full_name      text,
    template_id    uuid,
    template_name  text
  )
  LANGUAGE sql STABLE SECURITY DEFINER
  SET search_path = public AS
$$
  -- 1 · Owner / super-admin (public.users row has a business_id)
  SELECT
    b.id        AS business_id,
    b.name      AS business_name,
    r.id        AS role_id,
    r.name      AS role_name,
    br.id       AS branch_id,
    br.name     AS branch_name,
    u.full_name AS full_name,
    bt.id       AS template_id,
    bt.name     AS template_name
  FROM       public.users              u
  LEFT JOIN  public.businesses         b  ON b.id  = u.business_id
  LEFT JOIN  public.roles              r  ON r.id  = u.role_id
  LEFT JOIN  public.branches           br ON br.id = u.branch_id
  LEFT JOIN  public.business_templates bt ON bt.id = b.template_id
  WHERE u.id          = auth.uid()
    AND u.business_id IS NOT NULL          -- exclude "stub" rows created for employees

  UNION ALL

  -- 2 · Employee account
  --     Only reached when the public.users row has no business context.
  --     The IS NOT NULL guard is what makes this work — without it the
  --     UNION ALL first branch always fires for stub rows (NULL business_id)
  --     and the employee branch is never reached.
  SELECT
    e.business_id  AS business_id,
    b.name         AS business_name,
    -- role_id column does not exist until migration 004 adds it.
    -- Migration 004 replaces this function with the real role_id join.
    NULL::uuid     AS role_id,
    e.role         AS role_name,  -- raw text ('cashier', 'owner', etc.)
    e.branch_id    AS branch_id,
    br.name        AS branch_name,
    e.full_name    AS full_name,
    bt.id          AS template_id,
    bt.name        AS template_name
  FROM       public.employees          e
  LEFT JOIN  public.businesses         b  ON b.id  = e.business_id
  LEFT JOIN  public.branches           br ON br.id = e.branch_id
  LEFT JOIN  public.business_templates bt ON bt.id = b.template_id
  WHERE e.auth_user_id = auth.uid()
    AND e.status       = 'active'
    AND NOT EXISTS (
      SELECT 1 FROM public.users
       WHERE id          = auth.uid()
         AND business_id IS NOT NULL
    )

  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_business_context() TO authenticated;
GRANT EXECUTE ON FUNCTION public.my_business_id()          TO authenticated;
GRANT EXECUTE ON FUNCTION public.my_branch_id()            TO authenticated;
GRANT EXECUTE ON FUNCTION public.i_am_super_admin()        TO authenticated;
