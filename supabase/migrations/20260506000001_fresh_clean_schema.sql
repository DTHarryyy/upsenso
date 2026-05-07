-- =============================================================================
-- Upsenso POS — Fresh Clean Schema
-- =============================================================================
-- Run this in Supabase SQL Editor on a brand-new / wiped project.
-- It drops everything, then rebuilds from scratch with correct normalization,
-- types, constraints, RLS, indexes, and seed data.
--
-- Order:
--   0  Nuclear drop
--   1  Extensions
--   2  Utility trigger function (updated_at)
--   3  Tables  (dependency order)
--   4  Auth trigger  (auto-create users row on signup)
--   5  SECURITY DEFINER helper functions
--   6  get_my_business_context() RPC
--   7  Enable RLS
--   8  Policies
--   9  Indexes
--  10  Seed data (business_templates)
-- =============================================================================


-- =============================================================================
-- 0 · NUCLEAR DROP
-- =============================================================================

-- Triggers on auth.users first (can't CASCADE from there)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Functions
DROP FUNCTION IF EXISTS public.handle_new_auth_user()      CASCADE;
DROP FUNCTION IF EXISTS public.set_updated_at()            CASCADE;
DROP FUNCTION IF EXISTS public.my_business_id()            CASCADE;
DROP FUNCTION IF EXISTS public.my_branch_id()              CASCADE;
DROP FUNCTION IF EXISTS public.i_am_super_admin()          CASCADE;
DROP FUNCTION IF EXISTS public.i_am_owner_of(uuid)         CASCADE;
DROP FUNCTION IF EXISTS public.get_my_business_context()   CASCADE;

-- Tables (reverse dependency order; CASCADE drops FKs automatically)
DROP TABLE IF EXISTS public.receipt_settings    CASCADE;
DROP TABLE IF EXISTS public.expenses            CASCADE;
DROP TABLE IF EXISTS public.transaction_items   CASCADE;
DROP TABLE IF EXISTS public.transactions        CASCADE;
DROP TABLE IF EXISTS public.stock_ledger        CASCADE;
DROP TABLE IF EXISTS public.inventory_levels    CASCADE;
DROP TABLE IF EXISTS public.product_variants    CASCADE;
DROP TABLE IF EXISTS public.products            CASCADE;
DROP TABLE IF EXISTS public.categories          CASCADE;
DROP TABLE IF EXISTS public.users               CASCADE;
DROP TABLE IF EXISTS public.branches            CASCADE;
DROP TABLE IF EXISTS public.roles               CASCADE;
DROP TABLE IF EXISTS public.businesses          CASCADE;
DROP TABLE IF EXISTS public.business_templates  CASCADE;


-- =============================================================================
-- 1 · EXTENSIONS & SCHEMA GRANTS
-- =============================================================================
-- These grants are normally set by Supabase automatically but must be
-- re-applied after any schema wipe. Without them, even correct RLS policies
-- are bypassed because the role cannot reach the table at the PostgreSQL level.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pg_trgm";    -- trigram indexes for text search

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- For objects that already exist (re-run safety)
GRANT ALL ON ALL TABLES    IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- For every object created after this point in the script
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON TABLES    TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON FUNCTIONS TO anon, authenticated, service_role;


-- =============================================================================
-- 2 · UTILITY TRIGGER FUNCTION
-- =============================================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
  RETURNS trigger LANGUAGE plpgsql AS
$$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


-- =============================================================================
-- 3 · TABLES
-- =============================================================================

-- ---------------------------------------------------------------------------
-- business_templates  — read-only catalogue; managed via dashboard / seed
-- ---------------------------------------------------------------------------
CREATE TABLE public.business_templates (
  id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name                text        NOT NULL,
  default_modules     jsonb       NOT NULL DEFAULT '{}',
  default_roles       jsonb       NOT NULL DEFAULT '[]',
  default_permissions jsonb       NOT NULL DEFAULT '{}',
  default_tax_rate    numeric(5,2),
  created_at          timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.business_templates IS 'Pre-built POS configurations. Managed by admins, read-only for tenants.';
COMMENT ON COLUMN public.business_templates.default_modules     IS 'Map of module_name → enabled (bool).';
COMMENT ON COLUMN public.business_templates.default_roles       IS 'Array of {name, permissions} objects seeded when a business is created.';
COMMENT ON COLUMN public.business_templates.default_tax_rate    IS 'Default VAT/tax % for this business type (e.g. 12.00 for PH VAT).';


-- ---------------------------------------------------------------------------
-- businesses
-- ---------------------------------------------------------------------------
CREATE TABLE public.businesses (
  id          uuid        PRIMARY KEY,
  name        text        NOT NULL,
  owner_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  template_id uuid        REFERENCES public.business_templates(id),
  is_active   boolean     NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_businesses_updated_at
  BEFORE UPDATE ON public.businesses
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ---------------------------------------------------------------------------
-- roles  — per-business RBAC definitions
-- ---------------------------------------------------------------------------
CREATE TABLE public.roles (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name        text        NOT NULL,
  permissions jsonb       NOT NULL DEFAULT '{}',
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, name)
);

COMMENT ON COLUMN public.roles.permissions IS 'Flexible JSON map; e.g. {"all":true} or {"modules":["sales","inventory"]}.';


-- ---------------------------------------------------------------------------
-- branches  — physical / logical locations inside a business
-- ---------------------------------------------------------------------------
CREATE TABLE public.branches (
  id          uuid        PRIMARY KEY,
  business_id uuid        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name        text        NOT NULL,
  address     text,
  phone       text,
  is_active   boolean     NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_branches_updated_at
  BEFORE UPDATE ON public.branches
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ---------------------------------------------------------------------------
-- users  — public profile / tenant membership
-- One row per auth.users entry; business context added after onboarding.
-- branch_id is NULL for Super Admin (no branch restriction).
-- ---------------------------------------------------------------------------
CREATE TABLE public.users (
  id          uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       text,
  full_name   text,
  avatar_url  text,
  business_id uuid        REFERENCES public.businesses(id) ON DELETE SET NULL,
  role_id     uuid        REFERENCES public.roles(id)      ON DELETE SET NULL,
  branch_id   uuid        REFERENCES public.branches(id)   ON DELETE SET NULL,
  is_active   boolean     NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON COLUMN public.users.branch_id IS 'NULL = Super Admin (unrestricted). Non-null = restricted to that branch.';

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ---------------------------------------------------------------------------
-- categories
-- ---------------------------------------------------------------------------
CREATE TABLE public.categories (
  id          uuid        PRIMARY KEY,
  business_id uuid        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name        text        NOT NULL,
  sort_order  integer     NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, name)
);


-- ---------------------------------------------------------------------------
-- products
-- ---------------------------------------------------------------------------
CREATE TABLE public.products (
  id          uuid        PRIMARY KEY,
  business_id uuid        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  category_id uuid        REFERENCES public.categories(id) ON DELETE SET NULL,
  name        text        NOT NULL,
  sku         text,
  barcode     text,
  tax         numeric(5,2) NOT NULL DEFAULT 0  CHECK (tax >= 0),
  sell_by     text        NOT NULL DEFAULT 'unit' CHECK (sell_by IN ('unit','fraction')),
  has_variants boolean    NOT NULL DEFAULT false,
  image_path  text,
  is_active   boolean     NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ---------------------------------------------------------------------------
-- product_variants
-- Intentionally denormalized: business_id mirrors products.business_id
-- so RLS policies avoid an extra join on every row access.
-- ---------------------------------------------------------------------------
CREATE TABLE public.product_variants (
  id                 uuid        PRIMARY KEY,
  product_id         uuid        NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  business_id        uuid        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name               text        NOT NULL DEFAULT 'Default',
  price              numeric(15,4) NOT NULL DEFAULT 0 CHECK (price >= 0),
  cost_price         numeric(15,4) NOT NULL DEFAULT 0 CHECK (cost_price >= 0),
  retail_price       numeric(15,4) NOT NULL DEFAULT 0 CHECK (retail_price >= 0),
  stock              integer     NOT NULL DEFAULT 0,
  stock_decimal      numeric(15,4) NOT NULL DEFAULT 0,
  sku                text,
  barcode            text,
  low_stock_alert    integer     NOT NULL DEFAULT 5 CHECK (low_stock_alert >= 0),
  track_stock        boolean     NOT NULL DEFAULT true,
  track_expiry       boolean     NOT NULL DEFAULT false,
  expiry_date        bigint,            -- Unix epoch ms; NULL = no expiry
  is_active          boolean     NOT NULL DEFAULT true,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now()
);

COMMENT ON COLUMN public.product_variants.business_id  IS 'Denormalized from products for RLS efficiency.';
COMMENT ON COLUMN public.product_variants.expiry_date  IS 'Unix epoch milliseconds. NULL means no expiry tracking.';

CREATE TRIGGER trg_product_variants_updated_at
  BEFORE UPDATE ON public.product_variants
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ---------------------------------------------------------------------------
-- inventory_levels  — per-variant per-branch stock snapshot
-- id = '<variant_uuid>:<branch_uuid>' (Flutter composite key convention)
-- UNIQUE (variant_id, branch_id) enforces one row per slot.
-- ---------------------------------------------------------------------------
CREATE TABLE public.inventory_levels (
  id                     text        PRIMARY KEY,  -- '<variantId>:<branchId>'
  variant_id             uuid        NOT NULL REFERENCES public.product_variants(id) ON DELETE CASCADE,
  branch_id              uuid        NOT NULL REFERENCES public.branches(id)          ON DELETE CASCADE,
  business_id            uuid        NOT NULL REFERENCES public.businesses(id)        ON DELETE CASCADE,
  quantity               integer     NOT NULL DEFAULT 0,
  quantity_decimal       numeric(15,4) NOT NULL DEFAULT 0,
  low_stock_alert_override integer,               -- NULL = use variant default
  updated_at             timestamptz NOT NULL DEFAULT now(),
  UNIQUE (variant_id, branch_id)
);

COMMENT ON COLUMN public.inventory_levels.id IS 'Composite text key generated by Flutter: "<variant_id>:<branch_id>".';
COMMENT ON COLUMN public.inventory_levels.low_stock_alert_override IS 'Per-branch threshold. NULL falls back to product_variants.low_stock_alert.';


-- ---------------------------------------------------------------------------
-- stock_ledger  — immutable audit trail of every stock movement
-- No UPDATE / DELETE policies — append-only by design.
-- Intentional denormalizations: product_id (skip join), business_id (RLS).
-- ---------------------------------------------------------------------------
CREATE TABLE public.stock_ledger (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  variant_id      uuid        NOT NULL REFERENCES public.product_variants(id),
  product_id      uuid        NOT NULL REFERENCES public.products(id),
  branch_id       uuid        NOT NULL REFERENCES public.branches(id),
  business_id     uuid        NOT NULL REFERENCES public.businesses(id),
  change_type     text        NOT NULL CHECK (change_type IN ('IN','OUT')),
  quantity        numeric(15,4) NOT NULL CHECK (quantity > 0),  -- always positive; direction = change_type
  quantity_before numeric(15,4),
  quantity_after  numeric(15,4),
  reason          text        NOT NULL CHECK (reason IN ('Sale','Restock','Damage','Transfer','Adjustment')),
  note            text,
  created_at      timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.stock_ledger IS 'Immutable stock movement audit log. No client UPDATE/DELETE allowed.';
COMMENT ON COLUMN public.stock_ledger.quantity IS 'Always a positive value. Direction determined by change_type.';


-- ---------------------------------------------------------------------------
-- transactions  — completed POS sales
-- Immutable after creation. No UPDATE / DELETE policies.
-- cashier_id is stored as text (UUID string) for Flutter sync compatibility.
-- ---------------------------------------------------------------------------
CREATE TABLE public.transactions (
  id               uuid        PRIMARY KEY,
  business_id      uuid        REFERENCES public.businesses(id),
  branch_id        uuid        REFERENCES public.branches(id),
  cashier_id       text        NOT NULL,   -- auth.uid()::text
  total_amount     numeric(15,4) NOT NULL DEFAULT 0,
  discount_amount  numeric(15,4) NOT NULL DEFAULT 0,
  tax_amount       numeric(15,4) NOT NULL DEFAULT 0,
  status           text        NOT NULL DEFAULT 'completed',
  transaction_hash text,
  created_at       timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.transactions IS 'Immutable POS sales records. No client UPDATE/DELETE.';
COMMENT ON COLUMN public.transactions.cashier_id IS 'auth.uid() as text for Flutter sync compatibility.';


-- ---------------------------------------------------------------------------
-- transaction_items  — line items; immutable
-- product_name / variant_name are historical snapshots (products can change).
-- ---------------------------------------------------------------------------
CREATE TABLE public.transaction_items (
  id             uuid        PRIMARY KEY,
  transaction_id uuid        NOT NULL REFERENCES public.transactions(id) ON DELETE CASCADE,
  variant_id     uuid        NOT NULL REFERENCES public.product_variants(id),
  product_name   text        NOT NULL,
  variant_name   text        NOT NULL,
  unit_price     numeric(15,4) NOT NULL,
  tax_rate       numeric(5,2),
  qty            numeric(15,4) NOT NULL CHECK (qty > 0),
  line_total     numeric(15,4) NOT NULL,
  line_tax       numeric(15,4) NOT NULL DEFAULT 0
);

COMMENT ON COLUMN public.transaction_items.product_name IS 'Snapshot at sale time; intentionally denormalized.';


-- ---------------------------------------------------------------------------
-- expenses  — expense tracking with approval workflow
-- branch_name is a snapshot (branch can be renamed later).
-- submitted_by_id / approved_by_id stored as text for Flutter compatibility.
-- ---------------------------------------------------------------------------
CREATE TABLE public.expenses (
  id                 uuid        PRIMARY KEY,
  business_id        uuid        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  branch_id          uuid        REFERENCES public.branches(id) ON DELETE SET NULL,
  branch_name        text,                -- snapshot; intentional denormalization
  category           text        NOT NULL,
  vendor             text,
  amount             numeric(15,4) NOT NULL CHECK (amount >= 0),
  status             text        NOT NULL DEFAULT 'pending'
                                 CHECK (status IN ('pending','approved','rejected','draft')),
  submitted_by_id    text        NOT NULL,  -- auth.uid()::text
  submitted_by_name  text        NOT NULL,
  approved_by_id     text,
  approved_by_name   text,
  note               text,
  expense_date       date        NOT NULL,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_expenses_updated_at
  BEFORE UPDATE ON public.expenses
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ---------------------------------------------------------------------------
-- receipt_settings  — one row per business; id = business_id
-- ---------------------------------------------------------------------------
CREATE TABLE public.receipt_settings (
  id                           uuid        PRIMARY KEY,   -- = business_id
  business_id                  uuid        NOT NULL UNIQUE REFERENCES public.businesses(id) ON DELETE CASCADE,
  -- Business identity
  business_name                text,
  store_name                   text,
  owner_name                   text,
  address                      text,
  contact_number               text,
  email                        text,
  website                      text,
  tin_number                   text,
  permit_number                text,
  -- Receipt content
  header_text                  text,
  footer_text                  text,
  return_policy                text,
  custom_notes                 text,
  -- Logo
  show_logo                    boolean     NOT NULL DEFAULT false,
  logo_local_path              text,
  logo_url                     text,
  -- Display toggles
  show_qr_code                 boolean     NOT NULL DEFAULT false,
  show_tax_breakdown           boolean     NOT NULL DEFAULT false,
  show_cashier_name            boolean     NOT NULL DEFAULT true,
  show_customer_name           boolean     NOT NULL DEFAULT false,
  show_date_time               boolean     NOT NULL DEFAULT true,
  show_order_id                boolean     NOT NULL DEFAULT true,
  -- Printing
  paper_size                   text        NOT NULL DEFAULT '80mm'    CHECK (paper_size IN ('58mm','80mm')),
  font_size                    text        NOT NULL DEFAULT 'medium'  CHECK (font_size IN ('small','medium','large')),
  text_alignment               text        NOT NULL DEFAULT 'center'  CHECK (text_alignment IN ('left','center','right')),
  auto_print_after_checkout    boolean     NOT NULL DEFAULT false,
  print_duplicate_copy         boolean     NOT NULL DEFAULT false,
  thermal_printer_enabled      boolean     NOT NULL DEFAULT false,
  -- Currency & tax
  currency_symbol              text        NOT NULL DEFAULT '₱',
  tax_percentage               numeric(5,2) NOT NULL DEFAULT 0,
  service_charge_percentage    numeric(5,2) NOT NULL DEFAULT 0,
  vat_inclusive                boolean     NOT NULL DEFAULT false,
  created_at                   timestamptz NOT NULL DEFAULT now(),
  updated_at                   timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_receipt_settings_updated_at
  BEFORE UPDATE ON public.receipt_settings
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- =============================================================================
-- 4 · AUTH TRIGGER
-- =============================================================================
-- Automatically creates a public.users row whenever someone signs up.
-- The row starts with just id + email + full_name (from OAuth metadata).
-- Business context (business_id, role_id, branch_id) is filled in later
-- during the onboarding flow.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
  RETURNS trigger LANGUAGE plpgsql
  SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      split_part(COALESCE(NEW.email, ''), '@', 1)
    )
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();


-- =============================================================================
-- 5 · SECURITY DEFINER HELPER FUNCTIONS
-- =============================================================================
-- Run under the table-owner role → bypass RLS → NO infinite recursion.
-- =============================================================================

-- Current user's business_id (NULL before onboarding completes)
CREATE OR REPLACE FUNCTION public.my_business_id()
  RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER
  SET search_path = public AS
$$
  SELECT business_id FROM public.users WHERE id = auth.uid();
$$;

-- Current user's branch_id (NULL for Super Admin)
CREATE OR REPLACE FUNCTION public.my_branch_id()
  RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER
  SET search_path = public AS
$$
  SELECT branch_id FROM public.users WHERE id = auth.uid();
$$;

-- True when the current user's role name is "Super Admin"
CREATE OR REPLACE FUNCTION public.i_am_super_admin()
  RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
  SET search_path = public AS
$$
  SELECT EXISTS (
    SELECT 1
    FROM  public.users u
    JOIN  public.roles r ON r.id = u.role_id
    WHERE u.id = auth.uid()
      AND LOWER(TRIM(r.name)) = 'super admin'
  );
$$;

-- True when auth.uid() owns the given business.
-- Used during onboarding before the users row has a business_id.
CREATE OR REPLACE FUNCTION public.i_am_owner_of(p_business_id uuid)
  RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
  SET search_path = public AS
$$
  SELECT EXISTS (
    SELECT 1 FROM public.businesses
    WHERE id = p_business_id AND owner_id = auth.uid()
  );
$$;


-- =============================================================================
-- 6 · get_my_business_context() RPC
-- =============================================================================
-- One round-trip on session restore; returns everything Flutter needs.
-- SECURITY DEFINER → bypasses RLS on every joined table.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_my_business_context()
  RETURNS TABLE (
    business_id    uuid,
    business_name  text,
    role_id        uuid,
    role_name      text,
    branch_id      uuid,
    branch_name    text,
    full_name      text,
    template_id    uuid,
    template_name  text
  )
  LANGUAGE sql STABLE SECURITY DEFINER
  SET search_path = public AS
$$
  SELECT
    b.id          AS business_id,
    b.name        AS business_name,
    r.id          AS role_id,
    r.name        AS role_name,
    br.id         AS branch_id,
    br.name       AS branch_name,
    u.full_name   AS full_name,
    bt.id         AS template_id,
    bt.name       AS template_name
  FROM       public.users              u
  LEFT JOIN  public.businesses         b  ON b.id  = u.business_id
  LEFT JOIN  public.roles              r  ON r.id  = u.role_id
  LEFT JOIN  public.branches           br ON br.id = u.branch_id
  LEFT JOIN  public.business_templates bt ON bt.id = b.template_id
  WHERE u.id = auth.uid()
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_business_context() TO authenticated;


-- =============================================================================
-- 7 · ENABLE RLS
-- =============================================================================

ALTER TABLE public.business_templates  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.businesses          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branches            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variants    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_levels    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_ledger        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaction_items   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipt_settings    ENABLE ROW LEVEL SECURITY;


-- =============================================================================
-- 8 · POLICIES
-- =============================================================================

-- ── business_templates ────────────────────────────────────────────────────
-- Public read-only catalogue. Writes via service role / dashboard only.
CREATE POLICY "bt_select" ON public.business_templates
  FOR SELECT TO authenticated USING (true);


-- ── businesses ────────────────────────────────────────────────────────────
-- SELECT also allows owner_id = auth.uid() so that insert().select() works
-- during onboarding before users.business_id has been populated.
CREATE POLICY "biz_select" ON public.businesses
  FOR SELECT TO authenticated
  USING (id = public.my_business_id() OR owner_id = auth.uid());

CREATE POLICY "biz_insert" ON public.businesses
  FOR INSERT TO authenticated WITH CHECK (owner_id = auth.uid());

CREATE POLICY "biz_update" ON public.businesses
  FOR UPDATE TO authenticated
  USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());

CREATE POLICY "biz_delete" ON public.businesses
  FOR DELETE TO authenticated USING (owner_id = auth.uid());


-- ── roles ─────────────────────────────────────────────────────────────────
-- i_am_owner_of() handles the onboarding window before users row has business_id.
CREATE POLICY "roles_select" ON public.roles
  FOR SELECT TO authenticated
  USING (business_id = public.my_business_id() OR public.i_am_owner_of(business_id));

CREATE POLICY "roles_insert" ON public.roles
  FOR INSERT TO authenticated
  WITH CHECK (business_id = public.my_business_id() OR public.i_am_owner_of(business_id));

CREATE POLICY "roles_update" ON public.roles
  FOR UPDATE TO authenticated
  USING (business_id = public.my_business_id() AND public.i_am_super_admin());

CREATE POLICY "roles_delete" ON public.roles
  FOR DELETE TO authenticated
  USING (business_id = public.my_business_id() AND public.i_am_super_admin());


-- ── branches ──────────────────────────────────────────────────────────────
CREATE POLICY "branches_select" ON public.branches
  FOR SELECT TO authenticated
  USING (business_id = public.my_business_id() OR public.i_am_owner_of(business_id));

CREATE POLICY "branches_insert" ON public.branches
  FOR INSERT TO authenticated
  WITH CHECK (business_id = public.my_business_id() OR public.i_am_owner_of(business_id));

CREATE POLICY "branches_update" ON public.branches
  FOR UPDATE TO authenticated
  USING (business_id = public.my_business_id() AND public.i_am_super_admin());

CREATE POLICY "branches_delete" ON public.branches
  FOR DELETE TO authenticated
  USING (business_id = public.my_business_id() AND public.i_am_super_admin());


-- ── users ─────────────────────────────────────────────────────────────────
-- THE FIX: no policy here touches `users` directly.
-- Own-row uses auth.uid(). Cross-business uses SECURITY DEFINER my_business_id().
CREATE POLICY "users_select" ON public.users
  FOR SELECT TO authenticated
  USING (id = auth.uid() OR business_id = public.my_business_id());

-- Auth trigger handles INSERT; app may also upsert during onboarding.
CREATE POLICY "users_insert" ON public.users
  FOR INSERT TO authenticated WITH CHECK (id = auth.uid());

CREATE POLICY "users_update" ON public.users
  FOR UPDATE TO authenticated
  USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- DELETE: service role only (no policy → impossible from client)


-- ── categories ────────────────────────────────────────────────────────────
CREATE POLICY "cat_select" ON public.categories
  FOR SELECT TO authenticated USING (business_id = public.my_business_id());
CREATE POLICY "cat_insert" ON public.categories
  FOR INSERT TO authenticated WITH CHECK (business_id = public.my_business_id());
CREATE POLICY "cat_update" ON public.categories
  FOR UPDATE TO authenticated USING (business_id = public.my_business_id());
CREATE POLICY "cat_delete" ON public.categories
  FOR DELETE TO authenticated USING (business_id = public.my_business_id());


-- ── products ──────────────────────────────────────────────────────────────
CREATE POLICY "prod_select" ON public.products
  FOR SELECT TO authenticated USING (business_id = public.my_business_id());
CREATE POLICY "prod_insert" ON public.products
  FOR INSERT TO authenticated WITH CHECK (business_id = public.my_business_id());
CREATE POLICY "prod_update" ON public.products
  FOR UPDATE TO authenticated USING (business_id = public.my_business_id());
CREATE POLICY "prod_delete" ON public.products
  FOR DELETE TO authenticated USING (business_id = public.my_business_id());


-- ── product_variants ──────────────────────────────────────────────────────
CREATE POLICY "pv_select" ON public.product_variants
  FOR SELECT TO authenticated USING (business_id = public.my_business_id());
CREATE POLICY "pv_insert" ON public.product_variants
  FOR INSERT TO authenticated WITH CHECK (business_id = public.my_business_id());
CREATE POLICY "pv_update" ON public.product_variants
  FOR UPDATE TO authenticated USING (business_id = public.my_business_id());
CREATE POLICY "pv_delete" ON public.product_variants
  FOR DELETE TO authenticated USING (business_id = public.my_business_id());


-- ── inventory_levels ──────────────────────────────────────────────────────
-- Super Admin sees all branches; staff see only their own branch.
CREATE POLICY "inv_select" ON public.inventory_levels
  FOR SELECT TO authenticated
  USING (
    business_id = public.my_business_id()
    AND (public.i_am_super_admin() OR branch_id = public.my_branch_id())
  );
CREATE POLICY "inv_insert" ON public.inventory_levels
  FOR INSERT TO authenticated
  WITH CHECK (
    business_id = public.my_business_id()
    AND (public.i_am_super_admin() OR branch_id = public.my_branch_id())
  );
CREATE POLICY "inv_update" ON public.inventory_levels
  FOR UPDATE TO authenticated
  USING (
    business_id = public.my_business_id()
    AND (public.i_am_super_admin() OR branch_id = public.my_branch_id())
  );
CREATE POLICY "inv_delete" ON public.inventory_levels
  FOR DELETE TO authenticated
  USING (business_id = public.my_business_id() AND public.i_am_super_admin());


-- ── stock_ledger  (append-only; no UPDATE / DELETE policies) ──────────────
CREATE POLICY "ledger_select" ON public.stock_ledger
  FOR SELECT TO authenticated
  USING (
    business_id = public.my_business_id()
    AND (public.i_am_super_admin() OR branch_id = public.my_branch_id())
  );
CREATE POLICY "ledger_insert" ON public.stock_ledger
  FOR INSERT TO authenticated
  WITH CHECK (
    business_id = public.my_business_id()
    AND (public.i_am_super_admin() OR branch_id = public.my_branch_id())
  );


-- ── transactions  (append-only; no UPDATE / DELETE policies) ─────────────
CREATE POLICY "txn_select" ON public.transactions
  FOR SELECT TO authenticated
  USING (
    business_id = public.my_business_id()
    AND (public.i_am_super_admin() OR branch_id = public.my_branch_id())
  );
CREATE POLICY "txn_insert" ON public.transactions
  FOR INSERT TO authenticated
  WITH CHECK (
    business_id = public.my_business_id()
    AND (public.i_am_super_admin() OR branch_id = public.my_branch_id())
    AND cashier_id = auth.uid()::text
  );


-- ── transaction_items  (append-only; branch inherited from parent txn) ────
CREATE POLICY "txn_items_select" ON public.transaction_items
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.transactions t
      WHERE t.id = transaction_items.transaction_id
        AND t.business_id = public.my_business_id()
        AND (public.i_am_super_admin() OR t.branch_id = public.my_branch_id())
    )
  );
CREATE POLICY "txn_items_insert" ON public.transaction_items
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.transactions t
      WHERE t.id = transaction_items.transaction_id
        AND t.business_id = public.my_business_id()
    )
  );


-- ── expenses ──────────────────────────────────────────────────────────────
CREATE POLICY "exp_select" ON public.expenses
  FOR SELECT TO authenticated
  USING (
    business_id = public.my_business_id()
    AND (
      public.i_am_super_admin()
      OR branch_id = public.my_branch_id()
      OR submitted_by_id = auth.uid()::text
    )
  );
CREATE POLICY "exp_insert" ON public.expenses
  FOR INSERT TO authenticated
  WITH CHECK (
    business_id = public.my_business_id()
    AND submitted_by_id = auth.uid()::text
  );
-- Submitter can edit their own pending; Super Admin can approve/reject any
CREATE POLICY "exp_update" ON public.expenses
  FOR UPDATE TO authenticated
  USING (
    business_id = public.my_business_id()
    AND (
      public.i_am_super_admin()
      OR (submitted_by_id = auth.uid()::text AND status = 'pending')
    )
  );
CREATE POLICY "exp_delete" ON public.expenses
  FOR DELETE TO authenticated
  USING (business_id = public.my_business_id() AND public.i_am_super_admin());


-- ── receipt_settings ──────────────────────────────────────────────────────
CREATE POLICY "rs_select" ON public.receipt_settings
  FOR SELECT TO authenticated USING (business_id = public.my_business_id());
CREATE POLICY "rs_insert" ON public.receipt_settings
  FOR INSERT TO authenticated
  WITH CHECK (business_id = public.my_business_id() AND public.i_am_super_admin());
CREATE POLICY "rs_update" ON public.receipt_settings
  FOR UPDATE TO authenticated
  USING (business_id = public.my_business_id() AND public.i_am_super_admin());
CREATE POLICY "rs_delete" ON public.receipt_settings
  FOR DELETE TO authenticated
  USING (business_id = public.my_business_id() AND public.i_am_super_admin());


-- ── Storage: avatars bucket ───────────────────────────────────────────────
-- Create the bucket first: Storage → New bucket → name: avatars → Public: ON
DROP POLICY IF EXISTS "avatars_public_read"  ON storage.objects;
DROP POLICY IF EXISTS "avatars_insert_own"   ON storage.objects;
DROP POLICY IF EXISTS "avatars_update_own"   ON storage.objects;
DROP POLICY IF EXISTS "avatars_delete_own"   ON storage.objects;

CREATE POLICY "avatars_public_read" ON storage.objects
  FOR SELECT TO public USING (bucket_id = 'avatars');

CREATE POLICY "avatars_insert_own" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "avatars_update_own" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "avatars_delete_own" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);


-- =============================================================================
-- 9 · INDEXES
-- =============================================================================
-- Every RLS helper function causes a users(id) lookup; index it first.
-- Then every FK / filter column used in policies or common queries.

-- users
CREATE INDEX idx_users_business_id       ON public.users(business_id);
CREATE INDEX idx_users_branch_id         ON public.users(branch_id);
CREATE INDEX idx_users_role_id           ON public.users(role_id);

-- businesses
CREATE INDEX idx_biz_owner_id            ON public.businesses(owner_id);
CREATE INDEX idx_biz_template_id         ON public.businesses(template_id);

-- roles
CREATE INDEX idx_roles_business_id       ON public.roles(business_id);

-- branches
CREATE INDEX idx_branches_business_id    ON public.branches(business_id);

-- categories
CREATE INDEX idx_cat_business_id         ON public.categories(business_id);
CREATE INDEX idx_cat_sort                ON public.categories(business_id, sort_order);

-- products
CREATE INDEX idx_prod_business_id        ON public.products(business_id);
CREATE INDEX idx_prod_category_id        ON public.products(category_id);
CREATE INDEX idx_prod_barcode            ON public.products(barcode) WHERE barcode IS NOT NULL;
CREATE INDEX idx_prod_name_trgm          ON public.products USING gin(name gin_trgm_ops);

-- product_variants
CREATE INDEX idx_pv_product_id           ON public.product_variants(product_id);
CREATE INDEX idx_pv_business_id          ON public.product_variants(business_id);
CREATE INDEX idx_pv_barcode              ON public.product_variants(barcode) WHERE barcode IS NOT NULL;

-- inventory_levels
CREATE INDEX idx_inv_variant_id          ON public.inventory_levels(variant_id);
CREATE INDEX idx_inv_branch_id           ON public.inventory_levels(branch_id);
CREATE INDEX idx_inv_business_id         ON public.inventory_levels(business_id);

-- stock_ledger
CREATE INDEX idx_ledger_variant_id       ON public.stock_ledger(variant_id);
CREATE INDEX idx_ledger_branch_id        ON public.stock_ledger(branch_id);
CREATE INDEX idx_ledger_business_id      ON public.stock_ledger(business_id);
CREATE INDEX idx_ledger_created_at       ON public.stock_ledger(created_at DESC);
CREATE INDEX idx_ledger_reason           ON public.stock_ledger(reason);

-- transactions
CREATE INDEX idx_txn_business_id         ON public.transactions(business_id);
CREATE INDEX idx_txn_branch_id           ON public.transactions(branch_id);
CREATE INDEX idx_txn_cashier_id          ON public.transactions(cashier_id);
CREATE INDEX idx_txn_created_at          ON public.transactions(created_at DESC);

-- transaction_items
CREATE INDEX idx_ti_transaction_id       ON public.transaction_items(transaction_id);
CREATE INDEX idx_ti_variant_id           ON public.transaction_items(variant_id);

-- expenses
CREATE INDEX idx_exp_business_id         ON public.expenses(business_id);
CREATE INDEX idx_exp_branch_id           ON public.expenses(branch_id);
CREATE INDEX idx_exp_submitted_by        ON public.expenses(submitted_by_id);
CREATE INDEX idx_exp_status              ON public.expenses(status);
CREATE INDEX idx_exp_date                ON public.expenses(expense_date DESC);

-- receipt_settings
CREATE INDEX idx_rs_business_id          ON public.receipt_settings(business_id);


-- =============================================================================
-- 10 · SEED DATA — business_templates
-- =============================================================================

INSERT INTO public.business_templates
  (id, name, default_modules, default_roles, default_permissions, default_tax_rate)
VALUES

-- General Retail / Tindahan
( gen_random_uuid(), 'General Retail',
  '{"sales":true,"inventory":true,"expenses":true,"reports":true,"receipts":true,"staff":true,"ai":true}',
  '[
    {"name":"Super Admin","permissions":{"all":true}},
    {"name":"Manager","permissions":{"modules":["sales","inventory","expenses","reports","staff"]}},
    {"name":"Cashier","permissions":{"modules":["sales","receipts"]}},
    {"name":"Stock Manager","permissions":{"modules":["inventory","reports"]}}
  ]',
  '{}', 12.00 ),

-- Food & Beverage / Carinderia / Fast Food
( gen_random_uuid(), 'Food & Beverage',
  '{"sales":true,"inventory":true,"expenses":true,"reports":true,"receipts":true,"staff":true,"ai":true}',
  '[
    {"name":"Super Admin","permissions":{"all":true}},
    {"name":"Manager","permissions":{"modules":["sales","inventory","expenses","reports","staff"]}},
    {"name":"Cashier","permissions":{"modules":["sales","receipts"]}},
    {"name":"Kitchen Staff","permissions":{"modules":["inventory"]}}
  ]',
  '{}', 12.00 ),

-- Coffee Shop / Cafe
( gen_random_uuid(), 'Coffee Shop',
  '{"sales":true,"inventory":true,"expenses":true,"reports":true,"receipts":true,"staff":true,"ai":true}',
  '[
    {"name":"Super Admin","permissions":{"all":true}},
    {"name":"Manager","permissions":{"modules":["sales","inventory","expenses","reports","staff"]}},
    {"name":"Barista","permissions":{"modules":["sales","receipts"]}},
    {"name":"Stock Manager","permissions":{"modules":["inventory"]}}
  ]',
  '{}', 12.00 ),

-- Restaurant
( gen_random_uuid(), 'Restaurant',
  '{"sales":true,"inventory":true,"expenses":true,"reports":true,"receipts":true,"staff":true,"ai":true}',
  '[
    {"name":"Super Admin","permissions":{"all":true}},
    {"name":"Manager","permissions":{"modules":["sales","inventory","expenses","reports","staff"]}},
    {"name":"Cashier","permissions":{"modules":["sales","receipts"]}},
    {"name":"Waiter","permissions":{"modules":["sales"]}},
    {"name":"Kitchen Staff","permissions":{"modules":["inventory"]}}
  ]',
  '{}', 12.00 ),

-- Grocery / Supermarket
( gen_random_uuid(), 'Grocery & Supermarket',
  '{"sales":true,"inventory":true,"expenses":true,"reports":true,"receipts":true,"staff":true,"ai":true}',
  '[
    {"name":"Super Admin","permissions":{"all":true}},
    {"name":"Store Manager","permissions":{"modules":["sales","inventory","expenses","reports","staff"]}},
    {"name":"Cashier","permissions":{"modules":["sales","receipts"]}},
    {"name":"Stock Clerk","permissions":{"modules":["inventory"]}}
  ]',
  '{}', 12.00 ),

-- Pharmacy / Drugstore
( gen_random_uuid(), 'Pharmacy',
  '{"sales":true,"inventory":true,"expenses":true,"reports":true,"receipts":true,"staff":true,"ai":true}',
  '[
    {"name":"Super Admin","permissions":{"all":true}},
    {"name":"Pharmacist","permissions":{"modules":["sales","inventory","reports","receipts"]}},
    {"name":"Cashier","permissions":{"modules":["sales","receipts"]}},
    {"name":"Stock Manager","permissions":{"modules":["inventory","reports"]}}
  ]',
  '{}', 12.00 ),

-- Services (Salon, Repair Shop, etc.)
( gen_random_uuid(), 'Service Business',
  '{"sales":true,"inventory":false,"expenses":true,"reports":true,"receipts":true,"staff":true,"ai":true}',
  '[
    {"name":"Super Admin","permissions":{"all":true}},
    {"name":"Manager","permissions":{"modules":["sales","expenses","reports","staff"]}},
    {"name":"Staff","permissions":{"modules":["sales","receipts"]}}
  ]',
  '{}', 12.00 ),

-- Wholesale / Distributor
( gen_random_uuid(), 'Wholesale & Distribution',
  '{"sales":true,"inventory":true,"expenses":true,"reports":true,"receipts":true,"staff":true,"ai":true}',
  '[
    {"name":"Super Admin","permissions":{"all":true}},
    {"name":"Sales Manager","permissions":{"modules":["sales","reports","staff"]}},
    {"name":"Sales Agent","permissions":{"modules":["sales","receipts"]}},
    {"name":"Warehouse Staff","permissions":{"modules":["inventory"]}}
  ]',
  '{}', 12.00 );
                   