-- LWW conflict resolution was keyed on `updated_at`, but a BEFORE UPDATE
-- trigger (set_updated_at) unconditionally stamps that column with SERVER
-- receipt time, not the device's edit time. So "last write wins" was
-- actually "last device to SYNC wins" — a device that edited first but
-- synced later could silently overwrite a newer edit from another device.
--
-- client_updated_at carries the device's local edit timestamp untouched by
-- any trigger. Pushes use it with a conditional filter (only apply if the
-- stored value isn't already newer) so a stale push becomes a no-op instead
-- of clobbering a newer edit. NULL means "no client timestamp yet" — existing
-- rows keep today's behavior (always overwritable) until next edited.
-- Rollback:
--   alter table public.products drop column if exists client_updated_at;
--   alter table public.product_variants drop column if exists client_updated_at;
--   alter table public.inventory_levels drop column if exists client_updated_at;

alter table public.products add column if not exists client_updated_at timestamptz;
alter table public.product_variants add column if not exists client_updated_at timestamptz;
alter table public.inventory_levels add column if not exists client_updated_at timestamptz;
