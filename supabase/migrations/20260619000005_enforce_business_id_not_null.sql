-- stock_ledger.business_id and product_variants.business_id were nullable,
-- but RLS predicates business_id = get_my_business_id() — a NULL value would
-- make a row invisible/unwritable and silently break tenant accounting/sync.
-- Verified before apply: zero existing NULL rows in either table; the local
-- Drift schema already declares both columns non-nullable, so the app never
-- sends a NULL here anyway.
-- Rollback:
--   alter table public.stock_ledger alter column business_id drop not null;
--   alter table public.product_variants alter column business_id drop not null;

alter table public.stock_ledger alter column business_id set not null;
alter table public.product_variants alter column business_id set not null;
