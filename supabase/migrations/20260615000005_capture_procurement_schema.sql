-- =============================================================================
-- Capture the procurement table schema into version control.
--
-- Audit (2026-06-15): purchase_orders / purchase_order_lines exist on the remote
-- but were created OUT-OF-BAND — the referenced 20260611000002_procurement_schema
-- .sql never existed in the repo. This records the canonical definition (columns,
-- PK/FK, status CHECK, indexes, RLS enable, grants, the lines isolation policy,
-- and the updated_at triggers), reverse-engineered from the live schema.
--
-- Fully idempotent (IF NOT EXISTS / DROP …​ IF EXISTS), so on the current remote
-- it is a NO-OP — it exists to document the schema and keep the migration history
-- aligned with the repo.
--
-- NOTES / known limitations (the baseline was dashboard-created, not migrated):
--   • The permission-aware policy on purchase_orders (po_biz_isolation) is owned
--     by 20260615000003 and is intentionally NOT recreated here (so this no-op
--     migration cannot clobber it).
--   • The submit→approver notification trigger (trg_notify_po_approvers) is owned
--     by 20260615000004 and is likewise not recreated here.
--   • A clean `supabase db reset` would still require the out-of-band baseline
--     (permission catalog, apply_business_template, has_permission, businesses,
--     etc.); this migration only captures the procurement tables themselves.
-- =============================================================================

BEGIN;

-- ── purchase_orders ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.purchase_orders (
  id                text        PRIMARY KEY,
  business_id       uuid        NOT NULL REFERENCES public.businesses(id),
  branch_id         text,
  supplier_id       text,
  supplier_name     text,
  status            text        NOT NULL DEFAULT 'draft'
                      CHECK (status IN ('draft', 'submitted', 'approved',
                                        'partially_received', 'received',
                                        'cancelled')),
  po_number         text        NOT NULL,
  notes             text,
  expected_delivery timestamptz,
  total_amount      numeric     NOT NULL DEFAULT 0,
  created_by_id     text,
  created_by_name   text,
  submitted_at      timestamptz,
  approved_at       timestamptz,
  approved_by_id    text,
  approved_by_name  text,
  is_deleted        boolean     NOT NULL DEFAULT false,
  deleted_at        timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_purchase_orders_business
  ON public.purchase_orders (business_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_status
  ON public.purchase_orders (business_id, status) WHERE (is_deleted = false);

-- ── purchase_order_lines ─────────────────────────────────────────────────────
-- purchase_order_id is an UNCONSTRAINED text reference (no FK to purchase_orders)
-- by design — mirrors the offline-first decoupling used elsewhere in the schema.
CREATE TABLE IF NOT EXISTS public.purchase_order_lines (
  id                text        PRIMARY KEY,
  purchase_order_id text        NOT NULL,
  business_id       uuid        NOT NULL REFERENCES public.businesses(id),
  product_id        text        NOT NULL,
  variant_id        text        NOT NULL,
  product_name      text        NOT NULL,
  variant_name      text        NOT NULL,
  sku               text,
  quantity_ordered  numeric     NOT NULL DEFAULT 0,
  quantity_received numeric     NOT NULL DEFAULT 0,
  unit_cost         numeric     NOT NULL DEFAULT 0,
  is_deleted        boolean     NOT NULL DEFAULT false,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pol_purchase_order
  ON public.purchase_order_lines (purchase_order_id) WHERE (is_deleted = false);
CREATE INDEX IF NOT EXISTS idx_pol_business
  ON public.purchase_order_lines (business_id);

-- ── RLS + grants ─────────────────────────────────────────────────────────────
ALTER TABLE public.purchase_orders      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_order_lines ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.purchase_orders      TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.purchase_order_lines TO authenticated;

-- Lines isolation policy (business-scoped). The purchase_orders policy is the
-- permission-aware one from 20260615000003 and is not touched here.
DROP POLICY IF EXISTS po_lines_biz_isolation ON public.purchase_order_lines;
CREATE POLICY po_lines_biz_isolation ON public.purchase_order_lines
  FOR ALL TO authenticated
  USING      (business_id = my_business_id())
  WITH CHECK (business_id = my_business_id());

-- ── updated_at maintenance triggers ──────────────────────────────────────────
DROP TRIGGER IF EXISTS trg_po_updated_at ON public.purchase_orders;
CREATE TRIGGER trg_po_updated_at
  BEFORE UPDATE ON public.purchase_orders
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_pol_updated_at ON public.purchase_order_lines;
CREATE TRIGGER trg_pol_updated_at
  BEFORE UPDATE ON public.purchase_order_lines
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

COMMIT;
