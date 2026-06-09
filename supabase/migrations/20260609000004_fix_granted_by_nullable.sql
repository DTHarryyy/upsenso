-- =============================================================================
-- UPSENSO — Fix granted_by nullability and harden set_employee_permission_override
-- =============================================================================
-- Root cause: get_my_employee_id() returns NULL when the acting owner has no
-- active employee row linked via auth_user_id. Because granted_by was NOT NULL,
-- the INSERT in set_employee_permission_override violates the constraint.
--
-- Fix strategy (long-term / scalable):
--   1. Make granted_by nullable — architecturally correct because service
--      accounts, owner-level auth users, and automated jobs may have no
--      employee row and should still be able to grant permissions.
--   2. Replace the FK constraint with a partial FK that only enforces referential
--      integrity when granted_by IS NOT NULL (standard pattern for nullable FKs).
--   3. Harden set_employee_permission_override to surface a clear error when
--      the caller has NO employee record AND no auth.uid() — which would be a
--      genuine misconfiguration.
--   4. Add a granter_auth_uid column so there is always an audit trail even
--      when granted_by (employee FK) is NULL.
-- =============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Make granted_by nullable
-- ─────────────────────────────────────────────────────────────────────────────

-- Drop the existing NOT NULL + FK constraint so we can redefine it.
ALTER TABLE user_permissions
  ALTER COLUMN granted_by DROP NOT NULL;

-- The original REFERENCES employees(id) is implicit via the column definition.
-- Re-add as a named constraint so it can be managed independently.
-- (If the original unnamed FK still exists, this is a no-op in intent; Postgres
--  will enforce the new named one and the old one stays harmless.)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE  constraint_name = 'user_permissions_granted_by_fkey'
      AND  table_name      = 'user_permissions'
  ) THEN
    ALTER TABLE user_permissions
      ADD CONSTRAINT user_permissions_granted_by_fkey
      FOREIGN KEY (granted_by) REFERENCES employees(id)
      ON DELETE SET NULL;   -- if the granting employee is removed, don't lose the row
  END IF;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Add granter_auth_uid for a complete audit trail when granted_by is NULL
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE user_permissions
  ADD COLUMN IF NOT EXISTS granter_auth_uid uuid
    REFERENCES auth.users(id) ON DELETE SET NULL;

COMMENT ON COLUMN user_permissions.granted_by IS
  'Employee record of whoever granted this permission. NULL when the granter '
  'has no employee row (e.g. service account or owner-level auth user). '
  'See granter_auth_uid for the full audit trail.';

COMMENT ON COLUMN user_permissions.granter_auth_uid IS
  'auth.uid() of whoever granted this permission. Always populated. '
  'Provides audit trail even when granted_by (employee FK) is NULL.';


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Backfill granter_auth_uid for existing rows where granted_by IS NOT NULL
-- ─────────────────────────────────────────────────────────────────────────────

UPDATE user_permissions up
SET    granter_auth_uid = e.auth_user_id
FROM   employees e
WHERE  e.id              = up.granted_by
  AND  up.granter_auth_uid IS NULL
  AND  e.auth_user_id   IS NOT NULL;


-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Replace set_employee_permission_override with hardened version
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
  v_permission_id  uuid;
  v_business_id    uuid;
  v_caller_emp_id  uuid;   -- may be NULL for owner-type accounts
  v_auth_uid       uuid;   -- always present for authenticated callers
BEGIN
  -- Authorisation: only owners/admins may change overrides.
  IF NOT i_am_super_admin() THEN
    RAISE EXCEPTION 'Permission denied: only owners and admins may set permission overrides';
  END IF;

  -- Caller identity — auth.uid() must always be present.
  v_auth_uid := auth.uid();
  IF v_auth_uid IS NULL THEN
    RAISE EXCEPTION 'Cannot set permission override: no authenticated session found';
  END IF;

  -- Employee record is optional; NULL is valid for owner-type accounts.
  v_caller_emp_id := get_my_employee_id();

  -- Self-modification guard: block when the caller has an employee record
  -- that matches the target. If caller has no employee record they cannot
  -- be the same employee as the target, so the guard is skipped safely.
  IF v_caller_emp_id IS NOT NULL AND p_employee_id = v_caller_emp_id THEN
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

  IF p_is_granted IS NULL THEN
    -- Remove override → revert to role default.
    DELETE FROM user_permissions
    WHERE  employee_id   = p_employee_id
      AND  permission_id = v_permission_id
      AND  branch_id     IS NULL;
  ELSE
    -- Upsert override. granted_by is NULL when the caller has no employee row;
    -- granter_auth_uid always records the caller's auth identity for audit.
    INSERT INTO user_permissions
      (business_id, employee_id, branch_id, permission_id,
       is_granted, granted_by, granter_auth_uid, is_active)
    VALUES
      (v_business_id, p_employee_id, NULL, v_permission_id,
       p_is_granted, v_caller_emp_id, v_auth_uid, true)
    ON CONFLICT ON CONSTRAINT up_employee_branch_permission_unique
    DO UPDATE SET
      is_granted       = EXCLUDED.is_granted,
      granted_by       = EXCLUDED.granted_by,
      granter_auth_uid = EXCLUDED.granter_auth_uid,
      is_active        = true,
      expires_at       = NULL,
      updated_at       = now();
  END IF;
END;
$$;

COMMENT ON FUNCTION set_employee_permission_override(uuid, text, boolean) IS
  'Upserts (or removes when p_is_granted IS NULL) a business-wide permission override '
  'for an employee. Only callable by owners/admins. Fills granted_by (employee FK, '
  'nullable) and granter_auth_uid (always set) automatically from the caller session. '
  'Self-modification is blocked when the caller has an employee record.';
