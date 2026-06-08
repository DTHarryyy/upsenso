-- Fix audit_logs INSERT policies to allow inserts for any business the user belongs to.
-- Previously used get_my_business_id() which returns LIMIT 1 with no ORDER BY,
-- causing non-deterministic failures when a user owns multiple businesses.

DROP POLICY IF EXISTS audit_logs_employee_insert ON public.audit_logs;
DROP POLICY IF EXISTS audit_logs_insert_system ON public.audit_logs;

CREATE POLICY audit_logs_employee_insert ON public.audit_logs
  FOR INSERT TO authenticated
  WITH CHECK (
    business_id IN (
      SELECT business_id FROM public.employees WHERE user_id = auth.uid()
      UNION
      SELECT id FROM public.businesses WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY audit_logs_insert_system ON public.audit_logs
  FOR INSERT TO public
  WITH CHECK (
    business_id IN (
      SELECT business_id FROM public.employees WHERE user_id = auth.uid()
      UNION
      SELECT id FROM public.businesses WHERE owner_id = auth.uid()
    )
  );
