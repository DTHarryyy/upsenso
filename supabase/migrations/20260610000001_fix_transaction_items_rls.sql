-- =============================================================================
-- Fix: transaction_items RLS missing + transactions policy hardening
--
-- Root cause: transaction_items has RLS enabled but zero policies, so every
-- INSERT/UPDATE/SELECT from authenticated users was denied by default.
-- Also: the existing branch_transactions policy on transactions had
-- with_check = NULL (inherits USING), mirroring the same pattern that broke
-- expenses (see migration 009). Fixed here with an explicit WITH CHECK.
-- =============================================================================

BEGIN;

-- ── 1. Add RLS policy for transaction_items ───────────────────────────────────
-- transaction_items has no business_id/branch_id column — access is derived
-- through the parent transactions row. A user may read/write an item iff they
-- can already access the parent transaction (same business + branch check).
DROP POLICY IF EXISTS transaction_items_biz_isolation ON public.transaction_items;

CREATE POLICY transaction_items_biz_isolation ON public.transaction_items
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM   public.transactions t
      WHERE  t.id          = transaction_items.transaction_id
        AND  t.business_id = get_my_business_id()
        AND  has_branch_access(t.branch_id)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM   public.transactions t
      WHERE  t.id          = transaction_items.transaction_id
        AND  t.business_id = get_my_business_id()
        AND  has_branch_access(t.branch_id)
    )
  );

-- ── 2. Harden branch_transactions on transactions ────────────────────────────
-- Old policy had with_check = NULL (inherited USING), which is fragile on
-- owner accounts not in employee_branches. Replace with explicit WITH CHECK
-- that mirrors the expenses pattern: business isolation + owner OR super-admin
-- OR branch member.
DROP POLICY IF EXISTS branch_transactions ON public.transactions;

CREATE POLICY branch_transactions ON public.transactions
  FOR ALL TO authenticated
  USING (
    business_id = get_my_business_id()
    AND (
      EXISTS (
        SELECT 1 FROM public.businesses
        WHERE id = transactions.business_id AND owner_id = auth.uid()
      )
      OR i_am_super_admin()
      OR has_branch_access(branch_id)
    )
  )
  WITH CHECK (
    business_id = get_my_business_id()
    AND (
      EXISTS (
        SELECT 1 FROM public.businesses
        WHERE id = transactions.business_id AND owner_id = auth.uid()
      )
      OR i_am_super_admin()
      OR has_branch_access(branch_id)
    )
  );

-- ── 3. Ensure grants are in place ────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON public.transactions      TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.transaction_items TO authenticated;

-- ── PostgREST schema reload ───────────────────────────────────────────────────
SELECT pg_notify('pgrst', 'reload schema');

COMMIT;
