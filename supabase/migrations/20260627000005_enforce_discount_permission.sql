-- =============================================================================
-- Enforce pos.apply_discount on the server (completes the financial phase).
--
-- Pairs with the client guard added at the discount entry points (the discount
-- sheet open in pos_terminal_page and the authoritative checkout build in
-- checkout_payment_page) so a discounted sale can only be created by a user with
-- pos.apply_discount. This supersedes the Phase 1 transactions_perm_insert
-- (20260627000003) by AND-ing a column-conditioned discount check onto it:
-- a sale with discount_amount = 0 is unaffected; a discounted sale also needs
-- pos.apply_discount.
--
-- Safe to apply now: the only active non-owner employee already holds
-- apply_discount and owners bypass, so no in-flight sale is rejected.
--
-- ROLLBACK: recreate transactions_perm_insert with only has_permission('pos.use')
-- (the 20260627000003 definition).
-- =============================================================================

DROP POLICY IF EXISTS transactions_perm_insert ON public.transactions;
CREATE POLICY transactions_perm_insert ON public.transactions
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (
    has_permission('pos.use')
    AND (COALESCE(discount_amount, 0) = 0 OR has_permission('pos.apply_discount'))
  );
