-- ============================================================
-- Improved create_employee_auth_account
--
-- Normalisation goal:
--   public.employees.role_id should be a real FK to public.roles
--   exactly like public.users.role_id — not a derived side-effect
--   of a trigger.  The RPC now resolves role_id explicitly from
--   the roles table (same as how business-owner accounts are set
--   up), and the trigger (migration 004) acts as a belt-and-
--   suspenders guard on subsequent UPDATE statements.
--
-- Race-condition fix:
--   The original RPC only created the auth.users row.  The
--   public.employees row was populated later by the Flutter sync
--   cycle.  If the employee logged in before sync ran,
--   get_my_business_context() returned nothing → hasBusiness=false
--   → router sent them to the business-setup page.
--   Now the employee row is upserted atomically in the same call.
--
--   All new parameters are DEFAULT NULL so existing callers that
--   pass only p_email + p_password continue to work unchanged.
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_employee_auth_account(
  p_email          text,
  p_password       text,
  -- Optional employee data for atomic public.employees creation
  p_employee_id    uuid        DEFAULT NULL,
  p_business_id    uuid        DEFAULT NULL,
  p_branch_id      uuid        DEFAULT NULL,
  p_full_name      text        DEFAULT NULL,
  p_role           text        DEFAULT NULL,   -- 'cashier' | 'branch_manager' | etc.
  p_employee_code  text        DEFAULT NULL,
  p_phone          text        DEFAULT NULL,
  p_hired_at       timestamptz DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = extensions, public, auth
AS $$
DECLARE
  v_user_id     uuid;
  v_instance_id uuid;
  v_role_id     uuid;   -- resolved from public.roles, same pattern as users.role_id
BEGIN
  -- ── Permission check ──────────────────────────────────────────────────────
  IF NOT public.i_am_super_admin() THEN
    RAISE EXCEPTION 'Permission denied: only administrators can create employee accounts'
      USING ERRCODE = '42501';
  END IF;

  -- ── Basic input validation ────────────────────────────────────────────────
  IF p_email IS NULL OR trim(p_email) = '' THEN
    RAISE EXCEPTION 'Email must not be empty' USING ERRCODE = '22023';
  END IF;
  IF p_password IS NULL OR length(p_password) < 6 THEN
    RAISE EXCEPTION 'Password must be at least 6 characters' USING ERRCODE = '22023';
  END IF;

  -- ── Resolve role_id from public.roles (same as users.role_id) ────────────
  -- We do this early so that:
  --   1. The INSERT can supply role_id explicitly rather than leaving it to
  --      the trigger — making the roles-table connection first-class.
  --   2. We fail fast with a clear error if the role name is unknown.
  IF p_business_id IS NOT NULL AND p_role IS NOT NULL THEN
    -- Ensure the 5 standard roles exist for this business (idempotent).
    PERFORM public.ensure_standard_roles(p_business_id);

    SELECT id
      INTO v_role_id
      FROM public.roles
     WHERE business_id = p_business_id
       AND name        = public._employee_role_display_name(p_role)
     LIMIT 1;

    IF v_role_id IS NULL THEN
      RAISE EXCEPTION
        'Role "%" not found in public.roles for business %',
        p_role, p_business_id
        USING ERRCODE = 'integrity_constraint_violation';
    END IF;
  END IF;

  -- ── Idempotency: reuse existing auth account ──────────────────────────────
  SELECT id INTO v_user_id
    FROM auth.users
   WHERE email = lower(trim(p_email))
   LIMIT 1;

  IF NOT FOUND THEN
    SELECT COALESCE(
      (SELECT instance_id FROM auth.users LIMIT 1),
      '00000000-0000-0000-0000-000000000000'::uuid
    ) INTO v_instance_id;

    v_user_id := gen_random_uuid();

    INSERT INTO auth.users (
      id, instance_id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data, is_super_admin,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) VALUES (
      v_user_id, v_instance_id, 'authenticated', 'authenticated',
      lower(trim(p_email)),
      crypt(p_password, gen_salt('bf')),
      now(), now(), now(),
      jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
      '{}', false, '', '', '', ''
    );

    INSERT INTO auth.identities (
      id, user_id, provider_id, identity_data, provider,
      last_sign_in_at, created_at, updated_at
    ) VALUES (
      gen_random_uuid(), v_user_id, lower(trim(p_email)),
      jsonb_build_object('sub', v_user_id::text, 'email', lower(trim(p_email))),
      'email', now(), now(), now()
    );
  END IF;

  -- ── Atomic employee row upsert ────────────────────────────────────────────
  -- Upsert public.employees with an explicit role_id FK to public.roles —
  -- the same normalisation pattern as public.users.role_id.
  --
  -- ON CONFLICT covers:
  --   • Flutter sync already pushed the row → link auth_user_id + sync role_id.
  --   • RPC retried (idempotency) → no redundant work.
  IF  p_employee_id   IS NOT NULL
  AND p_business_id   IS NOT NULL
  AND p_branch_id     IS NOT NULL
  AND p_full_name     IS NOT NULL
  AND p_role          IS NOT NULL
  AND p_employee_code IS NOT NULL
  THEN
    INSERT INTO public.employees (
      id, business_id, branch_id, auth_user_id,
      employee_code, full_name, email, phone,
      role,       -- text column kept for CHECK constraint + RLS policies
      role_id,    -- FK to public.roles — normalised like users.role_id
      status, hired_at, created_at, updated_at
    ) VALUES (
      p_employee_id, p_business_id, p_branch_id, v_user_id,
      p_employee_code, p_full_name, lower(trim(p_email)), p_phone,
      p_role,
      v_role_id,  -- explicitly resolved above from public.roles
      'active', COALESCE(p_hired_at, now()), now(), now()
    )
    ON CONFLICT (id) DO UPDATE
      SET auth_user_id = EXCLUDED.auth_user_id,
          role         = EXCLUDED.role,
          role_id      = EXCLUDED.role_id,   -- keep role_id in sync too
          updated_at   = now()
    WHERE employees.auth_user_id IS DISTINCT FROM EXCLUDED.auth_user_id
       OR employees.role_id      IS DISTINCT FROM EXCLUDED.role_id;
  END IF;

  RETURN v_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_employee_auth_account(
  text, text, uuid, uuid, uuid, text, text, text, text, timestamptz
) TO authenticated;
