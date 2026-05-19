-- ============================================================
-- create_employee_auth_account
--
-- Called from the Flutter app after an employee record is created.
-- Creates a Supabase Auth user for the employee so they can log in.
--
-- Security:
--   • SECURITY DEFINER — runs with owner privileges so it can
--     write to auth.users without exposing the service role key.
--   • Guards against non-super-admins calling it.
--   • Idempotent — returns the existing user_id if the email is
--     already registered in auth.users.
--
-- Password hashing uses pgcrypto (enabled by default on Supabase).
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_employee_auth_account(
  p_email    text,
  p_password text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = extensions, public, auth
AS $$
DECLARE
  v_user_id     uuid;
  v_instance_id uuid;
BEGIN
  -- Permission check: only super-admins (owners / branch managers) may
  -- create auth accounts on behalf of other users.
  IF NOT public.i_am_super_admin() THEN
    RAISE EXCEPTION 'Permission denied: only administrators can create employee accounts'
      USING ERRCODE = '42501';
  END IF;

  -- Basic input validation
  IF p_email  IS NULL OR trim(p_email)    = '' THEN
    RAISE EXCEPTION 'Email must not be empty' USING ERRCODE = '22023';
  END IF;
  IF p_password IS NULL OR length(p_password) < 6 THEN
    RAISE EXCEPTION 'Password must be at least 6 characters' USING ERRCODE = '22023';
  END IF;

  -- Idempotency: return existing user_id if the email is already registered.
  SELECT id INTO v_user_id
    FROM auth.users
   WHERE email = lower(trim(p_email))
   LIMIT 1;

  IF FOUND THEN
    RETURN v_user_id;
  END IF;

  -- Resolve instance_id from an existing user (falls back to the default
  -- single-tenant UUID if the table is empty).
  SELECT COALESCE(
    (SELECT instance_id FROM auth.users LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::uuid
  ) INTO v_instance_id;

  v_user_id := gen_random_uuid();

  INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,   -- auto-confirm so the employee can log in immediately
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change
  ) VALUES (
    v_user_id,
    v_instance_id,
    'authenticated',
    'authenticated',
    lower(trim(p_email)),
    crypt(p_password, gen_salt('bf')),
    now(),
    now(),
    now(),
    jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
    '{}',
    false,
    '', '', '', ''
  );

  -- Also insert the corresponding identity row that Supabase Auth expects.
  INSERT INTO auth.identities (
    id,
    user_id,
    provider_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_user_id,
    lower(trim(p_email)),
    jsonb_build_object('sub', v_user_id::text, 'email', lower(trim(p_email))),
    'email',
    now(),
    now(),
    now()
  );

  RETURN v_user_id;
END;
$$;

-- Only authenticated users can call this; the function body enforces
-- the super-admin restriction on top of that.
GRANT EXECUTE ON FUNCTION public.create_employee_auth_account(text, text)
  TO authenticated;
