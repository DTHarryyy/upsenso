-- Phase 3 (expenses) — Option B: commit to the denormalized snapshot model the app
-- actually uses. The server's normalized FK half (expense_category_id, employee_id,
-- approved_by) was never populated by the client, and expense_categories was unused.
-- Verified: 0 rows in expense_categories; no FK/function/trigger/app-code references.
-- branch_id stays as the one real uuid FK (already FK -> branches).
ALTER TABLE public.expenses
  DROP COLUMN IF EXISTS expense_category_id,
  DROP COLUMN IF EXISTS employee_id,
  DROP COLUMN IF EXISTS approved_by;

DROP TABLE IF EXISTS public.expense_categories;
