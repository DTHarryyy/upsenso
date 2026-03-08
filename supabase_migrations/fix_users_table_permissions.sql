-- Fix PostgREST 42501: permission denied for table public.users
-- Run this in Supabase SQL Editor.

-- 1) Ensure authenticated can access schema and required tables.
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.users TO authenticated;
REVOKE DELETE ON TABLE public.users FROM authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.businesses TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.roles TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.branches TO authenticated;

-- 2) Users table: ENABLE RLS with self-access policies.
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS users_select_self ON public.users;
CREATE POLICY users_select_self
ON public.users
FOR SELECT
TO authenticated
USING (id = auth.uid());

DROP POLICY IF EXISTS users_insert_self ON public.users;
CREATE POLICY users_insert_self
ON public.users
FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS users_update_self ON public.users;
CREATE POLICY users_update_self
ON public.users
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- 3) Businesses table policies used by setup flow and fallback context lookup.
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS businesses_select_owner ON public.businesses;
CREATE POLICY businesses_select_owner
ON public.businesses
FOR SELECT
TO authenticated
USING (owner_id = auth.uid());

DROP POLICY IF EXISTS businesses_insert_owner ON public.businesses;
CREATE POLICY businesses_insert_owner
ON public.businesses
FOR INSERT
TO authenticated
WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS businesses_update_owner ON public.businesses;
CREATE POLICY businesses_update_owner
ON public.businesses
FOR UPDATE
TO authenticated
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

-- 4) Branches table: DISABLE RLS (auth tokens are primary security)
ALTER TABLE public.branches DISABLE ROW LEVEL SECURITY;

-- 5) Roles read policy used by context resolution.
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS roles_select_owner ON public.roles;
CREATE POLICY roles_select_owner
ON public.roles
FOR SELECT
TO authenticated
USING (
	EXISTS (
		SELECT 1
		FROM public.businesses b
		WHERE b.id = business_id
			AND b.owner_id = auth.uid()
	)
);

DROP POLICY IF EXISTS roles_insert_owner ON public.roles;
CREATE POLICY roles_insert_owner
ON public.roles
FOR INSERT
TO authenticated
WITH CHECK (
	EXISTS (
		SELECT 1
		FROM public.businesses b
		WHERE b.id = business_id
			AND b.owner_id = auth.uid()
	)
);

DROP POLICY IF EXISTS roles_update_owner ON public.roles;
CREATE POLICY roles_update_owner
ON public.roles
FOR UPDATE
TO authenticated
USING (
	EXISTS (
		SELECT 1
		FROM public.businesses b
		WHERE b.id = business_id
			AND b.owner_id = auth.uid()
	)
)
WITH CHECK (
	EXISTS (
		SELECT 1
		FROM public.businesses b
		WHERE b.id = business_id
			AND b.owner_id = auth.uid()
	)
);
