-- =============================================================================
-- Purchase orders: landed-cost columns (order-level discount + shipping)
-- =============================================================================
-- total_amount = subtotal - discount + shipping. Both are distributed across
-- received units into the moving-average cost on receipt (app-side).
-- Additive/non-destructive; defaults 0 so existing POs are unaffected.
--
-- Rollback:
--   ALTER TABLE public.purchase_orders DROP COLUMN IF EXISTS discount;
--   ALTER TABLE public.purchase_orders DROP COLUMN IF EXISTS shipping;
-- =============================================================================

ALTER TABLE public.purchase_orders
  ADD COLUMN IF NOT EXISTS discount numeric NOT NULL DEFAULT 0;
ALTER TABLE public.purchase_orders
  ADD COLUMN IF NOT EXISTS shipping numeric NOT NULL DEFAULT 0;

SELECT pg_notify('pgrst', 'reload schema');
