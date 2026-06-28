-- Normalize the transactions / transaction_items tables by removing legacy
-- duplicate columns that are NULL on every row (confirmed 0 populated):
--   transactions.total            -> superseded by total_amount
--   transactions.transaction_number, receipt_number -> superseded by invoice_number
--   transactions.employee_id      -> unused FK; cashier_id (text) is canonical
--   transaction_items.product_variant_id -> superseded by variant_id (text)
--   transaction_items.price       -> superseded by unit_price
--
-- Reconciliation note (2026-06-28): applied to prod on 2026-06-20, captured
-- here verbatim because it was missing from this repo.
--
-- Rollback (all columns were empty, so no data is lost):
--   ALTER TABLE public.transactions ADD COLUMN total numeric;
--   ALTER TABLE public.transactions ADD COLUMN transaction_number text;
--   ALTER TABLE public.transactions ADD COLUMN receipt_number text;
--   ALTER TABLE public.transactions ADD COLUMN employee_id uuid
--     REFERENCES public.employees(id);
--   ALTER TABLE public.transaction_items ADD COLUMN product_variant_id uuid;
--   ALTER TABLE public.transaction_items ADD COLUMN price numeric;

-- Defensive guard: abort the whole migration if any column gained data between
-- verification and apply, so we never drop a column that is now in use.
DO $$
DECLARE
  n bigint;
BEGIN
  SELECT count(total) + count(transaction_number) + count(receipt_number)
       + count(employee_id) INTO n FROM public.transactions;
  IF n > 0 THEN
    RAISE EXCEPTION 'Aborting: transactions legacy columns hold % value(s)', n;
  END IF;
  SELECT count(product_variant_id) + count(price) INTO n
    FROM public.transaction_items;
  IF n > 0 THEN
    RAISE EXCEPTION 'Aborting: transaction_items legacy columns hold % value(s)', n;
  END IF;
END $$;

ALTER TABLE public.transactions
  DROP COLUMN IF EXISTS total,
  DROP COLUMN IF EXISTS transaction_number,
  DROP COLUMN IF EXISTS receipt_number,
  DROP COLUMN IF EXISTS employee_id;

ALTER TABLE public.transaction_items
  DROP COLUMN IF EXISTS product_variant_id,
  DROP COLUMN IF EXISTS price;
