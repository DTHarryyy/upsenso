-- =============================================================================
-- UPSENSO — Permission security hardening
-- =============================================================================
-- Fixes two vulnerabilities identified in the permission override system:
--
--   1. Self-escalation: set_employee_permission_override() had no guard
--      preventing an owner from modifying their own permissions.
--
--   2. user_permissions RLS used a single FOR ALL policy, making it
--      impossible to apply different rules for INSERT vs SELECT vs DELETE.
--      Split into explicit policies per operation.
-- =============================================================================


-- =============================================================================
-- 1. Replace set_employee_permission_override with self-modification guard
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
BEGIN
  -- Authorisation: only owners/admins may change overrides.
  IF NOT i_am_super_admin() THEN
    RAISE EXCEPTION 'Permission denied: only owners and admins may set permission overrides';
  END IF;

  -- Self-modification guard: an admin cannot escalate or reduce their own permissions.
  -- This prevents privilege self-escalation and accidental self-lockout.
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

  -- Resolve business_id from the target employee (cross-checks caller's business scope).
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
END;
$$;

COMMENT ON FUNCTION set_employee_permission_override(uuid, text, boolean) IS
  'Upserts (or removes when p_is_granted IS NULL) a business-wide permission override '
  'for an employee. Only callable by owners/admins. Fills business_id and granted_by '
  'automatically from the caller''s JWT session. Self-modification is blocked.';


-- =============================================================================
-- 2. Split user_permissions RLS into explicit per-operation policies
-- =============================================================================
-- The previous single FOR ALL policy allowed any authenticated user to attempt
-- writes as long as they passed the SELECT filter — not the intended behaviour.
-- Replace with explicit INSERT / UPDATE / DELETE policies that require
-- i_am_super_admin(), and a tighter SELECT policy scoped to own business.

-- Drop the catch-all policy if it exists.
DROP POLICY IF EXISTS "user_permissions: owner/admin full access" ON user_permissions;
DROP POLICY IF EXISTS "user_permissions_owner_admin" ON user_permissions;

-- SELECT: employee sees their own overrides; owner/admin sees all in the business.
DROP POLICY IF EXISTS "user_permissions_select" ON user_permissions;
CREATE POLICY "user_permissions_select"
  ON user_permissions
  FOR SELECT
  USING (
    business_id = get_my_business_id()
    AND (
      employee_id = get_my_employee_id()
      OR i_am_super_admin()
    )
  );

-- INSERT: owner/admin only, within their business.
DROP POLICY IF EXISTS "user_permissions_insert" ON user_permissions;
CREATE POLICY "user_permissions_insert"
  ON user_permissions
  FOR INSERT
  WITH CHECK (
    business_id = get_my_business_id()
    AND i_am_super_admin()
  );

-- UPDATE: owner/admin only, within their business.
DROP POLICY IF EXISTS "user_permissions_update" ON user_permissions;
CREATE POLICY "user_permissions_update"
  ON user_permissions
  FOR UPDATE
  USING (
    business_id = get_my_business_id()
    AND i_am_super_admin()
  )
  WITH CHECK (
    business_id = get_my_business_id()
    AND i_am_super_admin()
  );

-- DELETE: owner/admin only, within their business.
DROP POLICY IF EXISTS "user_permissions_delete" ON user_permissions;
CREATE POLICY "user_permissions_delete"
  ON user_permissions
  FOR DELETE
  USING (
    business_id = get_my_business_id()
    AND i_am_super_admin()
  );
