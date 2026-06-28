-- =============================================================================
-- Layer-2 authoritative anti-escalation on role assignment. APPLIED to production
-- 2026-06-26 (remote version 20260626153155).
--
-- Closes a LIVE self-escalation vector: employees_update RLS allows a non-owner
-- to update their OWN row, so they could set their own role_name to a higher role;
-- the SECURITY DEFINER trigger trg_fn_sync_employee_role then rewrites
-- employee_roles (which has_permission reads) — granting the higher permissions.
--
-- (A) BEFORE INSERT/UPDATE trigger on employees gates role_name changes: a
--     non-owner may not set a role at or above their own priority, and must hold
--     employees.assign_role. Owners, super-admins, and server/service contexts
--     (auth.uid() IS NULL) are exempt; a write that leaves role_name unchanged
--     (or empty) early-returns so benign profile edits are unaffected.
-- (B) RESTRICTIVE employee_roles INSERT/UPDATE policies as defense-in-depth
--     against a raw API write straight to the junction.
--
-- WHY SAFE (verified read-only 2026-06-26): employees & employee_roles both have
-- FORCE ROW LEVEL SECURITY, BUT every relevant SECURITY DEFINER function
-- (incl. trg_fn_sync_employee_role) is owned by `postgres` (rolbypassrls = true),
-- so the legitimate sync BYPASSES RLS and is NOT blocked by (B); (B) only gates
-- direct `authenticated` writes (the client never writes employee_roles directly
-- — roles flow via employees.role_name). The new trigger, created as postgres,
-- likewise bypasses RLS for its internal SELECTs.
--
-- NOTE: the trigger's auth-context branches were not integration-tested from the
-- MCP (execute_sql runs with a null JWT). In-app validation: an owner creating/
-- editing employees still works (exempt); a non-owner attempting to assign/raise
-- a role at or above their own level is rejected with a check_violation.
--
-- ROLLBACK:
--   DROP TRIGGER IF EXISTS trg_enforce_role_assignment_authority ON public.employees;
--   DROP FUNCTION IF EXISTS public.enforce_role_assignment_authority();
--   DROP POLICY IF EXISTS employee_roles_no_escalation_ins ON public.employee_roles;
--   DROP POLICY IF EXISTS employee_roles_no_escalation_upd ON public.employee_roles;
-- =============================================================================

CREATE OR REPLACE FUNCTION public.enforce_role_assignment_authority()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_is_owner    boolean;
  v_target_prio int;
  v_caller_prio int;
  v_new text := lower(trim(coalesce(NEW.role_name, '')));
  v_old text := lower(trim(coalesce(OLD.role_name, '')));
BEGIN
  IF auth.uid() IS NULL THEN RETURN NEW; END IF;
  IF v_new = '' THEN RETURN NEW; END IF;
  IF TG_OP = 'UPDATE' AND v_new = v_old THEN RETURN NEW; END IF;

  SELECT EXISTS (
    SELECT 1 FROM businesses WHERE id = NEW.business_id AND owner_id = auth.uid()
  ) INTO v_is_owner;
  IF v_is_owner OR public.i_am_super_admin() THEN RETURN NEW; END IF;

  IF NOT public.has_permission('employees.assign_role') THEN
    RAISE EXCEPTION 'UNAUTHORIZED: employees.assign_role permission required'
      USING errcode = 'check_violation';
  END IF;

  SELECT priority INTO v_target_prio
  FROM roles
  WHERE business_id = NEW.business_id AND lower(name) = v_new
  LIMIT 1;
  IF v_target_prio IS NULL THEN
    RAISE EXCEPTION 'Invalid role: %', NEW.role_name USING errcode = 'check_violation';
  END IF;

  SELECT COALESCE(MAX(r.priority), -1) INTO v_caller_prio
  FROM employees e
  JOIN employee_roles er ON er.employee_id = e.id
  JOIN roles r           ON r.id           = er.role_id
  WHERE e.auth_user_id = auth.uid();

  IF v_target_prio >= v_caller_prio THEN
    RAISE EXCEPTION 'UNAUTHORIZED: cannot assign a role at or above your own level'
      USING errcode = 'check_violation';
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_enforce_role_assignment_authority ON public.employees;
CREATE TRIGGER trg_enforce_role_assignment_authority
  BEFORE INSERT OR UPDATE ON public.employees
  FOR EACH ROW EXECUTE FUNCTION public.enforce_role_assignment_authority();

DROP POLICY IF EXISTS employee_roles_no_escalation_ins ON public.employee_roles;
CREATE POLICY employee_roles_no_escalation_ins ON public.employee_roles
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM employees e JOIN businesses b ON b.id = e.business_id
      WHERE e.id = employee_roles.employee_id AND b.owner_id = auth.uid()
    )
    OR i_am_super_admin()
    OR (
      has_permission('employees.assign_role')
      AND (SELECT priority FROM roles WHERE id = employee_roles.role_id)
          < COALESCE((
              SELECT MAX(r.priority) FROM employees e2
              JOIN employee_roles er ON er.employee_id = e2.id
              JOIN roles r ON r.id = er.role_id
              WHERE e2.auth_user_id = auth.uid()
            ), -1)
    )
  );

DROP POLICY IF EXISTS employee_roles_no_escalation_upd ON public.employee_roles;
CREATE POLICY employee_roles_no_escalation_upd ON public.employee_roles
  AS RESTRICTIVE FOR UPDATE TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM employees e JOIN businesses b ON b.id = e.business_id
      WHERE e.id = employee_roles.employee_id AND b.owner_id = auth.uid()
    )
    OR i_am_super_admin()
    OR (
      has_permission('employees.assign_role')
      AND (SELECT priority FROM roles WHERE id = employee_roles.role_id)
          < COALESCE((
              SELECT MAX(r.priority) FROM employees e2
              JOIN employee_roles er ON er.employee_id = e2.id
              JOIN roles r ON r.id = er.role_id
              WHERE e2.auth_user_id = auth.uid()
            ), -1)
    )
  );

SELECT pg_notify('pgrst', 'reload schema');
