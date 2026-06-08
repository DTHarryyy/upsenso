-- =============================================================================
-- set_module_enabled RPC
-- =============================================================================
-- Authorisation order:
--   1. businesses.owner_id = auth.uid()  (business owner, no employee record needed)
--   2. employees with role 'admin' in the same business (admin employee)
-- =============================================================================

CREATE OR REPLACE FUNCTION set_module_enabled(
  p_business_id uuid,
  p_module_code  text,
  p_enabled      boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role_name     text;
  v_module_id     uuid;
  v_is_authorized boolean := false;
BEGIN
  -- Check 1: Is the caller the business owner via businesses.owner_id?
  SELECT EXISTS (
    SELECT 1 FROM businesses
    WHERE id = p_business_id AND owner_id = auth.uid()
  ) INTO v_is_authorized;

  -- Check 2: Fallback — is the caller an admin employee of this business?
  IF NOT v_is_authorized THEN
    SELECT LOWER(TRIM(r.name)) INTO v_role_name
    FROM   employees e
    LEFT JOIN roles r ON r.id = e.role_id
    WHERE  e.business_id = p_business_id
      AND  (e.auth_user_id = auth.uid() OR e.user_id = auth.uid())
      AND  e.is_active = true
    LIMIT 1;

    v_is_authorized := v_role_name IN ('admin');
  END IF;

  IF NOT v_is_authorized THEN
    RAISE EXCEPTION 'Permission denied: only the business owner or an admin may change module settings';
  END IF;

  SELECT id INTO v_module_id FROM modules WHERE code = p_module_code;
  IF v_module_id IS NULL THEN
    RAISE EXCEPTION 'Unknown module code: %', p_module_code;
  END IF;

  INSERT INTO business_modules (business_id, module_id, enabled)
  VALUES (p_business_id, v_module_id, p_enabled)
  ON CONFLICT (business_id, module_id)
  DO UPDATE SET enabled = EXCLUDED.enabled, updated_at = now();
END;
$$;
