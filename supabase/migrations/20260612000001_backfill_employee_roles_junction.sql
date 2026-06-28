-- =============================================================================
-- Backfill employee_roles junction + trigger to keep it in sync
--
-- WHY this is needed:
--   compute_employee_permissions() resolves role grants via the employee_roles
--   junction table (Layer 5). The Flutter app and create_employee_auth_account
--   RPC write employees.role_name (text) but never insert into employee_roles.
--   As a result, every employee snapshot came back default_deny for all codes
--   because employee_roles was empty for every employee.
--
-- This migration:
--   1. Backfills employee_roles by matching employees.role_name -> roles.name
--   2. Creates a trigger so every future INSERT/UPDATE on employees
--      automatically maintains the junction row
--   3. Recomputes effective_permissions for all active employees so the fix
--      takes effect immediately without waiting for re-login
--
-- Reconciliation note (2026-06-28): this migration ran on prod on 2026-06-12
-- but was never captured in this repo at the time — a different, unrelated
-- migration (add_procurement_ingredients_recipes_modules) was later committed
-- under this same version number and has been moved to 20260612000002 to free
-- this slot. This file reproduces the prod-applied SQL verbatim so a fresh
-- `supabase db reset` matches prod instead of regressing the default-deny bug.
--
-- ROLLBACK:
--   DROP TRIGGER trg_sync_employee_role ON public.employees;
--   DROP FUNCTION trg_fn_sync_employee_role();
--   -- (the employee_roles backfill rows are not removed by rollback)
-- =============================================================================

-- ── 1. Backfill ───────────────────────────────────────────────────────────────
-- Match by role name (case-insensitive). ON CONFLICT is safe — employees who
-- already have a junction row are skipped.

INSERT INTO employee_roles (employee_id, role_id)
SELECT e.id, r.id
FROM   employees e
JOIN   roles     r ON lower(r.name) = lower(e.role_name)
WHERE  e.role_name IS NOT NULL
ON CONFLICT DO NOTHING;

-- ── 2. Trigger function ───────────────────────────────────────────────────────
-- Runs AFTER INSERT OR UPDATE OF role_name ON employees.
-- Deletes any stale role row and inserts the current one so role changes
-- (e.g., promotion from Cashier → Branch Manager) are reflected instantly.

CREATE OR REPLACE FUNCTION trg_fn_sync_employee_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role_id uuid;
BEGIN
  -- Clear any previous role assignment for this employee.
  DELETE FROM employee_roles WHERE employee_id = NEW.id;

  -- Only insert if we can resolve the role.
  IF NEW.role_name IS NOT NULL THEN
    SELECT id INTO v_role_id FROM roles WHERE lower(name) = lower(NEW.role_name) LIMIT 1;
    IF v_role_id IS NOT NULL THEN
      INSERT INTO employee_roles (employee_id, role_id)
      VALUES (NEW.id, v_role_id)
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_employee_role ON public.employees;
CREATE TRIGGER trg_sync_employee_role
  AFTER INSERT OR UPDATE OF role_name ON public.employees
  FOR EACH ROW EXECUTE FUNCTION trg_fn_sync_employee_role();

-- ── 3. Recompute effective_permissions for all active employees ───────────────

DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT DISTINCT e.id AS employee_id, eb.branch_id
    FROM   employees        e
    JOIN   employee_branches eb ON eb.employee_id = e.id
    WHERE  e.is_active = true
  LOOP
    BEGIN
      PERFORM compute_employee_permissions(r.employee_id, r.branch_id);
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'recompute skipped employee=% branch=%: %',
        r.employee_id, r.branch_id, SQLERRM;
    END;
  END LOOP;
END;
$$;

SELECT pg_notify('pgrst', 'reload schema');
