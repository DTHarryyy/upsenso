-- =============================================================================
-- Stage 1c — employee_branches RLS de-dup (APPLIED via connector 2026-07-04)
--
-- Verified first: all 7 policies were PERMISSIVE. The delete/select pairs are
-- logically identical (IN-subquery vs correlated EXISTS, same tenant condition),
-- and eb_insert is strictly subsumed by employee_branches_insert (which adds the
-- `OR businesses.owner_id = auth.uid()` clause). Since permissive policies are
-- OR'd, removing the redundant/subsumed ones is a ZERO access change (7 -> 4).
--
-- NOTE: recipe_lines / products / stock_ledger / etc. were NOT touched — their
-- "extra" policies are the intended layering: PERMISSIVE tenant-scope AND'd with
-- RESTRICTIVE has_permission() checks. That is correct, not duplication.
--
-- ROLLBACK (recreate the dropped policies):
--   CREATE POLICY employee_branches_delete ON public.employee_branches FOR DELETE TO authenticated
--     USING (EXISTS (SELECT 1 FROM employees e WHERE e.id = employee_branches.employee_id AND e.business_id = my_business_id()));
--   CREATE POLICY employee_branches_select ON public.employee_branches FOR SELECT TO authenticated
--     USING (EXISTS (SELECT 1 FROM employees e WHERE e.id = employee_branches.employee_id AND e.business_id = my_business_id()));
--   CREATE POLICY eb_insert ON public.employee_branches FOR INSERT TO authenticated
--     WITH CHECK (employee_id IN (SELECT id FROM employees WHERE business_id = my_business_id()));
-- =============================================================================

DROP POLICY IF EXISTS employee_branches_delete ON public.employee_branches;  -- keep eb_delete (equivalent)
DROP POLICY IF EXISTS employee_branches_select ON public.employee_branches;  -- keep eb_select (equivalent)
DROP POLICY IF EXISTS eb_insert ON public.employee_branches;                 -- keep employee_branches_insert (broader)
-- Result: eb_delete, employee_branches_insert, eb_select, eb_update (one per command).
