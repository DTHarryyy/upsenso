-- =============================================================================
-- M7.1 Phase 3 — structural caps: branches & seats enforced server-side.
--
-- The plan meters branches/seats/devices (design §6.2). Devices land in
-- Phase 4 (registered_devices). Here we cap the two identity-plane resources
-- that the client can create through normal writes.
--
-- Two enforcement surfaces, because each create path is different:
--   * BRANCHES arrive via a plain INSERT (client + sync). A RESTRICTIVE
--     INSERT policy `count(*) < effective_limits().max_branches` is the gate.
--     NULL limit (enterprise) = unlimited. This is the repo's first
--     count<limit RLS — no prior art, patterned on the RESTRICTIVE-INSERT
--     scaffold from 20260627000003.
--   * SEATS (employees) are minted by the SECURITY DEFINER RPC
--     create_employee_auth_account, which BYPASSES RLS. So the authoritative
--     seat cap lives INSIDE that function; the employees RESTRICTIVE INSERT
--     policy is defense-in-depth for any direct insert path.
--     A BEFORE UPDATE trigger re-checks the cap on reactivation
--     (is_active false→true) — suspending frees a seat, reactivating reclaims
--     one (§10). WITH CHECK can't see OLD, so this must be a trigger.
--
-- Soft-cap philosophy (§6.2): the count<limit check has an inherent
-- concurrent-insert race (two inserts can both pass at count = limit-1). This
-- is ACCEPTED — branches/seats are low-volume, and a hard advisory lock would
-- hurt UX more than a rare 1-over. Never delete to enforce; block the NEXT
-- create only.
--
-- ROLLBACK:
--   DROP POLICY IF EXISTS branches_cap_insert  ON public.branches;
--   DROP POLICY IF EXISTS employees_cap_insert ON public.employees;
--   DROP TRIGGER IF EXISTS trg_employees_seat_cap ON public.employees;
--   DROP FUNCTION IF EXISTS public.enforce_seat_cap_on_reactivate();
--   -- restore create_employee_auth_account from 20260623135907 (drops the
--   -- seat-cap block; keeps the escalation/permission gates).
-- =============================================================================

-- ── 1. Branch cap (RESTRICTIVE INSERT) ───────────────────────────────────────
DROP POLICY IF EXISTS branches_cap_insert ON public.branches;
CREATE POLICY branches_cap_insert ON public.branches
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (
    -- Only cap the caller's own tenant; cross-tenant is already blocked by the
    -- permissive tenant policy this ANDs with.
    business_id <> public.get_my_business_id()
    OR (SELECT el.max_branches FROM public.effective_limits() el) IS NULL
    OR (
      SELECT count(*) FROM public.branches b
      WHERE b.business_id = public.get_my_business_id()
    ) < (SELECT el.max_branches FROM public.effective_limits() el)
  );

-- ── 2. Seat cap: employees RESTRICTIVE INSERT (defense in depth) ─────────────
DROP POLICY IF EXISTS employees_cap_insert ON public.employees;
CREATE POLICY employees_cap_insert ON public.employees
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (
    business_id <> public.get_my_business_id()
    OR (SELECT el.max_seats FROM public.effective_limits() el) IS NULL
    OR (
      SELECT count(*) FROM public.employees e
      WHERE e.business_id = public.get_my_business_id() AND e.is_active IS TRUE
    ) < (SELECT el.max_seats FROM public.effective_limits() el)
  );

-- ── 3. Seat cap inside the provisioning RPC (the authoritative path) ─────────
-- Re-declares create_employee_auth_account with an added seat-cap check right
-- after the permission/escalation gates. Everything else is byte-identical to
-- 20260623135907 (the current definition).
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
  v_max_seats    INT;
  v_active_seats INT;
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

  -- ── Seat cap (M7.1 §6.2) — the authoritative check; RLS can't see this RPC.
  -- Only bites when creating a genuinely NEW auth user below (an existing user
  -- being re-linked, or p_employee_id repointing, doesn't add a seat).
  SELECT el.max_seats INTO v_max_seats
  FROM public.effective_limits_for(v_caller_biz) el;

  IF v_max_seats IS NOT NULL THEN
    SELECT count(*) INTO v_active_seats
    FROM public.employees e
    WHERE e.business_id = v_caller_biz AND e.is_active IS TRUE;

    IF v_active_seats >= v_max_seats THEN
      RAISE EXCEPTION 'SEAT_LIMIT_REACHED: plan allows % active seat(s)', v_max_seats;
    END IF;
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

-- ── 4. Reactivation re-check (suspend frees a seat; reactivate reclaims) ─────
CREATE OR REPLACE FUNCTION public.enforce_seat_cap_on_reactivate()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_max_seats    INT;
  v_active_seats INT;
BEGIN
  -- Only on a false→true transition.
  IF NEW.is_active IS TRUE AND OLD.is_active IS DISTINCT FROM TRUE THEN
    SELECT el.max_seats INTO v_max_seats
    FROM public.effective_limits_for(NEW.business_id) el;

    IF v_max_seats IS NOT NULL THEN
      SELECT count(*) INTO v_active_seats
      FROM public.employees e
      WHERE e.business_id = NEW.business_id AND e.is_active IS TRUE
        AND e.id <> NEW.id;

      IF v_active_seats >= v_max_seats THEN
        RAISE EXCEPTION 'SEAT_LIMIT_REACHED: plan allows % active seat(s)', v_max_seats;
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_employees_seat_cap ON public.employees;
CREATE TRIGGER trg_employees_seat_cap
  BEFORE UPDATE ON public.employees
  FOR EACH ROW EXECUTE FUNCTION public.enforce_seat_cap_on_reactivate();
