-- =============================================================================
-- Upsenso POS — Production RLS & Security Setup
-- =============================================================================
-- Run this entire script in the Supabase SQL Editor (once).
-- It is idempotent: safe to re-run. All policies are dropped and recreated.
--
-- What this file does:
--   1. SECURITY DEFINER helper functions  →  breaks users-table recursion
--   2. get_my_business_context() RPC      →  called by Flutter on session restore
--   3. Enables RLS on all 14 tables
--   4. Drops every existing policy        →  clean slate
--   5. Recreates correct policies         →  multi-tenant + branch isolation
--   6. Storage bucket policies (avatars)
--   7. Performance indexes
-- =============================================================================


-- =============================================================================
-- SECTION 1 · SECURITY DEFINER helper functions
-- =============================================================================
-- These run under the table-owner role and therefore bypass RLS entirely.
-- That is the mechanism that breaks the infinite-recursion in the users table:
-- a policy on `users` that calls my_business_id() does NOT re-enter the policy.
-- =============================================================================

-- Returns the calling user's business_id (NULL if not yet onboarded).
CREATE OR REPLACE FUNCTION public.my_business_id()
  RETURNS uuid
  LANGUAGE sql STABLE SECURITY DEFINER
  SET search_path = public
AS $$
  SELECT business_id FROM public.users WHERE id = auth.uid();
$$;

-- Returns the calling user's branch_id (NULL for Super Admin or pre-onboarding).
CREATE OR REPLACE FUNCTION public.my_branch_id()
  RETURNS uuid
  LANGUAGE sql STABLE SECURITY DEFINER
  SET search_path = public
AS $$
  SELECT branch_id FROM public.users WHERE id = auth.uid();
$$;

-- Returns true when the current user holds the "Super Admin" role.
CREATE OR REPLACE FUNCTION public.i_am_super_admin()
  RETURNS boolean
  LANGUAGE sql STABLE SECURITY DEFINER
  SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users  u
    JOIN public.roles  r ON r.id = u.role_id
    WHERE u.id = auth.uid()
      AND LOWER(TRIM(r.name)) = 'super admin'
  );
$$;

-- Returns true when auth.uid() is the owner of the given business.
-- Used during onboarding before the public.users row exists.
CREATE OR REPLACE FUNCTION public.i_am_owner_of(p_business_id uuid)
  RETURNS boolean
  LANGUAGE sql STABLE SECURITY DEFINER
  SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.businesses
    WHERE id = p_business_id AND owner_id = auth.uid()
  );
$$;


-- =============================================================================
-- SECTION 2 · get_my_business_context() RPC
-- =============================================================================
-- Flutter calls this on every session restore instead of reading the users table
-- directly, avoiding any RLS friction and returning all context in one round-trip.
-- SECURITY DEFINER: joins across tables without touching RLS.
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
  SET search_path = public
AS $$
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
  FROM  public.users             u
  LEFT JOIN public.businesses        b  ON b.id  = u.business_id
  LEFT JOIN public.roles             r  ON r.id  = u.role_id
  LEFT JOIN public.branches          br ON br.id = u.branch_id
  LEFT JOIN public.business_templates bt ON bt.id = b.template_id
  WHERE u.id = auth.uid()
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_business_context() TO authenticated;


-- =============================================================================
-- SECTION 3 · Enable RLS on all tables
-- =============================================================================

ALTER TABLE public.users               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.businesses          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branches            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_templates  ENABLE ROW LEVEL SECURITY;
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
-- SECTION 4 · Drop every existing policy (idempotent clean slate)
-- =============================================================================

DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT schemaname, tablename, policyname
    FROM   pg_policies
    WHERE  schemaname = 'public'
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON %I.%I',
      r.policyname, r.schemaname, r.tablename
    );
  END LOOP;
END;
$$;


-- =============================================================================
-- SECTION 5 · users
-- =============================================================================
-- THE FIX: none of these policies query `users` directly.
--   • Own-row checks use auth.uid() — no table access, no recursion.
--   • Cross-user checks use my_business_id() which is SECURITY DEFINER and
--     therefore bypasses the users RLS when it reads the table internally.
-- =============================================================================

-- SELECT: own row always; same-business rows visible too (for staff lists)
CREATE POLICY "users_select" ON public.users
  FOR SELECT TO authenticated
  USING (
    id = auth.uid()
    OR business_id = public.my_business_id()
  );

-- INSERT: client inserts own row during onboarding (id must match session uid)
CREATE POLICY "users_insert" ON public.users
  FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid());

-- UPDATE: own row only (profile name, avatar, branch assignment)
CREATE POLICY "users_update" ON public.users
  FOR UPDATE TO authenticated
  USING    (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- DELETE: forbidden from client — service role only (no policy = no access)


-- =============================================================================
-- SECTION 6 · businesses
-- =============================================================================

CREATE POLICY "businesses_select" ON public.businesses
  FOR SELECT TO authenticated
  USING (id = public.my_business_id());

-- Any authenticated user may create a business (becomes the owner)
CREATE POLICY "businesses_insert" ON public.businesses
  FOR INSERT TO authenticated
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "businesses_update" ON public.businesses
  FOR UPDATE TO authenticated
  USING    (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "businesses_delete" ON public.businesses
  FOR DELETE TO authenticated
  USING (owner_id = auth.uid());


-- =============================================================================
-- SECTION 7 · roles
-- =============================================================================
-- During initial onboarding the public.users row does not yet exist, so
-- my_business_id() returns NULL. i_am_owner_of() handles that window.

CREATE POLICY "roles_select" ON public.roles
  FOR SELECT TO authenticated
  USING (
    business_id = public.my_business_id()
    OR public.i_am_owner_of(business_id)
  );

CREATE POLICY "roles_insert" ON public.roles
  FOR INSERT TO authenticated
  WITH CHECK (
    business_id = public.my_business_id()
    OR public.i_am_owner_of(business_id)   -- owner during first-time setup
  );

-- Only Super Admin can mutate existing roles
CREATE POLICY "roles_update" ON public.roles
  FOR UPDATE TO authenticated
  USING (
    business_id = public.my_business_id()
    AND public.i_am_super_admin()
  );

CREATE POLICY "roles_delete" ON public.roles
  FOR DELETE TO authenticated
  USING (
    business_id = public.my_business_id()
    AND public.i_am_super_admin()
  );


-- =============================================================================
-- SECTION 8 · business_templates  (public read-only catalogue)
-- =============================================================================

CREATE POLICY "business_templates_select" ON public.business_templates
  FOR SELECT TO authenticated
  USING (true);   -- all authenticated users can read templates

-- INSERT / UPDATE / DELETE: service role only (managed via dashboard)


-- =============================================================================
-- SECTION 9 · branches
-- =============================================================================

CREATE POLICY "branches_select" ON public.branches
  FOR SELECT TO authenticated
  USING (
    business_id = public.my_business_id()
    OR public.i_am_owner_of(business_id)
  );

-- Owner may create branches during onboarding (before users row exists)
CREATE POLICY "branches_insert" ON public.branches
  FOR INSERT TO authenticated
  WITH CHECK (
    business_id = public.my_business_id()
    OR public.i_am_owner_of(business_id)
  );

-- Only Super Admin can rename / deactivate branches post-onboarding
CREATE POLICY "branches_update" ON public.branches
  FOR UPDATE TO authenticated
  USING (
    business_id = public.my_business_id()
    AND public.i_am_super_admin()
  );

CREATE POLICY "branches_delete" ON public.branches
  FOR DELETE TO authenticated
  USING (
    business_id = public.my_business_id()
    AND public.i_am_super_admin()
  );


-- =============================================================================
-- SECTION 10 · categories
-- =============================================================================

CREATE POLICY "categories_select" ON public.categories
  FOR SELECT TO authenticated
  USING (business_id = public.my_business_id());

CREATE POLICY "categories_insert" ON public.categories
  FOR INSERT TO authenticated
  WITH CHECK (business_id = public.my_business_id());

CREATE POLICY "categories_update" ON public.categories
  FOR UPDATE TO authenticated
  USING (business_id = public.my_business_id());

CREATE POLICY "categories_delete" ON public.categories
  FOR DELETE TO authenticated
  USING (business_id = public.my_business_id());


-- =============================================================================
-- SECTION 11 · products
-- =============================================================================

CREATE POLICY "products_select" ON public.products
  FOR SELECT TO authenticated
  USING (business_id = public.my_business_id());

CREATE POLICY "products_insert" ON public.products
  FOR INSERT TO authenticated
  WITH CHECK (business_id = public.my_business_id());

CREATE POLICY "products_update" ON public.products
  FOR UPDATE TO authenticated
  USING (business_id = public.my_business_id());

CREATE POLICY "products_delete" ON public.products
  FOR DELETE TO authenticated
  USING (business_id = public.my_business_id());


-- =============================================================================
-- SECTION 12 · product_variants
-- =============================================================================

CREATE POLICY "product_variants_select" ON public.product_variants
  FOR SELECT TO authenticated
  USING (business_id = public.my_business_id());

CREATE POLICY "product_variants_insert" ON public.product_variants
  FOR INSERT TO authenticated
  WITH CHECK (business_id = public.my_business_id());

CREATE POLICY "product_variants_update" ON public.product_variants
  FOR UPDATE TO authenticated
  USING (business_id = public.my_business_id());

CREATE POLICY "product_variants_delete" ON public.product_variants
  FOR DELETE TO authenticated
  USING (business_id = public.my_business_id());


-- =============================================================================
-- SECTION 13 · inventory_levels  (branch-aware)
-- =============================================================================
-- Super Admin (branch_id IS NULL) sees all branches.
-- Regular staff see their assigned branch only.

CREATE POLICY "inventory_levels_select" ON public.inventory_levels
  FOR SELECT TO authenticated
  USING (
    business_id = public.my_business_id()
    AND (
      public.i_am_super_admin()
      OR branch_id = public.my_branch_id()
    )
  );

CREATE POLICY "inventory_levels_insert" ON public.inventory_levels
  FOR INSERT TO authenticated
  WITH CHECK (
    business_id = public.my_business_id()
    AND (
      public.i_am_super_admin()
      OR branch_id = public.my_branch_id()
    )
  );

CREATE POLICY "inventory_levels_update" ON public.inventory_levels
  FOR UPDATE TO authenticated
  USING (
    business_id = public.my_business_id()
    AND (
      public.i_am_super_admin()
      OR branch_id = public.my_branch_id()
    )
  );

-- Only Super Admin can remove inventory rows
CREATE POLICY "inventory_levels_delete" ON public.inventory_levels
  FOR DELETE TO authenticated
  USING (
    business_id = public.my_business_id()
    AND public.i_am_super_admin()
  );


-- =============================================================================
-- SECTION 14 · stock_ledger  (append-only audit log)
-- =============================================================================
-- No UPDATE or DELETE policies = immutable from the client.

CREATE POLICY "stock_ledger_select" ON public.stock_ledger
  FOR SELECT TO authenticated
  USING (
    business_id = public.my_business_id()
    AND (
      public.i_am_super_admin()
      OR branch_id = public.my_branch_id()
    )
  );

CREATE POLICY "stock_ledger_insert" ON public.stock_ledger
  FOR INSERT TO authenticated
  WITH CHECK (
    business_id = public.my_business_id()
    AND (
      public.i_am_super_admin()
      OR branch_id = public.my_branch_id()
    )
  );


-- =============================================================================
-- SECTION 15 · transactions  (immutable POS records)
-- =============================================================================
-- No UPDATE or DELETE policies.

CREATE POLICY "transactions_select" ON public.transactions
  FOR SELECT TO authenticated
  USING (
    business_id = public.my_business_id()
    AND (
      public.i_am_super_admin()
      OR branch_id = public.my_branch_id()
    )
  );

CREATE POLICY "transactions_insert" ON public.transactions
  FOR INSERT TO authenticated
  WITH CHECK (
    business_id = public.my_business_id()
    AND (
      public.i_am_super_admin()
      OR branch_id = public.my_branch_id()
    )
    AND cashier_id = auth.uid()::text   -- cashier must be the logged-in user
  );


-- =============================================================================
-- SECTION 16 · transaction_items  (immutable)
-- =============================================================================
-- Branch isolation is inherited from the parent transaction via a subquery.
-- No UPDATE or DELETE policies.

CREATE POLICY "transaction_items_select" ON public.transaction_items
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.transactions t
      WHERE t.id = transaction_items.transaction_id
        AND t.business_id = public.my_business_id()
        AND (
          public.i_am_super_admin()
          OR t.branch_id = public.my_branch_id()
        )
    )
  );

CREATE POLICY "transaction_items_insert" ON public.transaction_items
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.transactions t
      WHERE t.id = transaction_items.transaction_id
        AND t.business_id = public.my_business_id()
    )
  );


-- =============================================================================
-- SECTION 17 · expenses
-- =============================================================================

CREATE POLICY "expenses_select" ON public.expenses
  FOR SELECT TO authenticated
  USING (
    business_id = public.my_business_id()
    AND (
      public.i_am_super_admin()
      OR branch_id = public.my_branch_id()
      OR submitted_by_id = auth.uid()::text
    )
  );

CREATE POLICY "expenses_insert" ON public.expenses
  FOR INSERT TO authenticated
  WITH CHECK (
    business_id    = public.my_business_id()
    AND submitted_by_id = auth.uid()::text
  );

-- Submitter may edit while pending; Super Admin may approve / reject
CREATE POLICY "expenses_update" ON public.expenses
  FOR UPDATE TO authenticated
  USING (
    business_id = public.my_business_id()
    AND (
      public.i_am_super_admin()
      OR (submitted_by_id = auth.uid()::text AND status = 'pending')
    )
  );

-- Only Super Admin can delete expenses
CREATE POLICY "expenses_delete" ON public.expenses
  FOR DELETE TO authenticated
  USING (
    business_id = public.my_business_id()
    AND public.i_am_super_admin()
  );


-- =============================================================================
-- SECTION 18 · receipt_settings  (1-row-per-business)
-- =============================================================================

CREATE POLICY "receipt_settings_select" ON public.receipt_settings
  FOR SELECT TO authenticated
  USING (business_id = public.my_business_id());

CREATE POLICY "receipt_settings_insert" ON public.receipt_settings
  FOR INSERT TO authenticated
  WITH CHECK (
    business_id = public.my_business_id()
    AND public.i_am_super_admin()
  );

CREATE POLICY "receipt_settings_update" ON public.receipt_settings
  FOR UPDATE TO authenticated
  USING (
    business_id = public.my_business_id()
    AND public.i_am_super_admin()
  );

CREATE POLICY "receipt_settings_delete" ON public.receipt_settings
  FOR DELETE TO authenticated
  USING (
    business_id = public.my_business_id()
    AND public.i_am_super_admin()
  );


-- =============================================================================
-- SECTION 19 · Storage bucket policies  (avatars)
-- =============================================================================
-- The bucket must already exist. Create it in the Supabase dashboard if needed:
--   Storage → New bucket → name: "avatars" → Public: ON
-- =============================================================================

-- Drop existing storage policies first
DROP POLICY IF EXISTS "avatars_select_public"    ON storage.objects;
DROP POLICY IF EXISTS "avatars_insert_own"       ON storage.objects;
DROP POLICY IF EXISTS "avatars_update_own"       ON storage.objects;
DROP POLICY IF EXISTS "avatars_delete_own"       ON storage.objects;

-- Avatars are publicly readable (used in receipts, staff lists)
CREATE POLICY "avatars_select_public" ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'avatars');

-- Users may only upload / overwrite inside their own folder  (<uid>/avatar.jpg)
CREATE POLICY "avatars_insert_own" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "avatars_update_own" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "avatars_delete_own" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );


-- =============================================================================
-- SECTION 20 · Performance indexes
-- =============================================================================
-- Every RLS policy that calls my_business_id() / my_branch_id() results in a
-- lookup on users(id). All FK join columns should be indexed.

CREATE INDEX IF NOT EXISTS idx_users_business_id      ON public.users(business_id);
CREATE INDEX IF NOT EXISTS idx_users_branch_id        ON public.users(branch_id);
CREATE INDEX IF NOT EXISTS idx_users_role_id          ON public.users(role_id);

CREATE INDEX IF NOT EXISTS idx_businesses_owner_id    ON public.businesses(owner_id);

CREATE INDEX IF NOT EXISTS idx_roles_business_id      ON public.roles(business_id);

CREATE INDEX IF NOT EXISTS idx_branches_business_id   ON public.branches(business_id);

CREATE INDEX IF NOT EXISTS idx_categories_business_id ON public.categories(business_id);

CREATE INDEX IF NOT EXISTS idx_products_business_id   ON public.products(business_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id   ON public.products(category_id);

CREATE INDEX IF NOT EXISTS idx_pv_business_id         ON public.product_variants(business_id);
CREATE INDEX IF NOT EXISTS idx_pv_product_id          ON public.product_variants(product_id);

CREATE INDEX IF NOT EXISTS idx_inv_business_id        ON public.inventory_levels(business_id);
CREATE INDEX IF NOT EXISTS idx_inv_branch_id          ON public.inventory_levels(branch_id);
CREATE INDEX IF NOT EXISTS idx_inv_variant_id         ON public.inventory_levels(variant_id);

CREATE INDEX IF NOT EXISTS idx_ledger_business_id     ON public.stock_ledger(business_id);
CREATE INDEX IF NOT EXISTS idx_ledger_branch_id       ON public.stock_ledger(branch_id);
CREATE INDEX IF NOT EXISTS idx_ledger_variant_id      ON public.stock_ledger(variant_id);
CREATE INDEX IF NOT EXISTS idx_ledger_created_at      ON public.stock_ledger(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_txn_business_id        ON public.transactions(business_id);
CREATE INDEX IF NOT EXISTS idx_txn_branch_id          ON public.transactions(branch_id);
CREATE INDEX IF NOT EXISTS idx_txn_cashier_id         ON public.transactions(cashier_id);
CREATE INDEX IF NOT EXISTS idx_txn_created_at         ON public.transactions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_txn_items_txn_id       ON public.transaction_items(transaction_id);
CREATE INDEX IF NOT EXISTS idx_txn_items_variant_id   ON public.transaction_items(variant_id);

CREATE INDEX IF NOT EXISTS idx_expenses_business_id   ON public.expenses(business_id);
CREATE INDEX IF NOT EXISTS idx_expenses_branch_id     ON public.expenses(branch_id);
CREATE INDEX IF NOT EXISTS idx_expenses_submitter     ON public.expenses(submitted_by_id);
CREATE INDEX IF NOT EXISTS idx_expenses_status        ON public.expenses(status);
CREATE INDEX IF NOT EXISTS idx_expenses_date          ON public.expenses(expense_date DESC);

CREATE INDEX IF NOT EXISTS idx_receipt_business_id    ON public.receipt_settings(business_id);
