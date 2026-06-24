-- =============================================================================
-- Harden create_employee_auth_account authorization. APPLIED to production
-- 2026-06-23 via MCP apply_migration (remote version 20260623135338).
--
-- Before: the RPC only checked caller-has-business + business match + password
-- length, so ANY authenticated business member could provision login accounts
-- via the API. Now it requires has_permission('employees.create') (owners pass
-- via the owner bypass in has_permission, 20260623000002), and requires
-- employees.assign_role when a role is supplied (owners exempt).
--
-- DEFERRED — full anti-escalation by role RANK is intentionally NOT added here:
-- roles.priority is unpopulated (all 0) in this project, so a target<caller
-- priority check would wrongly block every non-owner role assignment (0 >= 0).
-- Follow-up: seed role priorities (Owner > Branch Manager > Cashier/Inventory) —
-- which also fixes current_user_role()'s ORDER BY priority — then add the
-- priority comparison. The role lands on employees.role_id / employee_roles via
-- sync, so the authoritative escalation gate ultimately belongs on those table
-- policies too (Layer 2, pending a pg_policy enumeration).
--
-- Verified before apply: client passes p_role_id; only owners exist (0 employee
-- rows) so nothing is blocked now; Branch Manager holds create + assign_role.
--
-- ROLLBACK: restore the definition from 20260619000007_harden_create_employee_
--   auth_account.sql (removes the create + assign_role gates added here).
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
BEGIN
  -- ── Authorization ─────────────────────────────────────────────────────────
  v_caller_biz := public.my_business_id();

  IF v_caller_biz IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: caller has no active business';
  END IF;

  IF p_business_id IS NOT NULL AND v_caller_biz <> p_business_id THEN
    RAISE EXCEPTION 'Unauthorized: business mismatch';
  END IF;

  -- Caller must be permitted to create employees (owners pass via the owner
  -- bypass baked into has_permission).
  IF NOT public.has_permission('employees.create') THEN
    RAISE EXCEPTION 'UNAUTHORIZED: employees.create permission required';
  END IF;

  -- Assigning a role requires assign_role rights (owners exempt).
  IF p_role_id IS NOT NULL THEN
    SELECT EXISTS (
      SELECT 1 FROM public.businesses
      WHERE id = v_caller_biz AND owner_id = auth.uid()
    ) INTO v_is_owner;

    IF NOT v_is_owner AND NOT public.has_permission('employees.assign_role') THEN
      RAISE EXCEPTION 'UNAUTHORIZED: employees.assign_role permission required';
    END IF;
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
      RAISE EXCEPTION 'DUPLICATE_EMAIL: An employee with this email already exists.';
    END IF;
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
