-- =============================================================================
-- Real server-side enforcement of inventory.adjust.
--
-- PROBLEM: inventory_levels.quantity is a snapshot the cashier app must write
-- (sales decrement it), so no RLS gate on that table can enforce inventory.adjust
-- without breaking sales. The fix is to make the LEDGER the only way to move
-- stock and DERIVE inventory_levels from it server-side.
--
--   1. stock_ledger gains source_type / source_id (sent by the client).
--   2. RESTRICTIVE INSERT policy gates the ledger by movement type:
--        sale / recipe_consumption -> pos.use
--        refund                    -> pos.refund_sale
--        purchase_order            -> procurement.receive
--        adjustment / initial / NULL -> inventory.adjust
--   3. AFTER INSERT trigger derives inventory_levels.quantity (+= signed delta)
--      and product_variants.stock from each new ledger row.
--   4. BEFORE trigger on inventory_levels neutralises any CLIENT-set quantity
--      (preserved server value / 0 on insert); only the derivation trigger,
--      flagged via a txn-local GUC, may set quantity. Other columns
--      (low_stock_alert_override) still pass through, so the existing level sync
--      keeps working without a client change.
--
-- Net effect: a manual stock change requires inventory.adjust (the ledger gate),
-- and a direct inventory_levels quantity write by any client is a no-op. Sales
-- (pos.use) and receipts (procurement.receive) keep working. Existing levels are
-- left as their current baseline; only NEW ledger rows apply deltas.
--
-- ROLLBACK:
--   DROP TRIGGER trg_maintain_inventory_level ON public.stock_ledger;
--   DROP TRIGGER trg_guard_inventory_quantity ON public.inventory_levels;
--   DROP FUNCTION maintain_inventory_level(); DROP FUNCTION guard_inventory_quantity();
--   DROP POLICY stock_ledger_perm_insert ON public.stock_ledger;
--   ALTER TABLE public.stock_ledger DROP COLUMN source_type, DROP COLUMN source_id;
-- =============================================================================

ALTER TABLE public.stock_ledger
  ADD COLUMN IF NOT EXISTS source_type text,
  ADD COLUMN IF NOT EXISTS source_id   text;

-- ── 1. Gate ledger inserts by movement type ─────────────────────────────────
DROP POLICY IF EXISTS stock_ledger_perm_insert ON public.stock_ledger;
CREATE POLICY stock_ledger_perm_insert ON public.stock_ledger
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (
    CASE
      WHEN source_type IN ('sale', 'recipe_consumption') THEN has_permission('pos.use')
      WHEN source_type = 'refund'                         THEN has_permission('pos.refund_sale')
      WHEN source_type = 'purchase_order'                 THEN has_permission('procurement.receive')
      ELSE has_permission('inventory.adjust')
    END
  );

-- ── 2. Guard: clients never set inventory_levels.quantity directly ──────────
CREATE OR REPLACE FUNCTION guard_inventory_quantity()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- The ledger derivation trigger flags its own writes; those are authoritative.
  IF coalesce(current_setting('app.stock_ledger_ctx', true), '') = '1' THEN
    RETURN NEW;
  END IF;
  IF TG_OP = 'INSERT' THEN
    NEW.quantity := 0;
  ELSE
    NEW.quantity := OLD.quantity;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_inventory_quantity ON public.inventory_levels;
CREATE TRIGGER trg_guard_inventory_quantity
  BEFORE INSERT OR UPDATE ON public.inventory_levels
  FOR EACH ROW EXECUTE FUNCTION guard_inventory_quantity();

-- ── 3. Derive inventory_levels + variant stock from each ledger row ─────────
CREATE OR REPLACE FUNCTION maintain_inventory_level()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_delta   numeric;
  v_variant uuid;
  v_branch  uuid;
BEGIN
  v_delta := CASE WHEN NEW.change_type = 'IN' THEN NEW.quantity ELSE -NEW.quantity END;
  BEGIN
    v_variant := NEW.variant_id::uuid;
    v_branch  := NEW.branch_id::uuid;
  EXCEPTION WHEN others THEN
    RETURN NEW;  -- non-uuid ids: skip derivation rather than fail the insert
  END;

  PERFORM set_config('app.stock_ledger_ctx', '1', true);

  INSERT INTO inventory_levels
    (id, product_variant_id, variant_id, branch_id, business_id, quantity, updated_at)
  VALUES
    (gen_random_uuid(), v_variant, NEW.variant_id, v_branch, NEW.business_id,
     GREATEST(v_delta, 0), now())
  ON CONFLICT (product_variant_id, branch_id) DO UPDATE
    SET quantity = inventory_levels.quantity + v_delta, updated_at = now();

  UPDATE product_variants pv
     SET stock = COALESCE((
       SELECT sum(il.quantity) FROM inventory_levels il
       WHERE il.product_variant_id = v_variant
     ), 0)
   WHERE pv.id = v_variant;

  PERFORM set_config('app.stock_ledger_ctx', '', true);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_maintain_inventory_level ON public.stock_ledger;
CREATE TRIGGER trg_maintain_inventory_level
  AFTER INSERT ON public.stock_ledger
  FOR EACH ROW EXECUTE FUNCTION maintain_inventory_level();
