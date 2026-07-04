-- Phase 3 — Empty the 3 storage buckets (buckets + policies stay).
-- Removes the object registry rows. NOTE: this clears what the app sees; if you
-- also want the physical bytes gone from the storage backend, use the dashboard
-- "Empty bucket" or the Storage API (service_role). Residual bytes here are ~1.7 MB.
DELETE FROM storage.objects
WHERE bucket_id IN ('avatars','business-logos','product-images');
