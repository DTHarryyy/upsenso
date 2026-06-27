-- =============================================================================
-- Enforce products.manage_prices on product_variants price changes.
--
-- RLS WITH CHECK can't compare OLD/NEW, so a BEFORE UPDATE trigger is used: a
-- change to price / cost_price / retail_price requires products.manage_prices.
-- A sale-driven sync (which re-sends the SAME price) is unaffected because the
-- values are not DISTINCT; only an actual price change trips the check. Owner
-- bypass + overrides honoured via has_permission().
--
-- Branch Manager + Business Owner hold manage_prices; Cashier + Inventory Staff
-- do not (Inventory Staff can edit a variant but not reprice it).
--
-- ROLLBACK: DROP TRIGGER trg_enforce_variant_price ON product_variants;
--           DROP FUNCTION enforce_variant_price_authority();
-- =============================================================================

CREATE OR REPLACE FUNCTION enforce_variant_price_authority()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN RETURN NEW; END IF;
  IF EXISTS (
    SELECT 1 FROM businesses b
    WHERE b.id = NEW.business_id AND b.owner_id = auth.uid()
  ) THEN
    RETURN NEW;
  END IF;
  IF (NEW.price        IS DISTINCT FROM OLD.price
   OR NEW.cost_price   IS DISTINCT FROM OLD.cost_price
   OR NEW.retail_price IS DISTINCT FROM OLD.retail_price)
   AND NOT has_permission('products.manage_prices') THEN
    RAISE EXCEPTION
      'UNAUTHORIZED: products.manage_prices permission required to change prices'
      USING errcode = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_variant_price ON public.product_variants;
CREATE TRIGGER trg_enforce_variant_price
  BEFORE UPDATE OF price, cost_price, retail_price ON public.product_variants
  FOR EACH ROW EXECUTE FUNCTION enforce_variant_price_authority();
