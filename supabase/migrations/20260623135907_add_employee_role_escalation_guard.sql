-- =============================================================================
-- Add the role anti-escalation check to create_employee_auth_account, now that
-- roles.priority is seeded (20260623135805). APPLIED to production 2026-06-23
-- (remote version 20260623135907).
--
-- A non-owner caller may not assign a role at or above their own highest role
-- priority; owners are exempt. Fail-closed: a caller with no resolvable role
-- priority gets -1, so any assignment is blocked.
--
-- SCOPE NOTE: this gates LOGIN provisioning. The role itself lands on the
-- employees row / employee_roles junction via the offline-first sync, so the
-- AUTHORITATIVE escalation gate still belongs on those table RLS policies
-- (Layer 2) — pending a pg_policy enumeration of the existing employees /
-- employee_roles policies (FOR ALL business-only + "granular" policies per
-- 20260608000018; permissive policies combine with OR).
--
-- Verified after apply: create_gate / assign_gate / escalation_check all present.
--
-- ROLLBACK: restore 20260623135338_harden_create_employee_permission_gate.sql
--   (drops the priority comparison; keeps the create + assign_role gates).
-- =============================================================================

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
  v_is_owner     BOOLEAN;
  v_caller_prio  INT;
  v_target_prio  INT;
BEGIN
  v_caller_biz := public.my_business_id();

  IF v_caller_biz IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: caller has no active business';
  END IF;

  IF p_business_id IS NOT NULL AND v_caller_biz <> p_business_id THEN
    RAISE EXCEPTION 'Unauthorized: business mismatch';
  END IF;

  IF NOT public.has_permission('employees.create') THEN
    RAISE EXCEPTION 'UNAUTHORIZED: employees.create permission required';
  END IF;

  IF p_role_id IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1 FROM public.businesses
      WHERE id = v_caller_biz AND owner_id = auth.uid()
    ) INTO v_is_owner;

    IF NOT v_is_owner THEN
      IF NOT public.has_permission('employees.assign_role') THEN
        RAISE EXCEPTION 'UNAUTHORIZED: employees.assign_role permission required';
      END IF;

      SELECT priority INTO v_target_prio FROM public.roles WHERE id = p_role_id;
      IF v_target_prio IS NULL THEN
        RAISE EXCEPTION 'Invalid role';
      END IF;

      SELECT COALESCE(MAX(r.priority), -1) INTO v_caller_prio
      FROM public.employees e
      JOIN public.employee_roles er ON er.employee_id = e.id
      JOIN public.roles r           ON r.id           = er.role_id
      WHERE e.auth_user_id = auth.uid();

      IF v_target_prio >= v_caller_prio THEN
        RAISE EXCEPTION
          'UNAUTHORIZED: cannot assign a role at or above your own level';
      END IF;
    END IF;
  END IF;

  IF p_password IS NULL OR length(p_password) < 8 THEN
    RAISE EXCEPTION 'WEAK_PASSWORD: Password must be at least 8 characters.';
  END IF;

  SELECT id INTO v_existing_uid
  FROM auth.users
  WHERE email = lower(trim(p_email))
  LIMIT 1;

  IF v_existing_uid IS NOT NULL THEN
    IF EXISTS (
      SELECT 1 FROM public.employees WHERE auth_user_id = v_existing_uid
    ) THEN
      RAISE EXCEPTION 'DUPLICATE_EMAIL: An employee with this email already exists.';
    END IF;
    RETURN v_existing_uid;
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

  IF p_employee_id IS NOT NULL THEN
    UPDATE public.employees
       SET auth_user_id = v_new_user_id
     WHERE id          = p_employee_id
       AND business_id = v_caller_biz;
  END IF;

  RETURN v_new_user_id;
END;
$function$;
