-- ============================================================
-- Production-grade employee role normalization
--
-- Problem: employees.role is a loose text enum ('cashier',
-- 'inventory_staff', etc.) with no FK to public.roles.
-- public.users.role_id is a proper UUID FK to public.roles,
-- giving it full RBAC (permissions JSON, audit trail, etc.)
-- Employees lack this entirely.
--
-- This migration:
--   1. ensure_standard_roles(business_id) — idempotent seeder.
--   2. Backfill all existing businesses.
--   3. Trigger on businesses INSERT — auto-seeds roles.
--   4. _employee_role_display_name() — maps text→display name.
--   5. employees.role_id — FK to public.roles.
--   6. sync_employee_role_id() trigger — keeps role_id in sync
--      with the text role column on INSERT / UPDATE.
--   7. Backfill role_id for existing employee rows.
--   8. Updated get_my_business_context() — returns real role_id
--      and roles.name for employees (not NULL / raw text).
--   9. Updated i_am_super_admin() — uses role_id JOIN for the
--      belt-and-suspenders check.
-- ============================================================


-- =============================================================================
-- 1 · Standard-role seeder
-- =============================================================================
-- Creates the 5 canonical roles for a business when they do not yet exist.
-- Safe to call many times (ON CONFLICT DO NOTHING).
-- permissions follow the module keys used by the Flutter router.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.ensure_standard_roles(p_business_id uuid)
  RETURNS void
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
AS $$
BEGIN
  INSERT INTO public.roles (business_id, name, permissions)
  VALUES
    (p_business_id, 'Super Admin',     '{"all": true}'),
    (p_business_id, 'Owner',           '{"all": true}'),
    (p_business_id, 'Branch Manager',  '{"modules": ["dashboard","products","pos","inventory","reports","expenses","settings","employees","audit_logs"]}'),
    (p_business_id, 'Cashier',         '{"modules": ["pos"]}'),
    (p_business_id, 'Inventory Staff', '{"modules": ["inventory"]}')
  ON CONFLICT (business_id, name) DO NOTHING;
END;
$$;

GRANT EXECUTE ON FUNCTION public.ensure_standard_roles(uuid) TO authenticated;


-- =============================================================================
-- 2 · Backfill all existing businesses
-- =============================================================================

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN SELECT id FROM public.businesses LOOP
    PERFORM public.ensure_standard_roles(r.id);
  END LOOP;
END;
$$;


-- =============================================================================
-- 3 · Auto-seed roles whenever a new business is created
-- =============================================================================

CREATE OR REPLACE FUNCTION public.seed_business_roles()
  RETURNS trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
AS $$
BEGIN
  PERFORM public.ensure_standard_roles(NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_seed_business_roles ON public.businesses;
CREATE TRIGGER trg_seed_business_roles
  AFTER INSERT ON public.businesses
  FOR EACH ROW EXECUTE FUNCTION public.seed_business_roles();


-- =============================================================================
-- 4 · Helper: map employees.role text → public.roles.name
-- =============================================================================
-- The text enum values use snake_case; roles.name uses Title Case with spaces
-- so they display nicely in the UI without any Flutter-side formatting.
-- =============================================================================

CREATE OR REPLACE FUNCTION public._employee_role_display_name(p_role text)
  RETURNS text
  LANGUAGE sql
  IMMUTABLE
AS $$
  SELECT CASE p_role
    WHEN 'owner'           THEN 'Owner'
    WHEN 'branch_manager'  THEN 'Branch Manager'
    WHEN 'cashier'         THEN 'Cashier'
    WHEN 'inventory_staff' THEN 'Inventory Staff'
    ELSE initcap(replace(p_role, '_', ' '))   -- safe fallback
  END;
$$;


-- =============================================================================
-- 5 · Add role_id FK column to employees
-- =============================================================================

ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS role_id uuid
    REFERENCES public.roles(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.employees.role_id IS
  'FK to public.roles — same RBAC join as public.users.role_id.
   Populated automatically by trg_employee_role_id.
   The companion text column employees.role remains for fast
   CHECK-constraint validation and backward-compat queries.';


-- =============================================================================
-- 6 · Trigger: keep role_id in sync with the text role column
-- =============================================================================
-- Fires BEFORE INSERT OR UPDATE OF role so role_id is always consistent
-- with the text value without requiring callers to look up the UUID.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.sync_employee_role_id()
  RETURNS trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public
AS $$
BEGIN
  -- Guarantee the standard roles exist for this business
  PERFORM public.ensure_standard_roles(NEW.business_id);

  -- Resolve role_id from the canonical display name
  SELECT id
    INTO NEW.role_id
    FROM public.roles
   WHERE business_id = NEW.business_id
     AND name        = public._employee_role_display_name(NEW.role)
   LIMIT 1;

  -- Fail loudly rather than silently leave role_id NULL
  IF NEW.role_id IS NULL THEN
    RAISE EXCEPTION
      'Could not resolve role_id for role=% in business=%',
      NEW.role, NEW.business_id
      USING ERRCODE = 'integrity_constraint_violation';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_employee_role_id ON public.employees;
CREATE TRIGGER trg_employee_role_id
  BEFORE INSERT OR UPDATE OF role ON public.employees
  FOR EACH ROW EXECUTE FUNCTION public.sync_employee_role_id();


-- =============================================================================
-- 7 · Backfill role_id for existing employee rows
-- =============================================================================

UPDATE public.employees e
   SET role_id = r.id
  FROM public.roles r
 WHERE r.business_id = e.business_id
   AND r.name        = public._employee_role_display_name(e.role)
   AND e.role_id     IS NULL;


-- =============================================================================
-- 8 · Updated get_my_business_context()
--     Employees now return a real role_id UUID and roles.name
--     instead of NULL / raw text.
-- =============================================================================

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
    AND u.business_id IS NOT NULL

  UNION ALL

  -- 2 · Employee account (has auth_user_id; public.users.business_id is NULL)
  SELECT
    e.business_id AS business_id,
    b.name        AS business_name,
    er.id         AS role_id,    -- real UUID from public.roles
    er.name       AS role_name,  -- e.g. 'Cashier', 'Branch Manager'
    e.branch_id   AS branch_id,
    br.name       AS branch_name,
    e.full_name   AS full_name,
    bt.id         AS template_id,
    bt.name       AS template_name
  FROM       public.employees          e
  LEFT JOIN  public.businesses         b  ON b.id  = e.business_id
  LEFT JOIN  public.roles              er ON er.id = e.role_id
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


-- =============================================================================
-- 9 · Updated i_am_super_admin()
--     Belt-and-suspenders: checks both the text role (fast path, handles
--     any row inserted before 004) and the role_id FK join (canonical path).
-- =============================================================================

CREATE OR REPLACE FUNCTION public.i_am_super_admin()
  RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
  SET search_path = public AS
$$
  SELECT
    -- Regular business-owner (public.users + public.roles 'Super Admin')
    EXISTS (
      SELECT 1
      FROM  public.users u
      JOIN  public.roles r ON r.id = u.role_id
      WHERE u.id = auth.uid()
        AND LOWER(TRIM(r.name)) = 'super admin'
    )
    OR
    -- Employee: text role fast-path (always present)
    EXISTS (
      SELECT 1
      FROM  public.employees
      WHERE auth_user_id = auth.uid()
        AND status       = 'active'
        AND role         IN ('owner', 'branch_manager')
    )
    OR
    -- Employee: role_id FK join (canonical, post-004)
    EXISTS (
      SELECT 1
      FROM  public.employees e
      JOIN  public.roles     r ON r.id = e.role_id
      WHERE e.auth_user_id = auth.uid()
        AND e.status       = 'active'
        AND LOWER(r.name)  IN ('owner', 'branch manager')
    );
$$;

GRANT EXECUTE ON FUNCTION public.i_am_super_admin() TO authenticated;
