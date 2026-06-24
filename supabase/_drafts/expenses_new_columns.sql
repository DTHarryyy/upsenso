-- =============================================================================
-- DRAFT FOR REVIEW — NOT APPLIED. In supabase/_drafts/ (outside `supabase db
-- push`). To apply after approval: move into supabase/migrations/ with a fresh
-- timestamp and run with explicit go-ahead.
-- =============================================================================
-- Expenses data-model completeness (Audit: Missing Business Requirements).
-- Adds receipt, tax, payment tracking, approval timestamp, supplier link, and
-- soft-delete. ALL columns are nullable or defaulted, so this is additive and
-- backward-compatible:
--   • The remote DS reads specific keys in upsertFromServer (extra columns are
--     ignored) and writes a fixed map in upsertExpense (new columns take
--     defaults), so EXISTING app builds keep working after this is applied.
--   • The Drift side + UI that POPULATE these columns is separate follow-up work
--     (schema bump in ExpensesTable + upsert mapping + forms). This migration is
--     safe to apply before that lands; the columns simply stay null/default.
--
-- MONEY-TYPE NOTE: tax_amount mirrors the existing expenses.amount column type.
-- The whole money model is float today; converting to minor-units/numeric is a
-- deferred PLATFORM-WIDE effort — tax_amount must move together with amount then,
-- not separately. >>> VERIFY the actual type of expenses.amount and match it:
--   SELECT data_type FROM information_schema.columns
--   WHERE table_schema='public' AND table_name='expenses' AND column_name='amount';
-- (Draft assumes double precision; adjust the tax_amount type below if it differs.)
--
-- ROLLBACK:
--   ALTER TABLE public.expenses
--     DROP COLUMN IF EXISTS receipt_url,
--     DROP COLUMN IF EXISTS tax_amount,
--     DROP COLUMN IF EXISTS payment_status,
--     DROP COLUMN IF EXISTS payment_method,
--     DROP COLUMN IF EXISTS paid_at,
--     DROP COLUMN IF EXISTS due_date,
--     DROP COLUMN IF EXISTS approved_at,
--     DROP COLUMN IF EXISTS supplier_id,
--     DROP COLUMN IF EXISTS deleted_at;
--   -- (also DROP the FK/index from the optional block if it was enabled)
-- =============================================================================

ALTER TABLE public.expenses
  ADD COLUMN IF NOT EXISTS receipt_url    text,
  ADD COLUMN IF NOT EXISTS tax_amount     double precision NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS payment_status text NOT NULL DEFAULT 'unpaid',
  ADD COLUMN IF NOT EXISTS payment_method text,
  ADD COLUMN IF NOT EXISTS paid_at        timestamptz,
  ADD COLUMN IF NOT EXISTS due_date       timestamptz,
  ADD COLUMN IF NOT EXISTS approved_at    timestamptz,
  ADD COLUMN IF NOT EXISTS supplier_id    uuid,
  ADD COLUMN IF NOT EXISTS deleted_at     timestamptz;

-- Constrain payment_status to known values. Existing rows default to 'unpaid',
-- which satisfies the check (whether a past approved expense was actually paid
-- is unknowable, so 'unpaid' is the safe starting point — a business marks paid).
ALTER TABLE public.expenses
  DROP CONSTRAINT IF EXISTS expenses_payment_status_check;
ALTER TABLE public.expenses
  ADD CONSTRAINT expenses_payment_status_check
  CHECK (payment_status IN ('unpaid', 'paid'));

-- Backfill approved_at for rows already approved (best-effort: use updated_at,
-- the closest available timestamp; approval moment wasn't recorded before).
UPDATE public.expenses
   SET approved_at = updated_at
 WHERE status = 'approved' AND approved_at IS NULL;

-- ── OPTIONAL: link supplier_id to the suppliers table ────────────────────────
-- Enable only after confirming the suppliers PK column (assumed id uuid):
--   SELECT column_name, data_type FROM information_schema.columns
--   WHERE table_schema='public' AND table_name='suppliers' AND column_name='id';
-- Then uncomment:
--
-- ALTER TABLE public.expenses
--   ADD CONSTRAINT expenses_supplier_id_fkey
--   FOREIGN KEY (supplier_id) REFERENCES public.suppliers(id) ON DELETE SET NULL;
-- CREATE INDEX IF NOT EXISTS idx_expenses_supplier ON public.expenses(supplier_id);

-- PostgREST schema reload.
SELECT pg_notify('pgrst', 'reload schema');
