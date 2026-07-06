-- =============================================================================
-- UPSENSO — Normalize barcodes (product_barcodes) + product_variants.unit
-- =============================================================================
-- Enforces MULTIPLE barcodes per variant by moving codes out of the single
-- `product_variants.barcode` text column (which could only comma-join, breaking
-- exact-match scan resolution) into a first-class, tenant-scoped, offline-first
-- `product_barcodes` table (1-to-many with variants; a code is unique per
-- business). Also adds `product_variants.unit` so weighed units (kg/g/L/ml)
-- round-trip across devices (they were local-only before this).
--
-- RLS mirrors product_variants writes:
--   • SELECT — tenant-scoped (so every role can sync/scan).
--   • INSERT — tenant AND has_permission('products.create').
--   • UPDATE — tenant AND has_permission('products.edit')  (soft-delete rides UPDATE).
--   • No DELETE — soft-delete only (is_deleted / deleted_at).
--
-- Additive + non-destructive. `product_variants.barcode` is LEFT IN PLACE
-- (backfilled into product_barcodes, no longer written by the app); a later
-- migration drops it once the normalized table is proven in prod.
--
-- ROLLBACK:
--   DROP TABLE IF EXISTS public.product_barcodes;   -- (drops its policies + trigger)
--   ALTER TABLE public.product_variants DROP COLUMN IF EXISTS unit;
-- =============================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. product_barcodes table
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.product_barcodes (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  variant_id  uuid        NOT NULL REFERENCES public.product_variants(id) ON DELETE CASCADE,
  code        text        NOT NULL,
  is_primary  boolean     NOT NULL DEFAULT false,
  -- Soft-delete so removals propagate to other devices via the delta-pull.
  is_deleted  boolean     NOT NULL DEFAULT false,
  deleted_at  timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_product_barcodes_business
  ON public.product_barcodes(business_id);
CREATE INDEX IF NOT EXISTS idx_product_barcodes_variant
  ON public.product_barcodes(variant_id);

-- A live code is unique per business (a scan must resolve to exactly one
-- variant). Partial so a soft-deleted code can be reused later.
CREATE UNIQUE INDEX IF NOT EXISTS uq_product_barcodes_business_code
  ON public.product_barcodes(business_id, code)
  WHERE is_deleted = false;

-- updated_at maintenance (function already exists app-wide).
DROP TRIGGER IF EXISTS trg_product_barcodes_updated_at ON public.product_barcodes;
CREATE TRIGGER trg_product_barcodes_updated_at
  BEFORE UPDATE ON public.product_barcodes
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Grants + RLS
-- ─────────────────────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE ON public.product_barcodes TO authenticated;

ALTER TABLE public.product_barcodes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS product_barcodes_select ON public.product_barcodes;
CREATE POLICY product_barcodes_select ON public.product_barcodes
  FOR SELECT TO authenticated
  USING (business_id = get_my_business_id());

DROP POLICY IF EXISTS product_barcodes_insert ON public.product_barcodes;
CREATE POLICY product_barcodes_insert ON public.product_barcodes
  FOR INSERT TO authenticated
  WITH CHECK (business_id = get_my_business_id() AND has_permission('products.create'));

DROP POLICY IF EXISTS product_barcodes_update ON public.product_barcodes;
CREATE POLICY product_barcodes_update ON public.product_barcodes
  FOR UPDATE TO authenticated
  USING      (business_id = get_my_business_id() AND has_permission('products.edit'))
  WITH CHECK (business_id = get_my_business_id() AND has_permission('products.edit'));

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Backfill existing barcodes (idempotent) — split comma-joined values.
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO public.product_barcodes
  (id, business_id, variant_id, code, is_primary, created_at, updated_at)
SELECT gen_random_uuid(), v.business_id, v.id, trim(t.code_val), (t.ord = 1),
       now(), now()
FROM public.product_variants v
CROSS JOIN LATERAL
  unnest(string_to_array(v.barcode, ',')) WITH ORDINALITY AS t(code_val, ord)
WHERE v.barcode IS NOT NULL
  AND trim(v.barcode) <> ''
  AND trim(t.code_val) <> ''
ON CONFLICT DO NOTHING;

-- Defensive: any product-level barcode → the product's Default variant.
INSERT INTO public.product_barcodes
  (id, business_id, variant_id, code, is_primary, created_at, updated_at)
SELECT gen_random_uuid(), p.business_id, v.id, trim(t.code_val), false, now(), now()
FROM public.products p
JOIN public.product_variants v
  ON v.product_id = p.id AND v.name = 'Default'
CROSS JOIN LATERAL
  unnest(string_to_array(p.barcode, ',')) WITH ORDINALITY AS t(code_val, ord)
WHERE p.barcode IS NOT NULL
  AND trim(p.barcode) <> ''
  AND trim(t.code_val) <> ''
ON CONFLICT DO NOTHING;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. product_variants.unit (weighed unit of measure) — offline-first sync gap.
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.product_variants
  ADD COLUMN IF NOT EXISTS unit text;

COMMIT;
