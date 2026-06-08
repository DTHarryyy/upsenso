-- =============================================================================
-- Align receipt_settings with Flutter app data model
-- =============================================================================
-- The original table had only 9 columns (id, business_id, header_text,
-- footer_text, show_logo, show_tax, paper_size, created_at, updated_at).
-- The Flutter app sends 28 columns.  All missing columns are added here.
-- Existing columns are never renamed or dropped.
-- show_tax is kept for backwards compatibility; show_tax_breakdown is added
-- as the canonical column the app reads/writes.
-- =============================================================================

ALTER TABLE public.receipt_settings

  -- Business identity
  ADD COLUMN IF NOT EXISTS business_name              text    DEFAULT '',
  ADD COLUMN IF NOT EXISTS store_name                 text    DEFAULT '',
  ADD COLUMN IF NOT EXISTS owner_name                 text    DEFAULT '',
  ADD COLUMN IF NOT EXISTS address                    text    DEFAULT '',
  ADD COLUMN IF NOT EXISTS contact_number             text    DEFAULT '',
  ADD COLUMN IF NOT EXISTS email                      text    DEFAULT '',
  ADD COLUMN IF NOT EXISTS website                    text    DEFAULT '',
  ADD COLUMN IF NOT EXISTS tin_number                 text    DEFAULT '',
  ADD COLUMN IF NOT EXISTS permit_number              text    DEFAULT '',

  -- Receipt content
  ADD COLUMN IF NOT EXISTS return_policy              text    DEFAULT '',
  ADD COLUMN IF NOT EXISTS custom_notes               text    DEFAULT '',

  -- Logo
  ADD COLUMN IF NOT EXISTS logo_url                   text    DEFAULT '',

  -- Visibility toggles
  ADD COLUMN IF NOT EXISTS show_qr_code               boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS show_tax_breakdown         boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS show_cashier_name          boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS show_customer_name         boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS show_date_time             boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS show_order_id              boolean DEFAULT true,

  -- Print preferences
  ADD COLUMN IF NOT EXISTS font_size                  text    DEFAULT 'medium',
  ADD COLUMN IF NOT EXISTS text_alignment             text    DEFAULT 'center',
  ADD COLUMN IF NOT EXISTS auto_print_after_checkout  boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS print_duplicate_copy       boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS thermal_printer_enabled    boolean DEFAULT false,

  -- Currency & tax
  ADD COLUMN IF NOT EXISTS currency_symbol            text    DEFAULT '₱',
  ADD COLUMN IF NOT EXISTS tax_percentage             numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS service_charge_percentage  numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS vat_inclusive              boolean DEFAULT true;

-- Keep existing show_tax in sync with show_tax_breakdown for any code still
-- reading the old column name.
CREATE OR REPLACE FUNCTION public.sync_receipt_show_tax()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.show_tax_breakdown IS DISTINCT FROM OLD.show_tax_breakdown THEN
    NEW.show_tax := NEW.show_tax_breakdown;
  ELSIF NEW.show_tax IS DISTINCT FROM OLD.show_tax THEN
    NEW.show_tax_breakdown := NEW.show_tax;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_receipt_show_tax ON public.receipt_settings;
CREATE TRIGGER trg_sync_receipt_show_tax
  BEFORE UPDATE ON public.receipt_settings
  FOR EACH ROW EXECUTE FUNCTION public.sync_receipt_show_tax();

-- Ensure the RLS policy on receipt_settings has an explicit WITH CHECK
-- (the old policy had NULL with_check which inherits USING — fine here,
-- but explicit is clearer and more maintainable).
DROP POLICY IF EXISTS biz_isolation_receipt_settings ON public.receipt_settings;
CREATE POLICY biz_isolation_receipt_settings ON public.receipt_settings
  FOR ALL TO authenticated
  USING    (business_id = get_my_business_id())
  WITH CHECK (business_id = get_my_business_id());

-- Ensure all required grants are present
GRANT SELECT, INSERT, UPDATE ON public.receipt_settings TO authenticated;

-- Index for the common single-row-per-business lookup
CREATE UNIQUE INDEX IF NOT EXISTS idx_receipt_settings_business
  ON public.receipt_settings (business_id);

-- PostgREST schema reload
SELECT pg_notify('pgrst', 'reload schema');
