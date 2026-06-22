-- =============================================================================
-- Purchase Order number system — production-ready sequential numbers
-- =============================================================================
-- Mirrors the invoice number system (20260616000001). Adds:
--   1. po_number_sequences      — atomic per-business counter (one row per month)
--   2. claim_po_number()        — SECURITY DEFINER RPC the Flutter app calls at
--      PO creation to claim the next number atomically (multi-device safe)
--
-- Format: PO-YYYYMM-NNNN  (e.g. PO-202606-0001)
--
-- Offline safety: the app falls back to a local SQLite counter when the RPC is
-- unreachable; it produces the same format. A rare offline collision is caught
-- on sync and re-claimed.
--
-- This migration is ADDITIVE and non-destructive (CREATE ... IF NOT EXISTS /
-- CREATE OR REPLACE). Existing data is untouched.
--
-- Rollback:
--   DROP FUNCTION IF EXISTS public.claim_po_number(uuid, text);
--   DROP TABLE    IF EXISTS public.po_number_sequences;
-- =============================================================================

-- ── 1. po_number_sequences ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.po_number_sequences (
  business_id  uuid  NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  month_key    text  NOT NULL,  -- 'YYYYMM', e.g. '202606'
  last_value   integer NOT NULL DEFAULT 0,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, month_key)
);

ALTER TABLE public.po_number_sequences ENABLE ROW LEVEL SECURITY;

-- Read scoped to the caller's business; the RPC writes via SECURITY DEFINER.
DROP POLICY IF EXISTS po_seq_select ON public.po_number_sequences;
CREATE POLICY po_seq_select ON public.po_number_sequences
  FOR SELECT TO authenticated
  USING (business_id = get_my_business_id());

GRANT SELECT ON public.po_number_sequences TO authenticated;

-- ── 2. claim_po_number() ──────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.claim_po_number(
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

  INSERT INTO public.po_number_sequences (business_id, month_key, last_value)
  VALUES (p_business_id, p_month_key, 1)
  ON CONFLICT (business_id, month_key)
  DO UPDATE
    SET last_value = po_number_sequences.last_value + 1,
        updated_at = now()
  RETURNING last_value INTO v_next;

  RETURN 'PO-' || p_month_key || '-' || LPAD(v_next::text, 4, '0');
END;
$$;

GRANT EXECUTE ON FUNCTION public.claim_po_number(uuid, text) TO authenticated;

-- ── PostgREST schema reload ───────────────────────────────────────────────────
SELECT pg_notify('pgrst', 'reload schema');
