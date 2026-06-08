-- Extend audit_logs INSERT policies to allow writes for businesses that
-- haven't been synced to Supabase yet (local-first scenario where business
-- sync and audit-log sync happen in the same cycle and business loses the race).

DROP POLICY IF EXISTS audit_logs_employee_insert ON public.audit_logs;
DROP POLICY IF EXISTS audit_logs_insert_system ON public.audit_logs;

CREATE POLICY audit_logs_employee_insert ON public.audit_logs
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND (
      -- user owns this business
      business_id IN (SELECT id FROM public.businesses WHERE owner_id = auth.uid())
      -- user is an employee of this business
      OR business_id IN (SELECT business_id FROM public.employees WHERE auth_user_id = auth.uid())
      -- business hasn't been pushed to Supabase yet (local-first new business)
      OR NOT EXISTS (SELECT 1 FROM public.businesses WHERE id = business_id)
    )
  );

CREATE POLICY audit_logs_insert_system ON public.audit_logs
  FOR INSERT TO public
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND (
      business_id IN (SELECT id FROM public.businesses WHERE owner_id = auth.uid())
      OR business_id IN (SELECT business_id FROM public.employees WHERE auth_user_id = auth.uid())
      OR NOT EXISTS (SELECT 1 FROM public.businesses WHERE id = business_id)
    )
  );
