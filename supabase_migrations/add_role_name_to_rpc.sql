-- Update get_my_business_context RPC to include role and branch info.
-- Run this in your Supabase SQL Editor

-- Drop the existing function first (required when changing return type)
DROP FUNCTION IF EXISTS public.get_my_business_context();

-- Recreate with a privileged execution context and owner fallback.
CREATE OR REPLACE FUNCTION public.get_my_business_context()
RETURNS TABLE (
  business_id UUID,
  business_name TEXT,
  role_id UUID,
  role_name TEXT,
  full_name TEXT,
  branch_id UUID,
  branch_name TEXT
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Primary path: read context from users row (best for multi-user businesses).
  BEGIN
    RETURN QUERY
    SELECT 
      u.business_id,
      b.name AS business_name,
      u.role_id,
      r.name AS role_name,
      u.full_name,
      COALESCE(br_user.id, br_fallback.id) AS branch_id,
      COALESCE(br_user.name, br_fallback.name) AS branch_name
    FROM public.users u
    LEFT JOIN public.businesses b ON b.id = u.business_id
    LEFT JOIN public.roles r ON r.id = u.role_id
    LEFT JOIN public.branches br_user ON br_user.id = u.branch_id
    LEFT JOIN LATERAL (
      SELECT br.id, br.name
      FROM public.branches br
      WHERE br.business_id = u.business_id
        AND br.is_active = true
      ORDER BY br.id
      LIMIT 1
    ) br_fallback ON true
    WHERE u.id = auth.uid()
    LIMIT 1;

    IF FOUND THEN
      RETURN;
    END IF;
  EXCEPTION
    WHEN insufficient_privilege THEN
      -- Fall back to owner-based context if users table is restricted.
      NULL;
  END;

  -- Fallback path: derive context from owned business without users table.
  RETURN QUERY
  SELECT
    b.id AS business_id,
    b.name AS business_name,
    r.id AS role_id,
    r.name AS role_name,
    COALESCE(
      auth.jwt() -> 'user_metadata' ->> 'full_name',
      split_part(COALESCE(auth.jwt() ->> 'email', ''), '@', 1)
    ) AS full_name,
    br.id AS branch_id,
    br.name AS branch_name
  FROM public.businesses b
  LEFT JOIN public.roles r
    ON r.business_id = b.id
   AND r.name = 'Super Admin'
  LEFT JOIN LATERAL (
    SELECT br.id, br.name
    FROM public.branches br
    WHERE br.business_id = b.id
      AND br.is_active = true
    ORDER BY br.id
    LIMIT 1
  ) br ON true
  WHERE b.owner_id = auth.uid()
  LIMIT 1;
END;
$$;

ALTER FUNCTION public.get_my_business_context() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.get_my_business_context() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_business_context() TO authenticated;
