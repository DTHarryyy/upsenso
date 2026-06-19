-- Fix cross-tenant invoice-number collisions: the unique index was global on
-- (invoice_number), but per-business counters legitimately reuse the same
-- INV-YYYYMM-NNNNNN string across tenants, turning routine sales into hard
-- sync failures. Scope uniqueness to (business_id, invoice_number).
-- Verified before apply: no existing duplicate (business_id, invoice_number).
-- Rollback:
--   drop index if exists public.idx_transactions_invoice_business;
--   create unique index idx_transactions_invoice_number
--     on public.transactions (invoice_number) where invoice_number is not null;

drop index if exists public.idx_transactions_invoice_number;
create unique index if not exists idx_transactions_invoice_business
  on public.transactions (business_id, invoice_number)
  where invoice_number is not null;
