-- Shorten invoice numbers from INV-YYYYMM-NNNNNN (17 chars) to INV-NNNNNN
-- (10 chars). The longer format was overflowing the meta row on 58mm receipts,
-- forcing the printed number to be ellipsis-truncated — unacceptable since the
-- invoice number must always be fully readable on the receipt.
--
-- Behaviour change only: claim_invoice_number() still increments the same
-- (business_id, month_key) counter row in invoice_sequences, it just drops the
-- month segment from the returned string. The Flutter app now always passes a
-- fixed bucket key ('seq') instead of the calendar month, so each business gets
-- one continuously-rising counter instead of a counter that resets monthly.
-- Existing rows/numbers already issued under real month keys (e.g. '202606')
-- are untouched and keep working — uniqueness is per (business_id,
-- invoice_number), so the old and new formats never collide.
--
-- No table/column changes, no data migration needed.
--
-- Rollback:
--   CREATE OR REPLACE FUNCTION public.claim_invoice_number(
--     p_business_id uuid,
--     p_month_key   text
--   ) RETURNS text
--   LANGUAGE plpgsql
--   SECURITY DEFINER
--   SET search_path = public
--   AS $$
--   DECLARE
--     v_next integer;
--   BEGIN
--     IF p_business_id IS DISTINCT FROM get_my_business_id() THEN
--       RAISE EXCEPTION 'Not authorized for business %', p_business_id;
--     END IF;
--     INSERT INTO public.invoice_sequences (business_id, month_key, last_value)
--     VALUES (p_business_id, p_month_key, 1)
--     ON CONFLICT (business_id, month_key)
--     DO UPDATE
--       SET last_value = invoice_sequences.last_value + 1,
--           updated_at = now()
--     RETURNING last_value INTO v_next;
--     RETURN 'INV-' || p_month_key || '-' || LPAD(v_next::text, 6, '0');
--   END;
--   $$;

CREATE OR REPLACE FUNCTION public.claim_invoice_number(
  p_business_id uuid,
  p_month_key   text    -- fixed bucket key ('seq') from the app, not a calendar month
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

  RETURN 'INV-' || LPAD(v_next::text, 6, '0');
END;
$$;

SELECT pg_notify('pgrst', 'reload schema');
