-- One-time repair for existing data:
-- 1) Create a default branch for businesses that have none.
-- 2) Set users.branch_id for users missing it.
-- Run this in Supabase SQL Editor as a user with schema privileges.

-- Create default branch where none exists.
INSERT INTO public.branches (id, business_id, name, is_active)
SELECT
  gen_random_uuid(),
  b.id,
  'Main Branch',
  true
FROM public.businesses b
WHERE NOT EXISTS (
  SELECT 1
  FROM public.branches br
  WHERE br.business_id = b.id
);

-- Temporarily disable RLS on users table to allow admin backfill.
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- Fill users.branch_id with first active branch in user's business.
WITH branch_map AS (
  SELECT DISTINCT ON (business_id) id, business_id
  FROM public.branches
  WHERE is_active = true
  ORDER BY business_id, id
)
UPDATE public.users u
SET branch_id = bm.id
FROM branch_map bm
WHERE u.business_id = bm.business_id
  AND u.business_id IS NOT NULL
  AND u.branch_id IS NULL;

-- Re-enable RLS on users table.
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
