-- Reconciliation note (2026-06-28): applied to prod on 2026-06-20, captured
-- here verbatim because it was missing from this repo.

-- ── 1. Remove duplicate {public}-role RLS policies ────────────────────────
-- Each table already has a stricter {authenticated} *_biz_isolation policy
-- (qual + WITH CHECK on business_id = get_my_business_id()). The {public}
-- duplicates add an anon-reachable path and have no WITH CHECK.
-- Rollback: recreate them as CREATE POLICY ... FOR ALL TO public USING (...).
DROP POLICY IF EXISTS biz_isolation_categories ON public.categories;
DROP POLICY IF EXISTS biz_isolation_products ON public.products;
DROP POLICY IF EXISTS biz_isolation_product_variants ON public.product_variants;

-- ── 2. Stop trigger functions being callable as RPCs ──────────────────────
-- These return trigger and are only ever fired by the DB; direct EXECUTE by
-- anon/authenticated is unnecessary attack surface. Triggers still fire (their
-- execution is not gated by the EXECUTE privilege).
-- Rollback: GRANT EXECUTE ON FUNCTION ... TO public.
REVOKE EXECUTE ON FUNCTION public.trg_fn_provision_business_modules() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_fn_sync_employee_role() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_fn_branch_perm_changed() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_fn_module_changed() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_fn_role_perm_changed() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_fn_user_perm_changed() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.notify_po_approvers() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.protect_owner_employee() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.log_permission_change() FROM PUBLIC, anon, authenticated;

-- ── 3. Restrict claim_invoice_number to signed-in users only ──────────────
-- It is a legitimate RPC, but only authenticated users settle sales.
-- Rollback: GRANT EXECUTE ... TO anon.
REVOKE EXECUTE ON FUNCTION public.claim_invoice_number(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.claim_invoice_number(uuid, text) TO authenticated;

-- ── 4. Stop anonymous listing of public storage buckets ───────────────────
-- Buckets stay public=true, so getPublicUrl() object reads keep working (the
-- public object endpoint bypasses RLS). Switching the broad SELECT policy from
-- {public} to {authenticated} removes anonymous enumeration of all files while
-- preserving the authenticated .list() the app uses on business-logos.
-- Rollback: recreate each policy TO public with the same USING clause.
DROP POLICY IF EXISTS avatars_public_read ON storage.objects;
CREATE POLICY avatars_authenticated_read ON storage.objects
  FOR SELECT TO authenticated USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS business_logos_select_public ON storage.objects;
CREATE POLICY business_logos_authenticated_read ON storage.objects
  FOR SELECT TO authenticated USING (bucket_id = 'business-logos');

DROP POLICY IF EXISTS product_images_select_public ON storage.objects;
CREATE POLICY product_images_authenticated_read ON storage.objects
  FOR SELECT TO authenticated USING (bucket_id = 'product-images');
