-- =============================================================================
-- Fix accumulated schema errors
-- =============================================================================

-- Fix 1: get_my_permissions() referenced e.branch_id which doesn't exist on
--        employees — branch assignment is in the employee_branches junction table.
CREATE OR REPLACE FUNCTION get_my_permissions()
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
  FROM   employees e
  WHERE  e.auth_user_id = auth.uid()
    AND  e.is_active    = true
  LIMIT  1;

  IF v_employee_id IS NULL THEN
    RETURN '{}'::jsonb;
  END IF;

  SELECT branch_id INTO v_branch_id
  FROM   employee_branches
  WHERE  employee_id = v_employee_id
  LIMIT  1;

  IF NOT EXISTS (
    SELECT 1 FROM effective_permissions
    WHERE employee_id = v_employee_id
      AND (branch_id = v_branch_id
           OR (branch_id IS NULL AND v_branch_id IS NULL))
  ) THEN
    PERFORM compute_employee_permissions(v_employee_id, v_branch_id);
  END IF;

  SELECT jsonb_object_agg(permission_code, is_granted)
  INTO   v_result
  FROM   effective_permissions
  WHERE  employee_id = v_employee_id
    AND  (branch_id = v_branch_id
          OR (branch_id IS NULL AND v_branch_id IS NULL));

  RETURN COALESCE(v_result, '{}'::jsonb);
END;
$$;

-- Fix 2: audit_logs is missing the action_type column the Flutter app writes.
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS action_type text;

-- Fix 3 & 4: receipt_settings and categories missing grants for authenticated role.
GRANT SELECT, INSERT, UPDATE ON public.receipt_settings TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.categories TO authenticated;

SELECT pg_notify('pgrst', 'reload schema');
