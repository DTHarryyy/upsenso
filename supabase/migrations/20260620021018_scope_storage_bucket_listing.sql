-- Reconciliation note (2026-06-28): applied to prod on 2026-06-20 (shortly
-- after 20260620020908_security_hardening_rls_grants_storage), captured here
-- verbatim because it was missing from this repo.

-- Public buckets serve objects via getPublicUrl without any SELECT policy, so
-- avatars and product-images (read only via getPublicUrl in the app) need none.
-- Dropping their broad SELECT removes file enumeration entirely.
-- Rollback: recreate the read policy FOR SELECT TO authenticated USING (bucket_id = '<name>').
DROP POLICY IF EXISTS avatars_authenticated_read ON storage.objects;
DROP POLICY IF EXISTS product_images_authenticated_read ON storage.objects;

-- business-logos IS listed by the app (deleteLogo lists receipt-logos/<businessId>),
-- so it keeps a SELECT policy — but scoped to the caller's own business folder
-- instead of the whole bucket, so it is no longer a broad listing policy and one
-- tenant can't enumerate another's logos.
-- Object path: receipt-logos/<businessId>/<file>  -> foldername[2] = businessId.
-- Rollback: recreate USING (bucket_id = 'business-logos').
DROP POLICY IF EXISTS business_logos_authenticated_read ON storage.objects;
CREATE POLICY business_logos_read_own_business ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'business-logos'
    AND (storage.foldername(name))[2] = (get_my_business_id())::text
  );
