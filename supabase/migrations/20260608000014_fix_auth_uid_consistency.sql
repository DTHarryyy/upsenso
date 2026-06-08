-- Fix auth.uid() lookups to use auth_user_id (the actual Supabase auth column)
-- instead of user_id (a custom profile ID) consistently across all policies
-- and helper functions.

-- Fix get_my_business_id() to use auth_user_id
CREATE OR REPLACE FUNCTION public.get_my_business_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT COALESCE(
    (SELECT business_id FROM public.employees WHERE auth_user_id = auth.uid() LIMIT 1),
    (SELECT id FROM public.businesses WHERE owner_id = auth.uid() LIMIT 1)
  );
$$;

-- Fix audit_logs INSERT policies to use auth_user_id
DROP POLICY IF EXISTS audit_logs_employee_insert ON public.audit_logs;
DROP POLICY IF EXISTS audit_logs_insert_system ON public.audit_logs;

CREATE POLICY audit_logs_employee_insert ON public.audit_logs
  FOR INSERT TO authenticated
  WITH CHECK (
    business_id IN (
      SELECT business_id FROM public.employees WHERE auth_user_id = auth.uid()
      UNION
      SELECT id FROM public.businesses WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY audit_logs_insert_system ON public.audit_logs
  FOR INSERT TO public
  WITH CHECK (
    business_id IN (
      SELECT business_id FROM public.employees WHERE auth_user_id = auth.uid()
      UNION
      SELECT id FROM public.businesses WHERE owner_id = auth.uid()
    )
  );
