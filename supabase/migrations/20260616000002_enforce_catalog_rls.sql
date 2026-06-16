-- UPSENSO — Enforce tenant isolation RLS on catalog tables
--
-- Gap found during the cross-account data-leak fix: products, product_variants
-- and categories had GRANTs to `authenticated` but no business-isolation RLS
-- policy in this migrations folder. Without RLS, an authenticated session could
-- read another business's catalog. This mirrors the existing
-- `stock_ledger_biz_isolation` pattern (business_id = get_my_business_id()).
--
-- Idempotent: ENABLE RLS is a no-op if already on; policies are dropped by name
-- then recreated. NOTE: if a pre-existing, differently-named permissive policy
-- exists on any of these tables, it is NOT removed here — review live policies
-- and drop any over-permissive ones after applying this migration.

-- ── products ─────────────────────────────────────────────────────────────────
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS products_biz_isolation ON public.products;
CREATE POLICY products_biz_isolation ON public.products
  FOR ALL TO authenticated
  USING (business_id = get_my_business_id())
  WITH CHECK (business_id = get_my_business_id());

-- ── product_variants ─────────────────────────────────────────────────────────
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS product_variants_biz_isolation ON public.product_variants;
CREATE POLICY product_variants_biz_isolation ON public.product_variants
  FOR ALL TO authenticated
  USING (business_id = get_my_business_id())
  WITH CHECK (business_id = get_my_business_id());

-- ── categories ───────────────────────────────────────────────────────────────
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS categories_biz_isolation ON public.categories;
CREATE POLICY categories_biz_isolation ON public.categories
  FOR ALL TO authenticated
  USING (business_id = get_my_business_id())
  WITH CHECK (business_id = get_my_business_id());

-- ── Rollback (manual) ────────────────────────────────────────────────────────
-- DROP POLICY IF EXISTS products_biz_isolation         ON public.products;
-- DROP POLICY IF EXISTS product_variants_biz_isolation ON public.product_variants;
-- DROP POLICY IF EXISTS categories_biz_isolation       ON public.categories;
-- -- Only disable RLS if it was previously OFF on these tables:
-- ALTER TABLE public.products         DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.product_variants DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.categories       DISABLE ROW LEVEL SECURITY;
