-- =============================================================================
-- Migration: Business logos storage bucket
-- =============================================================================
-- Creates the `business-logos` bucket and adds logo_url to the businesses table.
--
-- Path convention: {business_id}/logo.{ext}
-- RLS mirrors the product-images pattern — public read, per-business write.
-- =============================================================================


-- =============================================================================
-- SECTION 1 · Add logo_url column to businesses
-- =============================================================================

ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS logo_url text;


-- =============================================================================
-- SECTION 2 · Bucket definition
-- =============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'business-logos',
  'business-logos',
  true,
  5242880,   -- 5 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- SECTION 3 · RLS policies
-- =============================================================================

DROP POLICY IF EXISTS "business_logos_select_public"   ON storage.objects;
DROP POLICY IF EXISTS "business_logos_insert_own"      ON storage.objects;
DROP POLICY IF EXISTS "business_logos_update_own"      ON storage.objects;
DROP POLICY IF EXISTS "business_logos_delete_own"      ON storage.objects;

-- Anyone can read business logos (receipts, customer displays, PDF reports)
CREATE POLICY "business_logos_select_public" ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'business-logos');

-- Only authenticated members of the business can upload into their folder
CREATE POLICY "business_logos_insert_own" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'business-logos'
    AND (storage.foldername(name))[1] = public.my_business_id()::text
  );

CREATE POLICY "business_logos_update_own" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'business-logos'
    AND (storage.foldername(name))[1] = public.my_business_id()::text
  )
  WITH CHECK (
    bucket_id = 'business-logos'
    AND (storage.foldername(name))[1] = public.my_business_id()::text
  );

CREATE POLICY "business_logos_delete_own" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'business-logos'
    AND (storage.foldername(name))[1] = public.my_business_id()::text
  );
