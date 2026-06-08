-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: fix_employees_schema
--
-- Three categories of fixes identified during schema scan:
--
-- 1. employees.user_id NOT NULL  →  nullable
--    New employees are created locally before a Supabase Auth account exists.
--    Both user_id and auth_user_id are null at that point; the existing
--    sync_employee_auth_ids trigger back-fills user_id once auth_user_id is set.
--    The NOT NULL constraint causes every employee upsert from the app to fail.
--
-- 2. biz_isolation_* policies used get_my_business_id()  →  my_business_id()
--    get_my_business_id() is equivalent but lacks the is_active filter and has
--    no ORDER BY before its LIMIT 1, making it non-deterministic when a user
--    belongs to multiple businesses. my_business_id() is the canonical, stable
--    version used everywhere else.
--
-- 3. create_employee_auth_account RPC was missing
--    The app calls this RPC immediately after saving a new employee to provision
--    a Supabase Auth user (email + password). The call is wrapped in try/catch
--    so the missing function caused a silent failure — employees were saved
--    locally but could never receive login credentials.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Make employees.user_id nullable ───────────────────────────────────────

ALTER TABLE public.employees
  ALTER COLUMN user_id DROP NOT NULL;


-- ── 2. Replace biz_isolation_* policies with my_business_id() ────────────────

-- employees ─ the ALL policy covers any command not addressed by a narrower
-- policy. Granular insert/update/delete policies already exist and use
-- my_business_id(), so this change closes only the SELECT isolation gap caused
-- by the non-deterministic get_my_business_id().
DROP POLICY IF EXISTS biz_isolation_employees ON public.employees;
CREATE POLICY biz_isolation_employees ON public.employees
  FOR ALL
  TO authenticated
  USING (business_id = my_business_id());

-- employee_branches
DROP POLICY IF EXISTS biz_isolation_employee_branches ON public.employee_branches;
CREATE POLICY biz_isolation_employee_branches ON public.employee_branches
  FOR ALL
  TO authenticated
  USING (
    employee_id IN (
      SELECT id FROM public.employees
      WHERE business_id = my_business_id()
    )
  );

-- employee_roles
DROP POLICY IF EXISTS biz_isolation_employee_roles ON public.employee_roles;
CREATE POLICY biz_isolation_employee_roles ON public.employee_roles
  FOR ALL
  TO authenticated
  USING (
    employee_id IN (
      SELECT id FROM public.employees
      WHERE business_id = my_business_id()
    )
  );

-- roles
DROP POLICY IF EXISTS biz_isolation_roles ON public.roles;
CREATE POLICY biz_isolation_roles ON public.roles
  FOR ALL
  TO authenticated
  USING (business_id = my_business_id());


-- ── 3. create_employee_auth_account RPC ──────────────────────────────────────
--
-- Provisions a Supabase Auth user (email/password) for a new employee and
-- links the resulting auth_user_id back to the employees row.
--
-- Parameters
--   p_email        Required. Must be unique in auth.users.
--   p_password     Required. Stored as bcrypt hash via pgcrypto.
--   p_employee_id  Optional. When supplied the function sets auth_user_id on
--                  the matching employees row (same business guard applies).
--   p_business_id  Optional. When supplied the caller's business must match.
--   p_branch_id    Accepted for API symmetry; reserved for future use.
--   p_role_id      Accepted for API symmetry; reserved for future use.
--
-- Returns the UUID of the newly created auth user.
-- Raises an exception (caught by the app) on any validation or constraint
-- error; the app treats a null return as "auth account not yet created".
--
-- Security: SECURITY DEFINER runs as the function owner (postgres/service role)
-- so it can write to auth.users and auth.identities. The caller's business
-- membership is verified before any writes occur.
CREATE OR REPLACE FUNCTION public.create_employee_auth_account(
  p_email       TEXT,
  p_password    TEXT,
  p_employee_id UUID DEFAULT NULL,
  p_business_id UUID DEFAULT NULL,
  p_branch_id   UUID DEFAULT NULL,
  p_role_id     UUID DEFAULT NULL,
  p_full_name   TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
-- extensions first so crypt()/gen_salt() resolve from pgcrypto without
-- schema-qualifying them; auth last so auth.* names are still unambiguous.
SET search_path = extensions, public, auth
AS $$
DECLARE
  v_new_user_id  UUID;
  v_caller_biz   UUID;
BEGIN
  -- ── Authorization ──────────────────────────────────────────────────────────
  v_caller_biz := public.my_business_id();

  IF v_caller_biz IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: caller has no active business';
  END IF;

  IF p_business_id IS NOT NULL AND v_caller_biz <> p_business_id THEN
    RAISE EXCEPTION 'Unauthorized: caller does not belong to business %', p_business_id;
  END IF;

  -- ── Duplicate guard ────────────────────────────────────────────────────────
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = lower(trim(p_email))) THEN
    RAISE EXCEPTION 'Email is already registered: %', p_email;
  END IF;

  -- ── Create Auth user ───────────────────────────────────────────────────────
  v_new_user_id := gen_random_uuid();

  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,   -- pre-confirm; owner creates account on behalf of employee
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    v_new_user_id,
    'authenticated',
    'authenticated',
    lower(trim(p_email)),
    crypt(p_password, gen_salt('bf')),
    now(),
    jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
    jsonb_build_object('full_name', coalesce(p_full_name, '')),
    now(),
    now(),
    '',
    '',
    '',
    ''
  );

  -- ── Create email identity ──────────────────────────────────────────────────
  INSERT INTO auth.identities (
    id,
    user_id,
    provider_id,
    identity_data,
    provider,
    email,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_new_user_id,
    lower(trim(p_email)),
    jsonb_build_object(
      'sub',   v_new_user_id::text,
      'email', lower(trim(p_email))
    ),
    'email',
    lower(trim(p_email)),
    now(),
    now(),
    now()
  );

  -- ── Link to employee row ───────────────────────────────────────────────────
  IF p_employee_id IS NOT NULL THEN
    UPDATE public.employees
       SET auth_user_id = v_new_user_id
     WHERE id          = p_employee_id
       AND business_id = v_caller_biz;

    -- Guard against stale employee_id references from a different business.
    IF NOT FOUND THEN
      RAISE EXCEPTION
        'Employee % not found in business %', p_employee_id, v_caller_biz;
    END IF;
  END IF;

  RETURN v_new_user_id;
END;
$$;

-- Allow any authenticated user to call this; the function body enforces
-- that the caller owns or belongs to the target business.
GRANT EXECUTE ON FUNCTION public.create_employee_auth_account TO authenticated;
