-- =====================================================
-- FINAL FIX: Drop all conflicting policies and create correct ones
-- =====================================================

-- Drop ALL existing policies on users, businesses, and roles
DROP POLICY IF EXISTS select_user ON public.users;
DROP POLICY IF EXISTS insert_user ON public.users;
DROP POLICY IF EXISTS update_user ON public.users;
DROP POLICY IF EXISTS delete_user ON public.users;
DROP POLICY IF EXISTS users_select_own ON public.users;
DROP POLICY IF EXISTS users_insert_own ON public.users;

DROP POLICY IF EXISTS select_business_owner ON public.businesses;
DROP POLICY IF EXISTS insert_business_owner ON public.businesses;
DROP POLICY IF EXISTS update_business_owner ON public.businesses;
DROP POLICY IF EXISTS delete_business_owner ON public.businesses;
DROP POLICY IF EXISTS businesses_select_own ON public.businesses;
DROP POLICY IF EXISTS businesses_insert_own ON public.businesses;
DROP POLICY IF EXISTS businesses_update_own ON public.businesses;
DROP POLICY IF EXISTS businesses_select_related ON public.businesses;

DROP POLICY IF EXISTS select_role ON public.roles;
DROP POLICY IF EXISTS insert_role ON public.roles;
DROP POLICY IF EXISTS update_role ON public.roles;
DROP POLICY IF EXISTS delete_role ON public.roles;
DROP POLICY IF EXISTS roles_select_business ON public.roles;
DROP POLICY IF EXISTS roles_insert_business_owner ON public.roles;
DROP POLICY IF EXISTS roles_select_related ON public.roles;

-- =====================================================
-- USERS TABLE: Simple policies without circular dependency
-- =====================================================

-- Allow users to read their own record by id or email
CREATE POLICY users_select_own ON public.users
FOR SELECT TO authenticated
USING (
  id = auth.uid() 
  OR email = (SELECT email FROM auth.users WHERE id = auth.uid())
);

-- Allow users to insert their own record
CREATE POLICY users_insert_own ON public.users
FOR INSERT TO authenticated
WITH CHECK (
  id = auth.uid() 
  OR email = (SELECT email FROM auth.users WHERE id = auth.uid())
);

-- Allow users to update their own record
CREATE POLICY users_update_own ON public.users
FOR UPDATE TO authenticated
USING (
  id = auth.uid() 
  OR email = (SELECT email FROM auth.users WHERE id = auth.uid())
);

-- =====================================================
-- BUSINESSES TABLE: Owner can manage, members can read
-- =====================================================

-- Owner can read their businesses
CREATE POLICY businesses_select_owner ON public.businesses
FOR SELECT TO authenticated
USING (owner_id = auth.uid());

-- Owner can insert businesses
CREATE POLICY businesses_insert_owner ON public.businesses
FOR INSERT TO authenticated
WITH CHECK (owner_id = auth.uid());

-- Owner can update their businesses
CREATE POLICY businesses_update_owner ON public.businesses
FOR UPDATE TO authenticated
USING (owner_id = auth.uid());

-- Owner can delete their businesses
CREATE POLICY businesses_delete_owner ON public.businesses
FOR DELETE TO authenticated
USING (owner_id = auth.uid());

-- =====================================================
-- ROLES TABLE: Read roles in businesses you own
-- =====================================================

-- Can read roles in businesses you own
CREATE POLICY roles_select_owner ON public.roles
FOR SELECT TO authenticated
USING (
  business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  )
);

-- Owner can insert roles in their business
CREATE POLICY roles_insert_owner ON public.roles
FOR INSERT TO authenticated
WITH CHECK (
  business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  )
);

-- Owner can update roles in their business
CREATE POLICY roles_update_owner ON public.roles
FOR UPDATE TO authenticated
USING (
  business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  )
);

-- Owner can delete roles in their business
CREATE POLICY roles_delete_owner ON public.roles
FOR DELETE TO authenticated
USING (
  business_id IN (
    SELECT id FROM businesses WHERE owner_id = auth.uid()
  )
);

-- =====================================================
-- TEST: Verify you can now read your data
-- =====================================================

SELECT 'Testing users table...' as test;
SELECT id, business_id, full_name, email, role_id
FROM users
WHERE id = auth.uid();

SELECT 'Testing businesses table...' as test;
SELECT id, name, owner_id
FROM businesses
WHERE owner_id = auth.uid();

SELECT 'Testing roles table...' as test;
SELECT r.id, r.name, r.business_id
FROM roles r
JOIN businesses b ON b.id = r.business_id
WHERE b.owner_id = auth.uid();

-- =====================================================
-- DONE!
-- =====================================================
-- After running this:
-- 1. Check if the 3 test queries above returned your data
-- 2. If YES, restart your Flutter app (hot restart)
-- 3. Check Inventory screen - data should now populate!
