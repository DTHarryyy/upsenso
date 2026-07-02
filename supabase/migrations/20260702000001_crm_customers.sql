-- =============================================================================
-- UPSENSO — M5 CRM foundation: customers table + transactions.customer_id
-- =============================================================================
-- Adds a first-class, tenant-scoped, offline-first `customers` table (the CRM
-- module `crm` is already seeded + enabled in the modules catalogue) and a
-- nullable `customer_id` FK on `transactions` so a sale can be attributed to a
-- customer for purchase history. Walk-in sales keep customer_id NULL.
--
-- RLS mirrors the suppliers pattern:
--   • SELECT — tenant-scoped only (so every role in the tenant can sync/read the
--     directory; the app-layer crm.view gate hides the UI from roles without it,
--     matching how suppliers SELECT is left tenant-only for POS/read paths).
--   • INSERT/UPDATE — tenant-scoped AND has_permission('crm.manage').
--   • No DELETE — soft-delete only (is_deleted / deleted_at), never hard-delete.
--
-- Additive + non-destructive. Existing transactions are unaffected (new column
-- defaults NULL).
--
-- ROLLBACK:
--   ALTER TABLE public.transactions DROP COLUMN IF EXISTS customer_id;
--   DROP TABLE IF EXISTS public.customers;   -- (drops its policies + trigger)
-- =============================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. customers table
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.customers (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name        text        NOT NULL,
  phone       text,
  email       text,
  address     text,
  notes       text,
  is_active   boolean     NOT NULL DEFAULT true,
  -- Soft-delete (CLAUDE.md: never hard-delete business data).
  is_deleted  boolean     NOT NULL DEFAULT false,
  deleted_at  timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now(),
  -- Offline-first delta-sync contract: updated_at on every synced entity.
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_customers_business ON public.customers(business_id);

-- updated_at maintenance (function already exists app-wide).
DROP TRIGGER IF EXISTS trg_customers_updated_at ON public.customers;
CREATE TRIGGER trg_customers_updated_at
  BEFORE UPDATE ON public.customers
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Grants + RLS
-- ─────────────────────────────────────────────────────────────────────────────
-- No DELETE grant — soft-delete only.
GRANT SELECT, INSERT, UPDATE ON public.customers TO authenticated;

ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;

-- Tenant-scoped read (matches suppliers: reads are not permission-gated at RLS
-- so sync works for the whole tenant; UI access is gated by crm.view).
DROP POLICY IF EXISTS customers_select ON public.customers;
CREATE POLICY customers_select ON public.customers
  FOR SELECT TO authenticated
  USING (business_id = get_my_business_id());

-- Writes require crm.manage AND tenant ownership.
DROP POLICY IF EXISTS customers_insert ON public.customers;
CREATE POLICY customers_insert ON public.customers
  FOR INSERT TO authenticated
  WITH CHECK (business_id = get_my_business_id() AND has_permission('crm.manage'));

DROP POLICY IF EXISTS customers_update ON public.customers;
CREATE POLICY customers_update ON public.customers
  FOR UPDATE TO authenticated
  USING      (business_id = get_my_business_id() AND has_permission('crm.manage'))
  WITH CHECK (business_id = get_my_business_id() AND has_permission('crm.manage'));

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. transactions.customer_id FK
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS customer_id uuid
    REFERENCES public.customers(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_transactions_customer
  ON public.transactions(customer_id);

COMMIT;
