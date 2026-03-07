-- =====================================================
-- HARD FIX: permissions + non-recursive RLS policies
-- Fixes: PostgrestException 42501 permission denied for table users
-- =====================================================

BEGIN;

-- Base privileges required before RLS can even run
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.businesses TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.roles TO authenticated;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'branches'
  ) THEN
    EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.branches TO authenticated';
  END IF;
END $$;

-- Ensure RLS is enabled
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies on the target tables to remove conflicts
DO $$
DECLARE
  p RECORD;
BEGIN
  FOR p IN
    SELECT tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('users', 'businesses', 'roles')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', p.policyname, p.tablename);
  END LOOP;
END $$;

-- -----------------------------
-- USERS policies (self only)
-- -----------------------------
CREATE POLICY users_select_own ON public.users
FOR SELECT TO authenticated
USING (
  id = auth.uid()
  OR email = COALESCE(auth.jwt() ->> 'email', '')
);

CREATE POLICY users_insert_own ON public.users
FOR INSERT TO authenticated
WITH CHECK (
  id = auth.uid()
  OR email = COALESCE(auth.jwt() ->> 'email', '')
);

CREATE POLICY users_update_own ON public.users
FOR UPDATE TO authenticated
USING (
  id = auth.uid()
  OR email = COALESCE(auth.jwt() ->> 'email', '')
)
WITH CHECK (
  id = auth.uid()
  OR email = COALESCE(auth.jwt() ->> 'email', '')
);

-- -----------------------------
-- BUSINESSES policies
-- owner full access, member read
-- -----------------------------
CREATE POLICY businesses_select_owner_or_member ON public.businesses
FOR SELECT TO authenticated
USING (
  owner_id = auth.uid()
  OR id IN (
    SELECT u.business_id
    FROM public.users u
    WHERE u.id = auth.uid()
  )
);

CREATE POLICY businesses_insert_owner ON public.businesses
FOR INSERT TO authenticated
WITH CHECK (owner_id = auth.uid());

CREATE POLICY businesses_update_owner ON public.businesses
FOR UPDATE TO authenticated
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

CREATE POLICY businesses_delete_owner ON public.businesses
FOR DELETE TO authenticated
USING (owner_id = auth.uid());

-- -----------------------------
-- ROLES policies
-- -----------------------------
CREATE POLICY roles_select_owner_or_member ON public.roles
FOR SELECT TO authenticated
USING (
  business_id IN (
    SELECT b.id
    FROM public.businesses b
    WHERE b.owner_id = auth.uid()
  )
  OR business_id IN (
    SELECT u.business_id
    FROM public.users u
    WHERE u.id = auth.uid()
  )
);

CREATE POLICY roles_insert_owner ON public.roles
FOR INSERT TO authenticated
WITH CHECK (
  business_id IN (
    SELECT b.id
    FROM public.businesses b
    WHERE b.owner_id = auth.uid()
  )
);

CREATE POLICY roles_update_owner ON public.roles
FOR UPDATE TO authenticated
USING (
  business_id IN (
    SELECT b.id
    FROM public.businesses b
    WHERE b.owner_id = auth.uid()
  )
)
WITH CHECK (
  business_id IN (
    SELECT b.id
    FROM public.businesses b
    WHERE b.owner_id = auth.uid()
  )
);

CREATE POLICY roles_delete_owner ON public.roles
FOR DELETE TO authenticated
USING (
  business_id IN (
    SELECT b.id
    FROM public.businesses b
    WHERE b.owner_id = auth.uid()
  )
);

COMMIT;

-- Ask PostgREST to refresh schema cache
NOTIFY pgrst, 'reload schema';

-- -----------------------------
-- Verify grants + policies
-- -----------------------------
SELECT
  has_schema_privilege('authenticated', 'public', 'USAGE') AS public_usage,
  has_table_privilege('authenticated', 'public.users', 'SELECT') AS users_select,
  has_table_privilege('authenticated', 'public.businesses', 'SELECT') AS businesses_select,
  has_table_privilege('authenticated', 'public.roles', 'SELECT') AS roles_select;

SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('users', 'businesses', 'roles')
ORDER BY tablename, policyname;

-- After running this script:
-- 1) Fully restart the Flutter app
-- 2) Sign out and sign in once
-- 3) Re-open Inventory and verify logs no longer show 42501
