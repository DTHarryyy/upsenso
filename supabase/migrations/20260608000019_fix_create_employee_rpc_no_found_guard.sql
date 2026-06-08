-- Remove the NOT FOUND guard from create_employee_auth_account.
--
-- The app now upserts the employee row to Supabase directly after the RPC
-- returns, so the RPC no longer needs to UPDATE employees — it only needs to
-- create the Auth user and return the UUID. Keep the UPDATE attempt as a
-- best-effort convenience (useful if the row already exists from a prior
-- partial sync), but do NOT raise if the row is absent.

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
SET search_path = extensions, public, auth
AS $$
DECLARE
  v_new_user_id  UUID;
  v_caller_biz   UUID;
BEGIN
  v_caller_biz := public.my_business_id();

  IF v_caller_biz IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: caller has no active business';
  END IF;

  IF p_business_id IS NOT NULL AND v_caller_biz <> p_business_id THEN
    RAISE EXCEPTION 'Unauthorized: business mismatch';
  END IF;

  IF EXISTS (SELECT 1 FROM auth.users WHERE email = lower(trim(p_email))) THEN
    RAISE EXCEPTION 'Email already registered: %', p_email;
  END IF;

  v_new_user_id := gen_random_uuid();

  INSERT INTO auth.users (
    instance_id, id, aud, role, email,
    encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at,
    confirmation_token, email_change, email_change_token_new, recovery_token
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
    now(), now(),
    '', '', '', ''
  );

  INSERT INTO auth.identities (
    id, user_id, provider_id, identity_data, provider, email,
    last_sign_in_at, created_at, updated_at
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
    now(), now(), now()
  );

  -- Best-effort link: update the employee row if it already exists in Supabase.
  -- The app upserts the employee separately after this call, so NOT FOUND
  -- is expected and is not an error.
  IF p_employee_id IS NOT NULL THEN
    UPDATE public.employees
       SET auth_user_id = v_new_user_id
     WHERE id          = p_employee_id
       AND business_id = v_caller_biz;
  END IF;

  RETURN v_new_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_employee_auth_account TO authenticated;
