-- =============================================================================
-- Stage 1 structural hardening — DROP dead duplicate column (2026-07-04)
--
-- inventory_levels.variant_id (text) is a rename-era duplicate of
-- product_variant_id (uuid), which owns the FK to product_variants and the
-- UNIQUE(branch_id, product_variant_id). Evidence: 0/3 populated in the pre-reset
-- data (backups/reset-20260704), and the client never writes it:
--   • push  — products_remote_ds.dart upserts 'product_variant_id' only,
--             onConflict 'product_variant_id,branch_id'
--   • pull  — inventory_levels_dao.dart upsertFromServer reads
--             row['product_variant_id'] ?? row['variant_id']; after the drop the
--             absent key is null-coalesced away (product_variant_id is always set)
-- SERVER-ONLY: the local Drift table keeps its own `variantId` text key — that is
-- a different (local composite-key) column and is unaffected.
--
-- ROLLBACK: ALTER TABLE public.inventory_levels ADD COLUMN variant_id text;
-- =============================================================================

ALTER TABLE public.inventory_levels DROP COLUMN IF EXISTS variant_id;
