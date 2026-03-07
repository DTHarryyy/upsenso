-- =====================================================
-- RPC FIX: secure user-business context fetch
-- This bypasses direct table read issues (42501) while still scoping to caller
-- =====================================================

DROP FUNCTION IF EXISTS public.get_my_business_context();

CREATE OR REPLACE FUNCTION public.get_my_business_context()
RETURNS TABLE (
  user_id uuid,
  business_id uuid,
  role_id uuid,
  business_name text,
  full_name text,
  email text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT
    u.id AS user_id,
    u.business_id,
    u.role_id,
    b.name AS business_name,
    u.full_name,
    u.email
  FROM public.users u
  LEFT JOIN public.businesses b ON b.id = u.business_id
  WHERE
    u.id = auth.uid()
    OR u.email = COALESCE(auth.jwt() ->> 'email', '')
  ORDER BY u.id
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.get_my_business_context() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_business_context() TO authenticated;

NOTIFY pgrst, 'reload schema';

-- =====================================================
-- Verify function exists
-- =====================================================
SELECT
  n.nspname AS schema_name,
  p.proname AS function_name,
  p.prosecdef AS security_definer
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname = 'get_my_business_context';
