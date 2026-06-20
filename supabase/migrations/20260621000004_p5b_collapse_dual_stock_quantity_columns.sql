-- Phase 5b — collapse the dual int/decimal stock & quantity columns server-side
-- to match the client (the "fractional footgun" fix). Widen stock to numeric
-- FIRST so backfilling a fractional value from the *_decimal mirror can't
-- truncate, then drop the mirror. inventory_levels.quantity is already numeric.
ALTER TABLE public.product_variants ALTER COLUMN stock TYPE numeric USING stock::numeric;
UPDATE public.product_variants SET stock = stock_decimal
  WHERE stock_decimal IS NOT NULL AND stock_decimal <> 0;
ALTER TABLE public.product_variants DROP COLUMN stock_decimal;

UPDATE public.inventory_levels SET quantity = quantity_decimal
  WHERE quantity_decimal IS NOT NULL AND quantity_decimal <> 0;
ALTER TABLE public.inventory_levels DROP COLUMN quantity_decimal;
