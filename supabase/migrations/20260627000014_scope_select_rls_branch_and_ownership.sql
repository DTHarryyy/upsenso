-- Phase 3 — server-side read scoping for sales/refund/expense data.
-- WHY: SELECT on transactions/refunds/expenses was gated only by tenant +
--   has_branch_access() (branches the employee is explicitly assigned to).
--   Two gaps: (1) employees granted data.cross_branch_access / reports.view_all
--   in the permission matrix had no server-side way to actually see rows
--   outside their assigned branches — the permission existed in the app layer
--   but RLS never widened for it; (2) Cashiers (pos.view_own_sales only, no
--   pos.view_all_sales) could read every sale/refund in their branch via the
--   REST API directly, not just their own, even though the app UI only shows
--   their own — hidden UI is not access control (CLAUDE.md).
-- APPROACH (low blast radius): existing FOR ALL / permissive policies on
--   transactions, refunds and expenses are left completely untouched (some
--   are FOR ALL with no separate WITH CHECK, so editing USING risks changing
--   write behavior too — see 20260627000003/20260627000009 for why this
--   codebase always bolts new policies on instead of editing existing ones).
--   Two new SELECT policies are added per table:
--     * a PERMISSIVE FOR SELECT that widens access for cross-branch
--       permission holders (OR'd onto the existing permissive set)
--     * a RESTRICTIVE FOR SELECT that narrows to own-row-only for actors who
--       hold neither the cross-branch nor the view-all-sales permission
--       (AND'd on top of the permissive set)
--   transaction_items, transaction_payments and refund_items need no direct
--   changes: their existing policies gate via an EXISTS/IN subquery against
--   transactions/refunds, and Postgres applies a table's own RLS to every
--   reference to that table — including inside another table's policy
--   expression — so they transitively inherit the new transactions/refunds
--   scoping for free. (This is the same mechanism that already makes
--   transaction_items_biz_isolation respect has_branch_access() today without
--   repeating that check itself.)
-- SCOPE: transactions, refunds SELECT — widen via can_read_all_branches(),
--   narrow via pos.view_all_sales / own cashier_id|refunded_by (both store
--   auth.uid() as text — traced through AppUserModel.id <- Supabase User.id
--   <- every write site: app_router.dart, hold_sale_action.dart,
--   refund_sheet.dart). expenses SELECT — widen only; no own-row narrowing,
--   since no expenses.view_own/view_all permission pair exists and CLAUDE.md
--   doesn't call for cashier-level expense scoping.
--   Also fixes a latent, currently-dormant bug in my_branch_ids() (joined on
--   employees.user_id instead of employees.auth_user_id, the convention every
--   other helper uses) — confirmed via pg_policies to be called by zero
--   existing policies today, so this is a zero-behavior-change bugfix.
-- DEFERRED (tracked, not silently skipped): shifts (own-row is employee_id
--   uuid FK, not a text auth uid — different comparison shape, needs its own
--   pass); stock_ledger and inventory_levels (currently zero branch filtering
--   at all on SELECT — a bigger change with no precedent yet).
-- ROLLBACK:
--   DROP POLICY IF EXISTS transactions_select_cross_branch ON public.transactions;
--   DROP POLICY IF EXISTS transactions_select_own_only ON public.transactions;
--   DROP POLICY IF EXISTS refunds_select_cross_branch ON public.refunds;
--   DROP POLICY IF EXISTS refunds_select_own_only ON public.refunds;
--   DROP POLICY IF EXISTS expenses_select_cross_branch ON public.expenses;
--   DROP FUNCTION IF EXISTS public.can_read_all_branches();
--   (my_branch_ids fix is a pure bugfix with no live callers — no rollback
--   needed, but the prior definition used e.user_id instead of e.auth_user_id
--   if it ever must be restored.)

-- ── Bugfix: my_branch_ids() must match every other helper's auth_user_id
-- convention (employees has both user_id and auth_user_id columns; every
-- other helper — has_branch_access, has_permission — keys off auth_user_id).
-- Verified unused by any existing policy (pg_policies), so this changes no
-- live behavior today.
CREATE OR REPLACE FUNCTION public.my_branch_ids()
 RETURNS SETOF uuid
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  select branch_id
  from employee_branches eb
  join employees e on e.id = eb.employee_id
  where e.auth_user_id = auth.uid();
$function$;

-- ── New helper: true for owners, super admins, and anyone explicitly granted
-- cross-branch or view-all reporting access.
CREATE OR REPLACE FUNCTION public.can_read_all_branches()
 RETURNS boolean
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  SELECT public.i_am_super_admin()
      OR public.has_permission('data.cross_branch_access')
      OR public.has_permission('reports.view_all');
$function$;

-- ── transactions ────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS transactions_select_cross_branch ON public.transactions;
CREATE POLICY transactions_select_cross_branch ON public.transactions
  AS PERMISSIVE FOR SELECT TO authenticated
  USING (business_id = get_my_business_id() AND can_read_all_branches());

DROP POLICY IF EXISTS transactions_select_own_only ON public.transactions;
CREATE POLICY transactions_select_own_only ON public.transactions
  AS RESTRICTIVE FOR SELECT TO authenticated
  USING (
    can_read_all_branches()
    OR has_permission('pos.view_all_sales')
    OR cashier_id = auth.uid()::text
  );

-- ── refunds ─────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS refunds_select_cross_branch ON public.refunds;
CREATE POLICY refunds_select_cross_branch ON public.refunds
  AS PERMISSIVE FOR SELECT TO authenticated
  USING (business_id = get_my_business_id() AND can_read_all_branches());

DROP POLICY IF EXISTS refunds_select_own_only ON public.refunds;
CREATE POLICY refunds_select_own_only ON public.refunds
  AS RESTRICTIVE FOR SELECT TO authenticated
  USING (
    can_read_all_branches()
    OR has_permission('pos.view_all_sales')
    OR refunded_by = auth.uid()::text
  );

-- ── expenses ────────────────────────────────────────────────────────────────
-- Widen only — no own-row narrowing (no expenses.view_own/view_all permission
-- pair exists, and CLAUDE.md doesn't call for cashier-level expense scoping).

DROP POLICY IF EXISTS expenses_select_cross_branch ON public.expenses;
CREATE POLICY expenses_select_cross_branch ON public.expenses
  AS PERMISSIVE FOR SELECT TO authenticated
  USING (business_id = get_my_business_id() AND can_read_all_branches());
