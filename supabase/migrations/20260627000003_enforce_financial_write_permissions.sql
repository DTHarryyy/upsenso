-- =============================================================================
-- Phase 1 — server-side permission enforcement for financial writes.
--
-- WHY
--   transactions, refunds and shifts had RLS that only checked tenant +
--   has_branch_access() — any authenticated member could create a sale, issue a
--   refund or open a shift via the REST API regardless of their role, since the
--   only real gate was client-side. CLAUDE.md requires financial actions to be
--   server-enforced.
--
-- APPROACH (low blast radius)
--   Add RESTRICTIVE per-command policies that AND-in has_permission() on top of
--   the existing permissive FOR ALL policies. The existing tenant/branch policies
--   are left untouched, so the read path and tenant isolation are unchanged. A
--   RESTRICTIVE policy only narrows access; if any of these is wrong the fix is a
--   single DROP POLICY (see rollback) with zero impact on current behaviour.
--
--   has_permission() already honours owner bypass + per-employee overrides
--   (20260627000002), so owners and override-granted staff pass. Verified under
--   the authenticated role: owner→all allow, cashier→pos.use/refund/open allow &
--   void deny, no-perm principal→all deny.
--
-- SCOPE
--   • transactions INSERT  → pos.use        (creating a sale)
--   • transactions UPDATE  → pos.void_sale  (only when setting status='voided';
--                            refund status flips and re-syncs of completed sales
--                            are unaffected)
--   • refunds INSERT       → pos.refund_sale
--   • shifts INSERT        → pos.open_shift  (no client write path today;
--                            future-proofing — harmless)
--
-- DEFERRED (needs client-guard confirmation first to avoid blocking live sales)
--   • Order-level discount gate (pos.apply_discount on transactions.discount_amount)
--     — the discount sheet applies a discount without a visible business-logic
--     guard; gating it server-side could reject legitimate discounted sales.
--   • transaction_items / payments are gated through their parent transaction.
--
-- ROLLBACK
--   DROP POLICY transactions_perm_insert ON public.transactions;
--   DROP POLICY transactions_perm_void   ON public.transactions;
--   DROP POLICY refunds_perm_insert      ON public.refunds;
--   DROP POLICY shifts_perm_open         ON public.shifts;
-- =============================================================================

-- Creating a sale requires pos.use.
DROP POLICY IF EXISTS transactions_perm_insert ON public.transactions;
CREATE POLICY transactions_perm_insert ON public.transactions
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (has_permission('pos.use'));

-- Voiding a sale (status -> 'voided') requires pos.void_sale. Any other status
-- (completed re-sync, refund flip to 'refunded') is unaffected.
DROP POLICY IF EXISTS transactions_perm_void ON public.transactions;
CREATE POLICY transactions_perm_void ON public.transactions
  AS RESTRICTIVE FOR UPDATE TO authenticated
  WITH CHECK (status IS DISTINCT FROM 'voided' OR has_permission('pos.void_sale'));

-- Issuing a refund requires pos.refund_sale.
DROP POLICY IF EXISTS refunds_perm_insert ON public.refunds;
CREATE POLICY refunds_perm_insert ON public.refunds
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (has_permission('pos.refund_sale'));

-- Opening a shift requires pos.open_shift.
DROP POLICY IF EXISTS shifts_perm_open ON public.shifts;
CREATE POLICY shifts_perm_open ON public.shifts
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (has_permission('pos.open_shift'));
