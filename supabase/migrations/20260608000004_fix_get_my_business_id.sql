-- =============================================================================
-- Fix get_my_business_id() — add businesses.owner_id as fallback
-- =============================================================================
-- The original function only checks the employees table. Business owners who
-- are not in the employees table always got NULL, blocking all RLS policies
-- that use this function (including bm_read on business_modules).
--
-- The fix adds a COALESCE fallback to businesses.owner_id so owners can
-- always read and write their own business data.
-- =============================================================================

CREATE OR REPLACE FUNCTION get_my_business_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT business_id FROM employees WHERE user_id = auth.uid() LIMIT 1),
    (SELECT id FROM businesses WHERE owner_id = auth.uid() LIMIT 1)
  );
$$;

SELECT pg_notify('pgrst', 'reload schema');
