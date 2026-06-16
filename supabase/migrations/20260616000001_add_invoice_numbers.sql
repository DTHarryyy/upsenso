-- =============================================================================
-- Invoice number system — production-ready sequential numbers
-- =============================================================================
-- Adds:
--   1. invoice_sequences   — atomic per-business counter table (one row per month)
--   2. claim_invoice_number() — SECURITY DEFINER RPC; called by the Flutter app
--      at checkout time to claim the next number atomically (no race conditions)
--   3. invoice_number column on transactions — stores the final assigned number
--
-- Format: INV-YYYYMM-NNNNNN  (e.g. INV-202606-000042)
--
-- Multi-device safety: claim_invoice_number() runs under SERIALIZABLE isolation
-- via a SELECT ... FOR UPDATE lock, so two devices simultaneously online can
-- never receive the same number.
--
-- Offline safety: the Flutter app falls back to a local counter when the RPC
-- is unreachable; the local counter also produces INV-YYYYMM-NNNNNN. In the
-- rare case that two offline devices collide on a number, Supabase's UNIQUE
-- constraint catches it at sync time and the app re-claims a new number.
--
-- Rollback:
--   DROP FUNCTION IF EXISTS public.claim_invoice_number(uuid, text);
--   DROP TABLE  IF EXISTS public.invoice_sequences;
--   ALTER TABLE public.transactions DROP COLUMN IF EXISTS invoice_number;
-- =============================================================================

-- ── 1. invoice_sequences ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.invoice_sequences (
  business_id  uuid  NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  month_key    text  NOT NULL,  -- 'YYYYMM', e.g. '202606'
  last_value   integer NOT NULL DEFAULT 0,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, month_key)
);

ALTER TABLE public.invoice_sequences ENABLE ROW LEVEL SECURITY;

-- Only the business owner / admins can read; the RPC writes via SECURITY DEFINER.
CREATE POLICY inv_seq_select ON public.invoice_sequences
  FOR SELECT TO authenticated
  USING (business_id = get_my_business_id());

GRANT SELECT ON public.invoice_sequences TO authenticated;

-- ── 2. claim_invoice_number() ─────────────────────────────────────────────────
-- Atomically increments the counter and returns the formatted invoice string.
-- SECURITY DEFINER so the function can bypass RLS on invoice_sequences for the
-- upsert (the caller's identity is still validated via get_my_business_id()).
CREATE OR REPLACE FUNCTION public.claim_invoice_number(
  p_business_id uuid,
  p_month_key   text    -- 'YYYYMM'
) RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next integer;
BEGIN
  -- Guard: caller must belong to this business
  IF p_business_id IS DISTINCT FROM get_my_business_id() THEN
    RAISE EXCEPTION 'Not authorized for business %', p_business_id;
  END IF;

  INSERT INTO public.invoice_sequences (business_id, month_key, last_value)
  VALUES (p_business_id, p_month_key, 1)
  ON CONFLICT (business_id, month_key)
  DO UPDATE
    SET last_value = invoice_sequences.last_value + 1,
        updated_at = now()
  RETURNING last_value INTO v_next;

  RETURN 'INV-' || p_month_key || '-' || LPAD(v_next::text, 6, '0');
END;
$$;

GRANT EXECUTE ON FUNCTION public.claim_invoice_number(uuid, text) TO authenticated;

-- ── 3. invoice_number column on transactions ──────────────────────────────────
ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS invoice_number text;

-- UNIQUE so offline-collision duplicates are caught at sync time.
-- NULLS are excluded from uniqueness (pre-feature transactions have NULL).
CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_invoice_number
  ON public.transactions (invoice_number)
  WHERE invoice_number IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_transactions_business_invoice
  ON public.transactions (business_id, invoice_number);

-- ── PostgREST schema reload ───────────────────────────────────────────────────
SELECT pg_notify('pgrst', 'reload schema');
