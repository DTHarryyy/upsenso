-- Two fixes to create_employee_auth_account:
-- 1. Password policy: reject passwords under 8 chars (previously unenforced).
-- 2. Cross-tenant account leak: the orphan-reuse branch only checked whether
--    the existing auth user had an employee row in the CALLER's business. An
--    email already belonging to a live employee of a DIFFERENT business was
--    incorrectly treated as an orphaned/reusable account and its real auth
--    UUID was returned to the caller. Now any employee link (in any
--    business) blocks reuse, with the same generic error either way so the
--    response doesn't reveal which business owns the email.
-- Rollback: re-apply the previous definition from migration
--   20260608000021_fix_create_employee_rpc_idempotent.sql (or equivalent).

CREATE OR REPLACE FUNCTION public.create_employee_auth_account(
  p_email text,
  p_password text,
  p_employee_id uuid DEFAULT NULL::uuid,
  p_business_id uuid DEFAULT NULL::uuid,
  p_branch_id uuid DEFAULT NULL::uuid,
  p_role_id uuid DEFAULT NULL::uuid,
  p_full_name text DEFAULT NULL::text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'extensions', 'public', 'auth'
AS $function$
DECLARE
  v_new_user_id  UUID;
  v_caller_biz   UUID;
  v_existing_uid UUID;
BEGIN
  -- ── Authorization ─────────────────────────────────────────────────────────
  v_caller_biz := public.my_business_id();

  IF v_caller_biz IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: caller has no active business';
  END IF;

  IF p_business_id IS NOT NULL AND v_caller_biz <> p_business_id THEN
    RAISE EXCEPTION 'Unauthorized: business mismatch';
  END IF;

  IF p_password IS NULL OR length(p_password) < 8 THEN
    RAISE EXCEPTION 'WEAK_PASSWORD: Password must be at least 8 characters.';
  END IF;

  -- ── Idempotency / duplicate guard ─────────────────────────────────────────
  SELECT id INTO v_existing_uid
  FROM auth.users
  WHERE email = lower(trim(p_email))
  LIMIT 1;

  IF v_existing_uid IS NOT NULL THEN
    IF EXISTS (
      SELECT 1 FROM public.employees WHERE auth_user_id = v_existing_uid
    ) THEN
      -- Linked to an employee somewhere (caller's business or another's) —
      -- never reusable, and the message doesn't disclose which case it is.
      RAISE EXCEPTION 'DUPLICATE_EMAIL: An employee with this email already exists.';
    END IF;
    -- Truly orphaned (auth user with no employee link anywhere) — safe to
    -- reuse, e.g. recovering from a prior partial failure.
    RETURN v_existing_uid;
  END IF;

  -- ── Create Auth user ──────────────────────────────────────────────────────
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

  -- ── Create email identity ─────────────────────────────────────────────────
  -- NOTE: Do NOT include 'email' in the column list.  In Supabase auth ≥ 2.x
  -- auth.identities.email is a GENERATED column derived from identity_data.
  -- Inserting an explicit value raises "cannot insert a non-DEFAULT value".
  INSERT INTO auth.identities (
    id, user_id, provider_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) VALUES (
    gen_random_uuid(),
    v_new_user_id,
    lower(trim(p_email)),
    jsonb_build_object('sub', v_new_user_id::text, 'email', lower(trim(p_email))),
    'email',
    now(), now(), now()
  );

  -- ── Best-effort link to employee row ─────────────────────────────────────
  IF p_employee_id IS NOT NULL THEN
    UPDATE public.employees
       SET auth_user_id = v_new_user_id
     WHERE id          = p_employee_id
       AND business_id = v_caller_biz;
  END IF;

  RETURN v_new_user_id;
END;
$function$;
