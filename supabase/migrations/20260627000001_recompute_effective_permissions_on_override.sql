-- =============================================================================
-- Fix: per-employee permission overrides never reached the client.
--
-- ROOT CAUSE
--   set_employee_permission_override() writes to user_permissions but never
--   recomputes the effective_permissions snapshot. The user_permissions trigger
--   (trg_fn_user_perm_changed) only bumps permission_snapshot_versions — it does
--   NOT recompute either. get_my_permissions() (the client's only read path)
--   recomputes ONLY when no snapshot row exists; after the v2 backfill every
--   employee already has a snapshot, so it stays frozen at its bootstrap value
--   forever. Result: an override is stored but never appears in the UI, even
--   after logout/login.
--
-- FIX
--   After writing (or removing) an override, recompute effective_permissions for
--   the affected employee across every branch they read from: their assigned
--   branches (employee_branches), their primary branch (employees.branch_id —
--   what get_my_permissions reads), and any branch that already has a snapshot.
--   compute_employee_permissions() upserts, so this is idempotent and cheap
--   (one employee per call).
--
-- Propagation: the refreshed snapshot flows to the employee's device on their
--   next login / background sync (bootstrap.dart calls syncPermissions()).
--
-- ROLLBACK
--   Restore the prior definition from 20260609000002_permission_security_
--   hardening.sql (same body without the recompute loop). No schema change.
-- =============================================================================

CREATE OR REPLACE FUNCTION set_employee_permission_override(
  p_employee_id     uuid,
  p_permission_code text,
  p_is_granted      boolean   -- NULL = remove override (revert to role default)
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_permission_id  uuid;
  v_business_id    uuid;
  v_granted_by     uuid;
  v_caller_emp_id  uuid;
  v_branch         uuid;
BEGIN
  -- Authorisation: only owners/admins may change overrides.
  IF NOT i_am_super_admin() THEN
    RAISE EXCEPTION 'Permission denied: only owners and admins may set permission overrides';
  END IF;

  -- Self-modification guard: an admin cannot escalate or reduce their own
  -- permissions. Prevents privilege self-escalation and accidental self-lockout.
  v_caller_emp_id := get_my_employee_id();
  IF p_employee_id = v_caller_emp_id THEN
    RAISE EXCEPTION
      'You cannot modify your own permission overrides. Ask another admin to make this change.';
  END IF;

  -- Resolve permission UUID from the human-readable code.
  SELECT id INTO v_permission_id
  FROM   permissions
  WHERE  code = p_permission_code;

  IF v_permission_id IS NULL THEN
    RAISE EXCEPTION 'Unknown permission code: %', p_permission_code;
  END IF;

  -- Resolve business_id from the target employee (cross-checks caller's scope).
  SELECT business_id INTO v_business_id
  FROM   employees
  WHERE  id = p_employee_id
    AND  business_id = get_my_business_id();

  IF v_business_id IS NULL THEN
    RAISE EXCEPTION 'Employee % not found in your business', p_employee_id;
  END IF;

  v_granted_by := v_caller_emp_id;

  IF p_is_granted IS NULL THEN
    -- Remove override → revert to role default.
    DELETE FROM user_permissions
    WHERE  employee_id   = p_employee_id
      AND  permission_id = v_permission_id
      AND  branch_id     IS NULL;
  ELSE
    -- Upsert override (handles the NULLS NOT DISTINCT unique constraint safely).
    INSERT INTO user_permissions
      (business_id, employee_id, branch_id, permission_id,
       is_granted, granted_by, is_active)
    VALUES
      (v_business_id, p_employee_id, NULL, v_permission_id,
       p_is_granted, v_granted_by, true)
    ON CONFLICT ON CONSTRAINT up_employee_branch_permission_unique
    DO UPDATE SET
      is_granted = EXCLUDED.is_granted,
      granted_by = EXCLUDED.granted_by,
      is_active  = true,
      expires_at = NULL,
      updated_at = now();
  END IF;

  -- Recompute the snapshot so the override is reflected on the employee's next
  -- get_my_permissions() sync. The branch lives in employee_branches (there is
  -- no employees.branch_id); also cover any branch that already has a snapshot.
  FOR v_branch IN
    SELECT branch_id FROM employee_branches      WHERE employee_id = p_employee_id
    UNION
    SELECT branch_id FROM effective_permissions  WHERE employee_id = p_employee_id
  LOOP
    PERFORM compute_employee_permissions(p_employee_id, v_branch);
  END LOOP;
END;
$$;

COMMENT ON FUNCTION set_employee_permission_override(uuid, text, boolean) IS
  'Upserts (or removes when p_is_granted IS NULL) a business-wide permission override '
  'for an employee, then recomputes their effective_permissions snapshot so the change '
  'reaches the client on next sync. Owner/admin only; self-modification is blocked.';
