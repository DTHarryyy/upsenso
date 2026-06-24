-- =============================================================================
-- Permission-aware RLS on expenses — close the direct-API bypass of the approval
-- workflow (Audit Critical #2). APPLIED to production 2026-06-23 via MCP
-- apply_migration (remote version 20260623134842).
--
-- The prior single FOR ALL policy (branch_expenses, 20260608000009) was keyed on
-- business + branch access only, so any authenticated user with branch access
-- could set status='approved'/'rejected' or DELETE rows via PostgREST, bypassing
-- the expenses.approve / expenses.delete checks the app only enforced in the UI.
--
-- Replaced with command-specific policies (SELECT / INSERT / UPDATE / DELETE).
-- Mirrors the procurement fix (20260615000003) but command-split because
-- WITH CHECK cannot gate DELETE. Status gates are targeted: each only restricts
-- when the row is in that state; unknown statuses stay scope-only (no ELSE->false
-- trap that could wedge a sync). Offline-first preserved: no RPC, the policy
-- evaluates on the normal Drift->Supabase upsert under the acting user's session.
-- has_permission() (20260623000002) grants owners every permission.
--
-- Pre-apply verification (read-only) confirmed: role grants align (create/approve
-- = Branch Manager + Business Owner, delete = Business Owner only) and there were
-- 0 expense rows, so no existing data/sync could be rejected.
--
-- ROLLBACK (restore the prior single policy):
--   DROP POLICY IF EXISTS expenses_select ON public.expenses;
--   DROP POLICY IF EXISTS expenses_insert ON public.expenses;
--   DROP POLICY IF EXISTS expenses_update ON public.expenses;
--   DROP POLICY IF EXISTS expenses_delete ON public.expenses;
--   CREATE POLICY branch_expenses ON public.expenses
--     FOR ALL TO authenticated
--     USING (business_id = get_my_business_id()
--       AND (EXISTS (SELECT 1 FROM public.businesses
--                    WHERE id = expenses.business_id AND owner_id = auth.uid())
--            OR i_am_super_admin() OR has_branch_access(branch_id)))
--     WITH CHECK (business_id = get_my_business_id()
--       AND (EXISTS (SELECT 1 FROM public.businesses
--                    WHERE id = expenses.business_id AND owner_id = auth.uid())
--            OR i_am_super_admin() OR has_branch_access(branch_id)));
-- =============================================================================

DROP POLICY IF EXISTS branch_expenses ON public.expenses;

CREATE POLICY expenses_select ON public.expenses
  FOR SELECT TO authenticated
  USING (
    business_id = get_my_business_id()
    AND (
      EXISTS (
        SELECT 1 FROM public.businesses b
        WHERE b.id = expenses.business_id AND b.owner_id = auth.uid()
      )
      OR i_am_super_admin()
      OR has_branch_access(branch_id)
    )
  );

CREATE POLICY expenses_insert ON public.expenses
  FOR INSERT TO authenticated
  WITH CHECK (
    business_id = get_my_business_id()
    AND (
      EXISTS (
        SELECT 1 FROM public.businesses b
        WHERE b.id = expenses.business_id AND b.owner_id = auth.uid()
      )
      OR i_am_super_admin()
      OR has_branch_access(branch_id)
    )
    AND has_permission('expenses.create')
    AND (
      status NOT IN ('approved', 'rejected')
      OR has_permission('expenses.approve')
    )
  );

CREATE POLICY expenses_update ON public.expenses
  FOR UPDATE TO authenticated
  USING (
    business_id = get_my_business_id()
    AND (
      EXISTS (
        SELECT 1 FROM public.businesses b
        WHERE b.id = expenses.business_id AND b.owner_id = auth.uid()
      )
      OR i_am_super_admin()
      OR has_branch_access(branch_id)
    )
  )
  WITH CHECK (
    business_id = get_my_business_id()
    AND (
      EXISTS (
        SELECT 1 FROM public.businesses b
        WHERE b.id = expenses.business_id AND b.owner_id = auth.uid()
      )
      OR i_am_super_admin()
      OR has_branch_access(branch_id)
    )
    AND (
      status NOT IN ('approved', 'rejected')
      OR has_permission('expenses.approve')
    )
  );

CREATE POLICY expenses_delete ON public.expenses
  FOR DELETE TO authenticated
  USING (
    business_id = get_my_business_id()
    AND has_permission('expenses.delete')
    AND (
      EXISTS (
        SELECT 1 FROM public.businesses b
        WHERE b.id = expenses.business_id AND b.owner_id = auth.uid()
      )
      OR i_am_super_admin()
      OR has_branch_access(branch_id)
    )
  );

SELECT pg_notify('pgrst', 'reload schema');
