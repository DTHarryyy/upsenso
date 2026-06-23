-- =============================================================================
-- Goods receipts (GRN) — recorded receiving events against a PO
-- =============================================================================
-- Mirrors the local Drift tables. Writes require procurement.receive; reads are
-- business-isolated. Additive/non-destructive.
--
-- Rollback:
--   DROP TABLE IF EXISTS public.goods_receipt_items;
--   DROP TABLE IF EXISTS public.goods_receipts;
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.goods_receipts (
  id                text PRIMARY KEY,
  business_id       uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  purchase_order_id text NOT NULL,
  branch_id         text NOT NULL,
  receipt_number    text NOT NULL,
  received_by_id    text,
  received_by_name  text,
  notes             text,
  is_deleted        boolean NOT NULL DEFAULT false,
  received_at       timestamptz NOT NULL DEFAULT now(),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.goods_receipt_items (
  id                     text PRIMARY KEY,
  business_id            uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  goods_receipt_id       text NOT NULL,
  purchase_order_line_id text NOT NULL,
  variant_id             text NOT NULL,
  product_id             text NOT NULL,
  product_name           text NOT NULL,
  quantity_received      numeric NOT NULL DEFAULT 0,
  unit_cost              numeric NOT NULL DEFAULT 0,
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_goods_receipts_po
  ON public.goods_receipts (purchase_order_id);
CREATE INDEX IF NOT EXISTS idx_goods_receipt_items_receipt
  ON public.goods_receipt_items (goods_receipt_id);

ALTER TABLE public.goods_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goods_receipt_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS gr_biz_isolation ON public.goods_receipts;
CREATE POLICY gr_biz_isolation ON public.goods_receipts
  FOR ALL TO authenticated
  USING (business_id = my_business_id())
  WITH CHECK (business_id = my_business_id() AND has_permission('procurement.receive'));

DROP POLICY IF EXISTS gri_biz_isolation ON public.goods_receipt_items;
CREATE POLICY gri_biz_isolation ON public.goods_receipt_items
  FOR ALL TO authenticated
  USING (business_id = my_business_id())
  WITH CHECK (business_id = my_business_id() AND has_permission('procurement.receive'));

GRANT SELECT, INSERT, UPDATE, DELETE ON public.goods_receipts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.goods_receipt_items TO authenticated;

SELECT pg_notify('pgrst', 'reload schema');
