-- =============================================================================
-- Align Supabase schema with Flutter app data model
-- =============================================================================
-- Every upsert the Flutter app sends was audited against the Supabase tables.
-- This migration adds every missing column so sync stops failing.
-- Existing columns are never renamed or dropped — only additions are made.
-- =============================================================================

-- ── products ─────────────────────────────────────────────────────────────────
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS sku         text,
  ADD COLUMN IF NOT EXISTS barcode     text,
  ADD COLUMN IF NOT EXISTS tax         numeric      DEFAULT 0,
  ADD COLUMN IF NOT EXISTS sell_by     text         DEFAULT 'unit',
  ADD COLUMN IF NOT EXISTS has_variants boolean     DEFAULT false,
  ADD COLUMN IF NOT EXISTS image_path  text;

-- ── product_variants ─────────────────────────────────────────────────────────
ALTER TABLE public.product_variants
  ADD COLUMN IF NOT EXISTS business_id   uuid        REFERENCES public.businesses(id),
  ADD COLUMN IF NOT EXISTS name          text        DEFAULT 'Default',
  ADD COLUMN IF NOT EXISTS cost_price    numeric     DEFAULT 0,
  ADD COLUMN IF NOT EXISTS retail_price  numeric     DEFAULT 0,
  ADD COLUMN IF NOT EXISTS stock         integer     DEFAULT 0,
  ADD COLUMN IF NOT EXISTS barcode       text,
  ADD COLUMN IF NOT EXISTS stock_decimal numeric,
  ADD COLUMN IF NOT EXISTS low_stock_alert integer,
  ADD COLUMN IF NOT EXISTS track_stock   boolean     DEFAULT false,
  ADD COLUMN IF NOT EXISTS track_expiry  boolean     DEFAULT false,
  ADD COLUMN IF NOT EXISTS expiry_date   bigint,
  ADD COLUMN IF NOT EXISTS is_active     boolean     DEFAULT true;

-- ── expenses ─────────────────────────────────────────────────────────────────
-- The app uses a flat denormalised model (category/vendor as text, submitted_by
-- as id+name pair) rather than FKs to expense_categories/employees.
ALTER TABLE public.expenses
  ADD COLUMN IF NOT EXISTS branch_name       text,
  ADD COLUMN IF NOT EXISTS category          text,
  ADD COLUMN IF NOT EXISTS vendor            text,
  ADD COLUMN IF NOT EXISTS submitted_by_id   text,
  ADD COLUMN IF NOT EXISTS submitted_by_name text,
  ADD COLUMN IF NOT EXISTS approved_by_id    text,
  ADD COLUMN IF NOT EXISTS approved_by_name  text,
  ADD COLUMN IF NOT EXISTS note              text,
  ADD COLUMN IF NOT EXISTS expense_date      timestamptz,
  ADD COLUMN IF NOT EXISTS updated_at        timestamptz DEFAULT now();

-- ── audit_logs ───────────────────────────────────────────────────────────────
ALTER TABLE public.audit_logs
  ADD COLUMN IF NOT EXISTS branch_id   uuid,
  ADD COLUMN IF NOT EXISTS user_id     text,
  ADD COLUMN IF NOT EXISTS description text,
  ADD COLUMN IF NOT EXISTS device_id   text;

-- ── transactions ─────────────────────────────────────────────────────────────
-- App uses cashier_id/total_amount/discount_amount/tax_amount/status.
-- Supabase had employee_id/total — keep both so neither path breaks.
ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS cashier_id       text,
  ADD COLUMN IF NOT EXISTS total_amount     numeric,
  ADD COLUMN IF NOT EXISTS discount_amount  numeric     DEFAULT 0,
  ADD COLUMN IF NOT EXISTS tax_amount       numeric     DEFAULT 0,
  ADD COLUMN IF NOT EXISTS status           text        DEFAULT 'completed';

-- ── transaction_items ────────────────────────────────────────────────────────
-- App sends variant_id (text alias), product_name, variant_name, unit_price,
-- tax_rate, line_total, line_tax.
-- Supabase had product_variant_id (UUID FK) — keep it, add variant_id as text.
ALTER TABLE public.transaction_items
  ADD COLUMN IF NOT EXISTS variant_id   text,
  ADD COLUMN IF NOT EXISTS product_name  text,
  ADD COLUMN IF NOT EXISTS variant_name  text,
  ADD COLUMN IF NOT EXISTS unit_price    numeric,
  ADD COLUMN IF NOT EXISTS tax_rate      numeric     DEFAULT 0,
  ADD COLUMN IF NOT EXISTS line_total    numeric,
  ADD COLUMN IF NOT EXISTS line_tax      numeric     DEFAULT 0;

-- ── inventory_levels ─────────────────────────────────────────────────────────
-- App uses variant_id (text), quantity_decimal, low_stock_alert_override.
-- Supabase had product_variant_id (UUID FK) — keep it, add variant_id as text.
ALTER TABLE public.inventory_levels
  ADD COLUMN IF NOT EXISTS variant_id              text,
  ADD COLUMN IF NOT EXISTS quantity_decimal        numeric     DEFAULT 0,
  ADD COLUMN IF NOT EXISTS low_stock_alert_override integer;

-- ── stock_ledger ─────────────────────────────────────────────────────────────
-- New table — not in original schema. The app's stock ledger lives in Drift
-- locally and syncs here. Separate from inventory_movements (which is used
-- by the RBAC/permission system, not the POS logic).
CREATE TABLE IF NOT EXISTS public.stock_ledger (
  id              text          NOT NULL,
  variant_id      text          NOT NULL,
  product_id      text          NOT NULL,
  branch_id       text          NOT NULL,
  business_id     uuid          REFERENCES public.businesses(id),
  change_type     text          NOT NULL,
  quantity        numeric       NOT NULL,
  quantity_before numeric,
  quantity_after  numeric,
  reason          text          NOT NULL,
  note            text,
  created_at      timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT stock_ledger_pkey PRIMARY KEY (id)
);

ALTER TABLE public.stock_ledger ENABLE ROW LEVEL SECURITY;

CREATE POLICY stock_ledger_biz_isolation ON public.stock_ledger
  FOR ALL TO authenticated
  USING (business_id = get_my_business_id())
  WITH CHECK (business_id = get_my_business_id());

-- ── GRANTs (ensure authenticated role can read/write all app tables) ─────────
GRANT SELECT, INSERT, UPDATE, DELETE ON public.products          TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.product_variants  TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.expenses          TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.transactions      TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.transaction_items TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.inventory_levels  TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.stock_ledger      TO authenticated;
GRANT SELECT, INSERT, UPDATE         ON public.audit_logs        TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.branches          TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.categories        TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.units             TO authenticated;
GRANT SELECT, INSERT, UPDATE         ON public.receipt_settings  TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.suppliers         TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.expense_categories TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.shifts            TO authenticated;

-- ── Indexes for new columns used in queries ───────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_product_variants_business
  ON public.product_variants (business_id);

CREATE INDEX IF NOT EXISTS idx_inventory_levels_variant
  ON public.inventory_levels (variant_id);

CREATE INDEX IF NOT EXISTS idx_transaction_items_variant
  ON public.transaction_items (variant_id);

CREATE INDEX IF NOT EXISTS idx_stock_ledger_variant
  ON public.stock_ledger (variant_id, branch_id);

CREATE INDEX IF NOT EXISTS idx_stock_ledger_business
  ON public.stock_ledger (business_id, created_at DESC);

-- ── PostgREST schema reload ───────────────────────────────────────────────────
SELECT pg_notify('pgrst', 'reload schema');
