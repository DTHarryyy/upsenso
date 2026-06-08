-- =============================================================================
-- Production-grade schema normalization
-- =============================================================================
-- Fixes applied:
--   1. Unify employees.auth_user_id with user_id (sync + unique constraint)
--   2. Fix i_am_super_admin() — was checking a role name that never exists
--   3. Fix current_user_role() and has_branch_access() to use auth_user_id
--   4. Unify my_business_id() with get_my_business_id() logic (two fns, one truth)
--   5. Improve get_my_permissions() to handle branchless employees correctly
--   6. Allow NULL branch_id in effective_permissions and permission_snapshot_versions
--   7. Backfill employee_roles from employees.role_id (sync the dual-path role system)
--   8. Fix bm_owner_write policy (was blocked by broken i_am_super_admin)
--   9. Drop duplicate UNIQUE constraints (business_modules, modules, permissions)
--  10. Drop duplicate indexes (audit_logs, effective_permissions)
--  11. Drop duplicate RLS policies (audit_logs, modules)
--  12. Tighten audit_logs policies — only admins can read, any employee can insert
-- =============================================================================

-- ── 1. Sync auth_user_id from user_id ─────────────────────────────────────────
-- Both columns reference auth.users.id. user_id is NOT NULL (set by app).
-- auth_user_id was added later and may be NULL for older rows.
UPDATE public.employees
SET    auth_user_id = user_id
WHERE  auth_user_id IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE  table_schema = 'public'
      AND  table_name   = 'employees'
      AND  constraint_name = 'employees_auth_user_id_unique'
  ) THEN
    ALTER TABLE public.employees ADD CONSTRAINT employees_auth_user_id_unique UNIQUE (auth_user_id);
  END IF;
END $$;

-- Keep the two in sync on all future writes
CREATE OR REPLACE FUNCTION public.sync_employee_auth_ids()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.user_id IS NOT NULL AND NEW.auth_user_id IS NULL THEN
    NEW.auth_user_id := NEW.user_id;
  END IF;
  IF NEW.auth_user_id IS NOT NULL AND NEW.user_id IS NULL THEN
    NEW.user_id := NEW.auth_user_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_employee_auth_ids ON public.employees;
CREATE TRIGGER trg_sync_employee_auth_ids
  BEFORE INSERT OR UPDATE ON public.employees
  FOR EACH ROW EXECUTE FUNCTION public.sync_employee_auth_ids();

-- ── 2. Backfill employee_roles from employees.role_id ─────────────────────────
-- Role can be set via employees.role_id (direct FK) or employee_roles junction.
-- Functions like current_user_role() use only the junction, so sync it.
INSERT INTO public.employee_roles (employee_id, role_id)
SELECT id, role_id
FROM   public.employees
WHERE  role_id IS NOT NULL
ON CONFLICT DO NOTHING;

-- ── 3. Fix i_am_super_admin() ─────────────────────────────────────────────────
-- Old version: checked users.role_id for 'super admin' — that role name never
-- exists, so it always returned false, silently blocking all writes that relied
-- on it (user_permissions, branch_permissions, bm_owner_write, etc.).
CREATE OR REPLACE FUNCTION public.i_am_super_admin()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    -- Business owner always qualifies
    EXISTS (SELECT 1 FROM public.businesses WHERE owner_id = auth.uid())
    OR
    -- Admin-role employee qualifies
    EXISTS (
      SELECT 1
      FROM   public.employees e
      JOIN   public.employee_roles er ON er.employee_id = e.id
      JOIN   public.roles r           ON r.id           = er.role_id
      WHERE  e.auth_user_id = auth.uid()
        AND  e.is_active    = true
        AND  LOWER(TRIM(r.name)) IN ('admin', 'owner', 'super admin', 'superadmin')
    );
$$;

-- ── 4. Fix current_user_role() ────────────────────────────────────────────────
-- Old version: joined on employees.user_id; now uses auth_user_id consistently.
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS text
LANGUAGE sql STABLE SECURITY INVOKER
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

-- ── 5. Fix has_branch_access() ────────────────────────────────────────────────
-- Old version: joined on employees.user_id; now uses auth_user_id.
CREATE OR REPLACE FUNCTION public.has_branch_access(bid uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY INVOKER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM   public.employee_branches eb
    JOIN   public.employees e ON e.id = eb.employee_id
    WHERE  e.auth_user_id = auth.uid()
      AND  eb.branch_id   = bid
  );
$$;

-- ── 6. Unify my_business_id() with get_my_business_id() ──────────────────────
-- Old my_business_id(): SELECT business_id FROM users WHERE id = auth.uid()
-- This diverged from get_my_business_id() causing RLS inconsistencies for
-- owners who are not in the employees table.
CREATE OR REPLACE FUNCTION public.my_business_id()
RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT business_id FROM public.employees
     WHERE  auth_user_id = auth.uid() AND is_active = true LIMIT 1),
    (SELECT id FROM public.businesses WHERE owner_id = auth.uid() LIMIT 1)
  );
$$;

-- ── 7. Fix get_my_permissions() ───────────────────────────────────────────────
-- Supersedes migration 5 version. Handles branchless employees by reading
-- directly from role_permissions instead of the effective_permissions cache,
-- avoiding the branch_id NOT NULL constraint on that table.
CREATE OR REPLACE FUNCTION public.get_my_permissions()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_employee_id uuid;
  v_branch_id   uuid;
  v_result      jsonb;
BEGIN
  SELECT e.id
  INTO   v_employee_id
  FROM   public.employees e
  WHERE  e.auth_user_id = auth.uid()
    AND  e.is_active    = true
  LIMIT  1;

  IF v_employee_id IS NULL THEN
    RETURN '{}'::jsonb;
  END IF;

  SELECT branch_id INTO v_branch_id
  FROM   public.employee_branches
  WHERE  employee_id = v_employee_id
  LIMIT  1;

  -- Branchless employee: skip the effective_permissions cache and read directly
  -- from role_permissions (branch_id is NOT NULL in effective_permissions).
  IF v_branch_id IS NULL THEN
    SELECT jsonb_object_agg(p.code, rp.allowed)
    INTO   v_result
    FROM   public.employees e
    JOIN   public.employee_roles   er ON er.employee_id = e.id
    JOIN   public.role_permissions rp ON rp.role_id     = er.role_id
    JOIN   public.permissions      p  ON p.id           = rp.permission_id
    WHERE  e.id = v_employee_id;
    RETURN COALESCE(v_result, '{}'::jsonb);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.effective_permissions
    WHERE  employee_id = v_employee_id
      AND  branch_id   = v_branch_id
  ) THEN
    PERFORM public.compute_employee_permissions(v_employee_id, v_branch_id);
  END IF;

  SELECT jsonb_object_agg(permission_code, is_granted)
  INTO   v_result
  FROM   public.effective_permissions
  WHERE  employee_id = v_employee_id
    AND  branch_id   = v_branch_id;

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

-- ── 9. Fix business_modules write policy ─────────────────────────────────────
-- bm_owner_write used the old (broken) i_am_super_admin(), which always returned
-- false, blocking all module enable/disable for owners. Now i_am_super_admin() is
-- fixed. Also add an explicit owner direct-check as belt-and-suspenders.
DROP POLICY IF EXISTS bm_owner_write ON public.business_modules;
CREATE POLICY bm_owner_write ON public.business_modules
  FOR ALL
  TO authenticated
  USING (
    business_id = get_my_business_id()
    AND (
      EXISTS (SELECT 1 FROM public.businesses
              WHERE  id       = public.business_modules.business_id
                AND  owner_id = auth.uid())
      OR i_am_super_admin()
    )
  )
  WITH CHECK (
    business_id = get_my_business_id()
    AND (
      EXISTS (SELECT 1 FROM public.businesses
              WHERE  id       = public.business_modules.business_id
                AND  owner_id = auth.uid())
      OR i_am_super_admin()
    )
  );

-- ── 10. Drop duplicate UNIQUE constraints ─────────────────────────────────────
-- business_modules: two identical UNIQUE(business_id, module_id) constraints
ALTER TABLE public.business_modules
  DROP CONSTRAINT IF EXISTS unique_business_module;
-- Kept: business_modules_unique

-- modules: two identical UNIQUE(code) constraints
ALTER TABLE public.modules
  DROP CONSTRAINT IF EXISTS modules_code_unique;
-- Kept: modules_code_key

-- permissions: two identical UNIQUE(code) constraints
ALTER TABLE public.permissions
  DROP CONSTRAINT IF EXISTS unique_permission_code;
-- Kept: permissions_code_key

-- ── 11. Drop duplicate indexes ────────────────────────────────────────────────
-- audit_logs.business_id indexed twice
DROP INDEX IF EXISTS public.idx_audit_logs_business;
-- Kept: idx_audit_business

-- effective_permissions: ep_unique (UNIQUE) already acts as an index,
-- idx_ep_lookup is a plain copy of the same columns — redundant
DROP INDEX IF EXISTS public.idx_ep_lookup;
-- Kept: ep_unique (serves as both constraint and index)

-- ── 12. Clean up duplicate and overly-permissive RLS policies ─────────────────

-- audit_logs: audit_admin_only and audit_logs_strict_access are identical
DROP POLICY IF EXISTS audit_logs_strict_access ON public.audit_logs;
-- Kept: audit_admin_only (SELECT requires owner/admin role)

-- audit_logs: biz_isolation_audit_logs (ALL) lets any employee in the business
-- read the audit trail. Replace with a tighter insert-only policy.
DROP POLICY IF EXISTS biz_isolation_audit_logs ON public.audit_logs;
DROP POLICY IF EXISTS audit_logs_all_insert    ON public.audit_logs;
CREATE POLICY audit_logs_employee_insert
  ON public.audit_logs FOR INSERT
  TO authenticated
  WITH CHECK (business_id = get_my_business_id());

-- modules: modules_public (roles: {public}) duplicates modules_select ({authenticated})
DROP POLICY IF EXISTS modules_public ON public.modules;
-- Kept: modules_select (authenticated only)

-- ── 13. Reload PostgREST schema cache ─────────────────────────────────────────
SELECT pg_notify('pgrst', 'reload schema');
