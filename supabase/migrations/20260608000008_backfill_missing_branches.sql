-- =============================================================================
-- Backfill a "Main" branch for every business that has no branch yet.
-- =============================================================================
-- Root cause: before migration 4 (fix_get_my_business_id), the RLS policy on
-- branches blocked branch creation during setup because get_my_business_id()
-- returned NULL for the new owner. Businesses created in that window exist in
-- Supabase but have zero rows in the branches table. Without a branch, the
-- Flutter app shows an empty state and employees cannot be assigned.
-- =============================================================================

INSERT INTO public.branches (id, business_id, name, location)
SELECT
  gen_random_uuid() AS id,
  b.id              AS business_id,
  'Main'            AS name,
  NULL              AS location
FROM public.businesses b
WHERE NOT EXISTS (
  SELECT 1 FROM public.branches br WHERE br.business_id = b.id
);

SELECT pg_notify('pgrst', 'reload schema');
