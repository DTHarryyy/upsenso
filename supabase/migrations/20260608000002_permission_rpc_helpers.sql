-- =============================================================================
-- UPSENSO — Permission override RPC helpers
-- =============================================================================
-- Adds two SECURITY DEFINER functions so the Flutter client can read/write
-- user_permissions without needing to know internal UUIDs (permission_id,
-- granted_by, business_id) or deal with the NULLS NOT DISTINCT upsert.
-- =============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- 1. get_employee_permission_overrides(employee_id)
-- Returns business-wide (branch_id IS NULL) active overrides for one employee.
-- Readable by the employee themselves OR any owner/admin in the same business.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_employee_permission_overrides(
  p_employee_id uuid
)
RETURNS TABLE (permission_code text, is_granted boolean)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT  p.code        AS permission_code,
          up.is_granted
  FROM    user_permissions up
  JOIN    permissions      p  ON p.id  = up.permission_id
  WHERE   up.employee_id = p_employee_id
    AND   up.branch_id   IS NULL
    AND   up.is_active   = true
    AND   (up.expires_at IS NULL OR up.expires_at > now())
    AND   up.business_id = get_my_business_id()
    AND   (
            p_employee_id = get_my_employee_id()
            OR i_am_super_admin()
          )
$$;

COMMENT ON FUNCTION get_employee_permission_overrides(uuid) IS
  'Returns active business-wide permission overrides for an employee. '
  'Readable by the employee themselves or any owner/admin.';


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. set_employee_permission_override(employee_id, permission_code, is_granted)
-- Upserts (or removes when is_granted IS NULL) a business-wide override.
-- Callable ONLY by owners/admins (enforced inside the function).
-- Automatically fills business_id and granted_by from the caller's session.
-- ─────────────────────────────────────────────────────────────────────────────

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
  v_permission_id uuid;
  v_business_id   uuid;
  v_granted_by    uuid;
BEGIN
  -- Authorisation: only owners/admins may change overrides.
  IF NOT i_am_super_admin() THEN
    RAISE EXCEPTION 'Permission denied: only owners and admins may set permission overrides';
  END IF;

  -- Resolve permission UUID from the human-readable code.
  SELECT id INTO v_permission_id
  FROM   permissions
  WHERE  code = p_permission_code;

  IF v_permission_id IS NULL THEN
    RAISE EXCEPTION 'Unknown permission code: %', p_permission_code;
  END IF;

  -- Resolve business_id from the target employee (cross-checks RLS scope).
  SELECT business_id INTO v_business_id
  FROM   employees
  WHERE  id = p_employee_id
    AND  business_id = get_my_business_id();

  IF v_business_id IS NULL THEN
    RAISE EXCEPTION 'Employee % not found in your business', p_employee_id;
  END IF;

  -- Resolve the caller's own employee record for the audit trail.
  v_granted_by := get_my_employee_id();

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
END;
$$;

COMMENT ON FUNCTION set_employee_permission_override(uuid, text, boolean) IS
  'Upserts (or removes when p_is_granted IS NULL) a business-wide permission override '
  'for an employee. Only callable by owners/admins. Fills business_id and granted_by '
  'automatically from the caller''s JWT session.';
