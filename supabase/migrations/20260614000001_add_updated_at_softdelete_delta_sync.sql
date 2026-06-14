-- =============================================================================
-- Delta-sync enablement: updated_at (trigger-maintained) + soft-delete columns
-- =============================================================================
-- Adds the columns the app needs to extend incremental (delta) sync from
-- stock_ledger (already append-only) to the MUTABLE tables. See
-- docs/delta_sync_design.md.
--
-- Tables: products, product_variants, inventory_levels, transactions.
--
-- This migration is ADDITIVE and IDEMPOTENT (safe to run more than once). It
-- does NOT change app behaviour by itself — the Flutter delta-pull for these
-- tables is wired up separately AFTER this lands.
--
-- Per CLAUDE.md "Database & Migration Safety" — pre-change checklist:
--   • Schema impact : adds `updated_at timestamptz NOT NULL DEFAULT now()`,
--                     `deleted_at timestamptz`, a BEFORE UPDATE trigger, and a
--                     (business_id, updated_at) index to each table. No column
--                     is renamed or dropped.
--   • Offline impact: none. Drift's local schema is unchanged; these columns
--                     are server-side only until the app opts in to reading
--                     them. Existing pulls keep working.
--   • Sync impact   : after this runs, existing rows get updated_at = now() once,
--                     so the FIRST delta pull per table re-pulls everything once,
--                     then only changed rows thereafter. `deleted_at` lets future
--                     server-side soft-deletes propagate to offline devices
--                     (today the app still hard-deletes; converting those is
--                     follow-up app work).
--   • Existing data : preserved. NOT NULL is satisfied by DEFAULT now() for
--                     existing rows. `deleted_at` defaults to NULL (= not deleted).
--   • Rollback      : see the ROLLBACK block at the bottom (run manually).
--
-- NOTE: not applied by Claude. Review, then run `supabase db push` yourself.
-- =============================================================================

-- ── Shared trigger function ──────────────────────────────────────────────────
-- `set_updated_at()` already exists in this project (used by the permission and
-- business_modules triggers). Recreate the canonical body so this migration is
-- self-contained and safe on a fresh environment; the behaviour is identical.
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;
ALTER FUNCTION public.set_updated_at() SET search_path = public;

-- ── products ─────────────────────────────────────────────────────────────────
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

DROP TRIGGER IF EXISTS trg_products_updated_at ON public.products;
CREATE TRIGGER trg_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_products_business_updated
  ON public.products (business_id, updated_at);

-- ── product_variants ─────────────────────────────────────────────────────────
ALTER TABLE public.product_variants
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

DROP TRIGGER IF EXISTS trg_product_variants_updated_at ON public.product_variants;
CREATE TRIGGER trg_product_variants_updated_at
  BEFORE UPDATE ON public.product_variants
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_product_variants_business_updated
  ON public.product_variants (business_id, updated_at);

-- ── inventory_levels ─────────────────────────────────────────────────────────
ALTER TABLE public.inventory_levels
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

DROP TRIGGER IF EXISTS trg_inventory_levels_updated_at ON public.inventory_levels;
CREATE TRIGGER trg_inventory_levels_updated_at
  BEFORE UPDATE ON public.inventory_levels
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_inventory_levels_business_updated
  ON public.inventory_levels (business_id, updated_at);

-- ── transactions ─────────────────────────────────────────────────────────────
ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

DROP TRIGGER IF EXISTS trg_transactions_updated_at ON public.transactions;
CREATE TRIGGER trg_transactions_updated_at
  BEFORE UPDATE ON public.transactions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE INDEX IF NOT EXISTS idx_transactions_business_updated
  ON public.transactions (business_id, updated_at);

-- ── PostgREST schema reload ───────────────────────────────────────────────────
SELECT pg_notify('pgrst', 'reload schema');

-- =============================================================================
-- ROLLBACK (run manually only if you need to revert — drops the added objects)
-- =============================================================================
-- DROP TRIGGER IF EXISTS trg_products_updated_at         ON public.products;
-- DROP TRIGGER IF EXISTS trg_product_variants_updated_at ON public.product_variants;
-- DROP TRIGGER IF EXISTS trg_inventory_levels_updated_at ON public.inventory_levels;
-- DROP TRIGGER IF EXISTS trg_transactions_updated_at     ON public.transactions;
--
-- DROP INDEX IF EXISTS idx_products_business_updated;
-- DROP INDEX IF EXISTS idx_product_variants_business_updated;
-- DROP INDEX IF EXISTS idx_inventory_levels_business_updated;
-- DROP INDEX IF EXISTS idx_transactions_business_updated;
--
-- ALTER TABLE public.products          DROP COLUMN IF EXISTS updated_at, DROP COLUMN IF EXISTS deleted_at;
-- ALTER TABLE public.product_variants  DROP COLUMN IF EXISTS updated_at, DROP COLUMN IF EXISTS deleted_at;
-- ALTER TABLE public.inventory_levels  DROP COLUMN IF EXISTS updated_at, DROP COLUMN IF EXISTS deleted_at;
-- ALTER TABLE public.transactions      DROP COLUMN IF EXISTS updated_at, DROP COLUMN IF EXISTS deleted_at;
-- (set_updated_at() is shared with other triggers — do NOT drop it.)
