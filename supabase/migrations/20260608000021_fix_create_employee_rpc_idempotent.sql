-- Migration: make create_employee_auth_account idempotent
--
-- Problem: if a previous addEmployee attempt created the auth user but then
-- failed (network error, timeout) before the employee row was written, the next
-- retry hits the duplicate-email guard and raises a false "already registered"
-- exception — even though no employee exists in the business.
--
-- Fix: three-way branch on whether the email already exists in auth.users:
--   1. Email + employee in THIS business  → true duplicate, raise DUPLICATE_EMAIL
--   2. Email + no employee in this biz    → orphaned auth account from a prior
--                                           partial failure; return existing UUID
--                                           so the caller can complete creation
--   3. Email absent                       → normal path, create auth user

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
  v_existing_uid UUID;
BEGIN
  -- ── Authorization ───────────────────────────────────────────────────────────
  v_caller_biz := public.my_business_id();

  IF v_caller_biz IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: caller has no active business';
  END IF;

  IF p_business_id IS NOT NULL AND v_caller_biz <> p_business_id THEN
    RAISE EXCEPTION 'Unauthorized: business mismatch';
  END IF;

  -- ── Idempotency / duplicate guard ───────────────────────────────────────────
  SELECT id INTO v_existing_uid
  FROM auth.users
  WHERE email = lower(trim(p_email))
  LIMIT 1;

  IF v_existing_uid IS NOT NULL THEN
    -- Email is already in auth.users. Decide whether it is a true duplicate or
    -- an orphaned account left by a prior partial failure.
    IF EXISTS (
      SELECT 1 FROM public.employees
      WHERE auth_user_id = v_existing_uid
        AND business_id  = v_caller_biz
    ) THEN
      -- A complete employee record exists for this email in this business.
      RAISE EXCEPTION 'DUPLICATE_EMAIL: An employee with this email already exists.';
    END IF;

    -- Orphaned auth account — no employee row in this business.
    -- Return the existing UUID so the caller can complete the employee record.
    RETURN v_existing_uid;
  END IF;

  -- ── Create Auth user ─────────────────────────────────────────────────────────
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

  -- ── Create email identity ────────────────────────────────────────────────────
  INSERT INTO auth.identities (
    id, user_id, provider_id, identity_data, provider, email,
    last_sign_in_at, created_at, updated_at
  ) VALUES (
    gen_random_uuid(),
    v_new_user_id,
    lower(trim(p_email)),
    jsonb_build_object('sub', v_new_user_id::text, 'email', lower(trim(p_email))),
    'email',
    lower(trim(p_email)),
    now(), now(), now()
  );

  -- ── Best-effort link to employee row ─────────────────────────────────────────
  -- The app upserts the employee separately after this call returns; NOT FOUND
  -- here is expected and is not an error.
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
