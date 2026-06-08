-- =============================================================================
-- Fix inventory_levels push: composite text ID → (variant_id, branch_id) conflict
-- =============================================================================
-- The Flutter app stores inventory rows locally with a composite text PK of the
-- form "$variantId:$branchId".  On push it was sending that string as the value
-- for the 'id' column, which is uuid in Supabase → "invalid input syntax for
-- type uuid" (code 22P02).
--
-- Fix: add a UNIQUE constraint on (variant_id, branch_id) so the upsert can
-- conflict on those two columns instead of 'id'.  The app will stop sending
-- 'id' and use onConflict:'variant_id,branch_id' instead.
-- =============================================================================

-- Ensure variant_id is populated (added as text in migration 7)
-- branch_id was in the original schema (uuid type)

-- Drop old plain index on variant_id alone (superseded by the unique composite)
DROP INDEX IF EXISTS public.idx_inventory_levels_variant;

-- Add the composite unique index required for ON CONFLICT (variant_id, branch_id)
-- variant_id is text; branch_id is uuid. PostgreSQL handles mixed-type unique indexes.
-- Rows with NULL variant_id are excluded from the unique check (existing rows before
-- migration 7 may have NULL variant_id — they'll never conflict with app rows).
CREATE UNIQUE INDEX IF NOT EXISTS idx_inventory_levels_variant_branch
  ON public.inventory_levels (variant_id, branch_id)
  WHERE variant_id IS NOT NULL;

-- Reload PostgREST schema cache so it picks up the new index
SELECT pg_notify('pgrst', 'reload schema');
