-- =============================================================================
-- Enforce employees.edit / employees.suspend on direct (authenticated) writes.
--
-- The existing employees_update policy allows "admins (i_am_super_admin) OR self".
-- Two granular gaps remain:
--   1. an admin WITHOUT employees.edit could still edit other staff;
--   2. changing is_active (suspend/reactivate) wasn't tied to employees.suspend.
--
-- (1) RESTRICTIVE UPDATE policy: editing ANOTHER employee requires
--     employees.edit; a self-profile edit (auth_user_id = auth.uid()) stays open.
--     RESTRICTIVE so it ANDs onto the existing policy without replacing it.
--
-- (2) BEFORE UPDATE OF is_active trigger: changing active status requires
--     employees.suspend. A trigger is required because RLS WITH CHECK can't
--     compare OLD/NEW. Owner always allowed; an unchanged is_active is a no-op.
--
-- SAFE with employee creation: create_employee_auth_account() runs SECURITY
-- DEFINER (bypasses RLS) and only sets auth_user_id (not is_active), so neither
-- the policy nor the trigger fires for it. Both honour overrides + owner bypass
-- via has_permission().
--
-- ROLLBACK:
--   DROP POLICY employees_perm_edit ON public.employees;
--   DROP TRIGGER trg_enforce_employee_suspend ON public.employees;
--   DROP FUNCTION enforce_employee_suspend_authority();
-- =============================================================================

-- (1) Editing another employee requires employees.edit; self stays open.
DROP POLICY IF EXISTS employees_perm_edit ON public.employees;
CREATE POLICY employees_perm_edit ON public.employees
  AS RESTRICTIVE FOR UPDATE TO authenticated
  USING (auth_user_id = auth.uid() OR has_permission('employees.edit'));

-- (2) Suspend / reactivate requires employees.suspend.
CREATE OR REPLACE FUNCTION enforce_employee_suspend_authority()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN RETURN NEW; END IF;
  -- No change to active status → nothing to enforce.
  IF NEW.is_active IS NOT DISTINCT FROM OLD.is_active THEN RETURN NEW; END IF;
  -- Business owner may always change active status.
  IF EXISTS (
    SELECT 1 FROM businesses b
    WHERE b.id = NEW.business_id AND b.owner_id = auth.uid()
  ) THEN
    RETURN NEW;
  END IF;
  IF NOT has_permission('employees.suspend') THEN
    RAISE EXCEPTION
      'UNAUTHORIZED: employees.suspend permission required to change employee active status'
      USING errcode = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_employee_suspend ON public.employees;
CREATE TRIGGER trg_enforce_employee_suspend
  BEFORE UPDATE OF is_active ON public.employees
  FOR EACH ROW EXECUTE FUNCTION enforce_employee_suspend_authority();
