-- Phase 0/1 — remove genuinely-redundant objects (dev project, no data/users).
-- inventory_movements duplicates the richer stock_ledger; sync_queue is an abandoned
-- outbox replaced by per-row sync_status. Verified: no FKs, functions, triggers, or
-- app code reference either table.
DROP TABLE IF EXISTS public.inventory_movements;
DROP TABLE IF EXISTS public.sync_queue;

-- Duplicate indexes — keep the unique/constraint-backed variant, drop the copy.
DROP INDEX IF EXISTS public.idx_receipt_settings_business;     -- identical to receipt_settings_business_id_key
DROP INDEX IF EXISTS public.idx_transactions_business_invoice; -- redundant non-unique copy of the unique-partial index
