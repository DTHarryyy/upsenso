-- =============================================================================
-- Migration: Create storage buckets
-- =============================================================================
-- Creates the `avatars` and `product-images` Supabase Storage buckets.
--
-- avatars        – public read, per-user write   ({uid}/avatar.jpg)
-- product-images – public read, per-business write ({business_id}/{filename})
--
-- Avatars RLS policies live in 20260506000000_production_rls.sql (Section 19).
-- This file only adds the bucket rows + product-images policies.
-- Both INSERTs are ON CONFLICT DO NOTHING — safe to re-run.
-- =============================================================================


-- =============================================================================
-- SECTION 1 · Bucket definitions
-- =============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  (
    'avatars',
    'avatars',
    true,
    5242880,   -- 5 MB
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
  ),
  (
    'product-images',
    'product-images',
    true,
    10485760,  -- 10 MB
    ARRAY['image/jpeg', 'image/png', 'image/webp']
  )
ON CONFLICT (id) DO NOTHING;


-- =============================================================================
-- SECTION 2 · product-images RLS policies
-- =============================================================================
-- Path convention: {business_id}/{filename}
-- The first folder segment must equal the caller's business_id (from
-- public.my_business_id()), enforcing multi-tenant isolation at the storage
-- layer without any additional schema changes.

DROP POLICY IF EXISTS "product_images_select_public"   ON storage.objects;
DROP POLICY IF EXISTS "product_images_insert_business" ON storage.objects;
DROP POLICY IF EXISTS "product_images_update_business" ON storage.objects;
DROP POLICY IF EXISTS "product_images_delete_business" ON storage.objects;

-- Anyone can read product images (cashiers, receipts, customer-facing views)
CREATE POLICY "product_images_select_public" ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'product-images');

-- Only upload into your own business folder
CREATE POLICY "product_images_insert_business" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'product-images'
    AND (storage.foldername(name))[1] = public.my_business_id()::text
  );

CREATE POLICY "product_images_update_business" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'product-images'
    AND (storage.foldername(name))[1] = public.my_business_id()::text
  )
  WITH CHECK (
    bucket_id = 'product-images'
    AND (storage.foldername(name))[1] = public.my_business_id()::text
  );

CREATE POLICY "product_images_delete_business" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'product-images'
    AND (storage.foldername(name))[1] = public.my_business_id()::text
  );
