-- =============================================================================
-- Make the duplicate-business signup bug structurally impossible.
--
-- Signup used to be FOUR separate round-trips from the client:
--   businesses INSERT → branches INSERT → apply_business_template() → users UPSERT
-- Each one auto-commits on its own. A failure after the first left a committed
-- business with no branch, no roles, no receipt_settings and no owner link — and
-- because the client minted a fresh Uuid().v4() per attempt, every retry created
-- ANOTHER one. See 20260731130001 for the 8 orphans this produced on 2026-07-26.
--
-- Three defences, weakest to strongest:
--   §1 my_business_id() is deterministic          — a multi-business owner can no
--                                                   longer get a different answer
--                                                   per call
--   §2 unique index on businesses(owner_id)       — a second row cannot exist
--   §3 create_business_onboarding()               — all four steps in ONE
--                                                   transaction, plus an
--                                                   idempotency guard, so a retry
--                                                   returns the existing business
--                                                   instead of making a new one
--
-- MUST run AFTER 20260731131524 — the unique index cannot build while the 8
-- duplicate rows are still present.
--
-- APPLIED to prod 2026-07-31.
--
-- ROLLBACK:
--   DROP FUNCTION IF EXISTS public.create_business_onboarding(uuid,text,uuid,text,text,text);
--   DROP INDEX IF EXISTS public.businesses_owner_id_key;
--   -- my_business_id(): re-apply the pre-existing body (identical except the
--   -- two ORDER BY created_at clauses).
-- =============================================================================

-- ── 1. Deterministic business resolution ─────────────────────────────────────
-- Was: two bare `LIMIT 1` subqueries with no ORDER BY, so for any user with more
-- than one candidate row Postgres could legitimately return a different id on
-- each call — and this feeds has_permission()'s owner fast-path and
-- effective_limits(). Body is otherwise byte-identical.
CREATE OR REPLACE FUNCTION public.my_business_id()
RETURNS uuid
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  SELECT COALESCE(
    (SELECT business_id FROM public.employees
     WHERE  auth_user_id = auth.uid() AND is_active = true
     ORDER  BY created_at LIMIT 1),
    (SELECT id FROM public.businesses
     WHERE  owner_id = auth.uid()
     ORDER  BY created_at LIMIT 1)
  );
$function$;

-- ── 2. One business per owner ────────────────────────────────────────────────
-- What my_business_id(), getBusinessByOwner() and ActiveBusinessContext have all
-- assumed since day one, now actually enforced. owner_id is NOT NULL, so there
-- is no null-multiplicity loophole. If multi-business is ever a product goal,
-- this index is the single thing to drop — and the three call sites above must
-- be reworked first.
CREATE UNIQUE INDEX IF NOT EXISTS businesses_owner_id_key
  ON public.businesses (owner_id);

-- ── 3. Atomic onboarding ─────────────────────────────────────────────────────
-- SECURITY DEFINER so the four writes happen as one unit without RLS refusing a
-- half-built business (the owner has no employees row until the very last step,
-- which is exactly the ordering trap that made this fragile). owner_id is forced
-- to auth.uid(), so a caller can never provision a business for someone else.
-- p_business_id / p_branch_id are minted CLIENT-side: the app is offline-first,
-- so the local Drift rows already exist under those ids and the server must
-- adopt them or the next sync would duplicate the branch.
CREATE OR REPLACE FUNCTION public.create_business_onboarding(
  p_business_id       uuid,
  p_name              text,
  p_template_id       uuid,
  p_branch_id         uuid,
  p_branch_name       text,
  p_full_name         text DEFAULT NULL,
  p_signup_device_uid text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid           uuid := auth.uid();
  v_business      public.businesses%ROWTYPE;
  v_branch_id     uuid;
  v_owner_role_id uuid;
  v_email         text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: sign in before creating a business'
      USING ERRCODE = '42501';
  END IF;

  IF p_name IS NULL OR btrim(p_name) = '' THEN
    RAISE EXCEPTION 'INVALID_NAME: business name is required'
      USING ERRCODE = '22023';
  END IF;

  -- Idempotency guard — the real fix. A retry (even carrying a fresh client-side
  -- uuid) gets back what already exists rather than minting a second business.
  SELECT * INTO v_business
  FROM public.businesses
  WHERE owner_id = v_uid
  ORDER BY created_at
  LIMIT 1;

  IF FOUND THEN
    SELECT id INTO v_branch_id FROM public.branches
     WHERE business_id = v_business.id ORDER BY created_at LIMIT 1;
    SELECT id INTO v_owner_role_id FROM public.roles
     WHERE business_id = v_business.id AND level = 1 LIMIT 1;

    RETURN jsonb_build_object(
      'business',      to_jsonb(v_business),
      'branch_id',     v_branch_id,
      'owner_role_id', v_owner_role_id,
      'reused',        true);
  END IF;

  -- From here to the end is a single transaction: any raise rolls back the
  -- business, the branch, everything apply_business_template() wrote, AND the
  -- rows the AFTER INSERT triggers added (trg_grant_initial_trial's subscription
  -- + subscription_events, trg_provision_modules' business_modules).
  INSERT INTO public.businesses
    (id, name, owner_id, template_id, is_active, signup_device_uid)
  VALUES
    (COALESCE(p_business_id, gen_random_uuid()), btrim(p_name), v_uid,
     p_template_id, true, p_signup_device_uid)
  RETURNING * INTO v_business;

  v_branch_id := COALESCE(p_branch_id, gen_random_uuid());
  INSERT INTO public.branches (id, business_id, name)
  VALUES (v_branch_id, v_business.id,
          COALESCE(NULLIF(btrim(p_branch_name), ''), 'Main Branch'));

  -- Creates the 4 roles + role permissions, enables the template's modules,
  -- seeds categories, initialises receipt_settings. Returns the level-1 role.
  v_owner_role_id := public.apply_business_template(
    v_business.id, p_template_id, v_branch_id);

  SELECT u.email INTO v_email FROM auth.users u WHERE u.id = v_uid;

  -- The auth signup trigger may already have made a minimal row (id + email).
  INSERT INTO public.users
    (id, business_id, email, full_name, role_id, branch_id, is_active)
  VALUES
    (v_uid, v_business.id, v_email, NULLIF(btrim(COALESCE(p_full_name, '')), ''),
     v_owner_role_id, v_branch_id, true)
  ON CONFLICT (id) DO UPDATE SET
    business_id = EXCLUDED.business_id,
    email       = COALESCE(EXCLUDED.email,     public.users.email),
    full_name   = COALESCE(EXCLUDED.full_name, public.users.full_name),
    role_id     = EXCLUDED.role_id,
    branch_id   = EXCLUDED.branch_id,
    is_active   = true;

  RETURN jsonb_build_object(
    'business',      to_jsonb(v_business),
    'branch_id',     v_branch_id,
    'owner_role_id', v_owner_role_id,
    'reused',        false);
END;
$$;

REVOKE ALL ON FUNCTION public.create_business_onboarding(uuid,text,uuid,uuid,text,text,text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.create_business_onboarding(uuid,text,uuid,uuid,text,text,text) TO authenticated;
