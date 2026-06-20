-- Phase 6 (cleanup) — drop dead expenses columns (verified all-null and
-- unreferenced by code/functions) and add covering indexes for two unindexed
-- foreign keys that join in catalog/employee listings.
ALTER TABLE public.expenses
  DROP COLUMN IF EXISTS description,
  DROP COLUMN IF EXISTS approved_at,
  DROP COLUMN IF EXISTS receipt_url;

CREATE INDEX IF NOT EXISTS idx_employees_role ON public.employees(role_id);
CREATE INDEX IF NOT EXISTS idx_products_unit ON public.products(unit_id);
