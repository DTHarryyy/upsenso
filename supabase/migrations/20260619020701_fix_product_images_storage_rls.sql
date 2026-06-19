-- The product-images bucket only had a public SELECT policy on storage.objects.
-- Uploads from ImageService.uploadLocalImageToStorage() were silently rejected
-- by RLS, so product sync kept failing whenever a local image needed pushing.
-- Scope writes to the caller's own business folder (same pattern as the
-- products table RLS) so businesses can never write into another tenant's
-- image folder, even if a client tampers with the local business_id.

create policy product_images_insert_own_business
on storage.objects for insert to authenticated
with check (
  bucket_id = 'product-images'
  and (storage.foldername(name))[1] = public.get_my_business_id()::text
);

create policy product_images_update_own_business
on storage.objects for update to authenticated
using (
  bucket_id = 'product-images'
  and (storage.foldername(name))[1] = public.get_my_business_id()::text
)
with check (
  bucket_id = 'product-images'
  and (storage.foldername(name))[1] = public.get_my_business_id()::text
);
