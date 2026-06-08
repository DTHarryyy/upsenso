-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: fix_employee_branches_rls
--
-- Migration _023 dropped `biz_isolation_employee_branches` (the ALL-command
-- policy) with the comment "command-specific policies already exist", but no
-- command-specific policies were ever created for this table. With RLS enabled
-- and zero policies, PostgreSQL denies every operation by default — causing the
-- sync worker to fail with:
--   "new row violates row-level security policy (USING expression)
--    for table employee_branches"
--
-- Fix: create explicit per-command policies that mirror the business-isolation
-- logic used everywhere else (employee must belong to my_business_id()).
-- ─────────────────────────────────────────────────────────────────────────────

-- SELECT — read your own business's branch assignments
CREATE POLICY eb_select ON public.employee_branches
  FOR SELECT TO authenticated
  USING (
    employee_id IN (
      SELECT id FROM public.employees
      WHERE business_id = my_business_id()
    )
  );

-- INSERT — only insert assignments for employees in your business
CREATE POLICY eb_insert ON public.employee_branches
  FOR INSERT TO authenticated
  WITH CHECK (
    employee_id IN (
      SELECT id FROM public.employees
      WHERE business_id = my_business_id()
    )
  );

-- UPDATE — only update assignments for employees in your business
CREATE POLICY eb_update ON public.employee_branches
  FOR UPDATE TO authenticated
  USING (
    employee_id IN (
      SELECT id FROM public.employees
      WHERE business_id = my_business_id()
    )
  )
  WITH CHECK (
    employee_id IN (
      SELECT id FROM public.employees
      WHERE business_id = my_business_id()
    )
  );

-- DELETE — only remove assignments for employees in your business
CREATE POLICY eb_delete ON public.employee_branches
  FOR DELETE TO authenticated
  USING (
    employee_id IN (
      SELECT id FROM public.employees
      WHERE business_id = my_business_id()
    )
  );
