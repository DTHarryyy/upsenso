-- Phase 5a — additive tenant-scope + time columns on sale/refund line items.
-- Lets reporting/RLS use business_id + created_at without joining the parent.
-- Nullable for now (no broken-insert window for current clients); the client
-- write-path will populate them in the 5d sales+sync pass, after which a later
-- cleanup can SET NOT NULL. variant_id/cashier_id/refunded_by FKs are deferred
-- (data shows 3 orphan variants; cashier_id/refunded_by match no employee).
ALTER TABLE public.transaction_items
  ADD COLUMN IF NOT EXISTS business_id uuid REFERENCES public.businesses(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();
ALTER TABLE public.refund_items
  ADD COLUMN IF NOT EXISTS business_id uuid REFERENCES public.businesses(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

-- Backfill scope + time from the parent rows.
UPDATE public.transaction_items ti
  SET business_id = t.business_id, created_at = COALESCE(t.created_at, now())
  FROM public.transactions t WHERE t.id = ti.transaction_id;
UPDATE public.refund_items ri
  SET business_id = r.business_id, created_at = r.created_at
  FROM public.refunds r WHERE r.id = ri.refund_id;

CREATE INDEX IF NOT EXISTS idx_transaction_items_business_created
  ON public.transaction_items(business_id, created_at);
CREATE INDEX IF NOT EXISTS idx_refund_items_business_created
  ON public.refund_items(business_id, created_at);
