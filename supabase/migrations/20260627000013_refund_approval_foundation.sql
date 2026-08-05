-- =============================================================================
-- Refund approval — Phase 1 (server foundation). Inline manager-PIN auth,
-- threshold-gated. OFF by default (refund_settings.require_approval = false) so
-- the existing refund flow is unchanged until a business opts in.
--
-- Pieces:
--   refund_settings              per-business toggle + money threshold
--   employees.manager_pin_hash   bcrypt PIN + caller attempt lockout columns
--   refunds.approved_by/_at/_method  who authorised an over-threshold refund
--   refund_authorizations        single-use, tx+amount-scoped server-issued grant
--   employee_has_permission()    resolve a permission for a SPECIFIC employee
--   set_manager_pin()            self/admin set a bcrypt PIN (server-only)
--   authorize_refund()           verify a manager PIN -> issue an authorization
--   enforce_refund_approval()    BEFORE INSERT trigger: over-threshold refunds
--                                must be self-approved (caller holds
--                                approve_refund) or consume a valid authorisation
--
-- Tamper model: a client cannot fabricate an authorisation without the PIN
-- (authorize_refund is SECURITY DEFINER and verifies bcrypt server-side). Over-
-- threshold refunds therefore need connectivity at refund time; under-threshold
-- refunds remain fully offline.
--
-- ROLLBACK: drop the trigger, the three functions, refund_authorizations,
--   refund_settings; ALTER TABLE refunds/employees DROP the added columns.
-- =============================================================================

-- ── refund_settings ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.refund_settings (
  business_id        uuid PRIMARY KEY REFERENCES businesses(id) ON DELETE CASCADE,
  require_approval    boolean NOT NULL DEFAULT false,
  approval_threshold  numeric NOT NULL DEFAULT 0,
  updated_at          timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.refund_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS refund_settings_read ON public.refund_settings;
CREATE POLICY refund_settings_read ON public.refund_settings
  FOR SELECT USING (business_id = get_my_business_id());

DROP POLICY IF EXISTS refund_settings_write ON public.refund_settings;
CREATE POLICY refund_settings_write ON public.refund_settings
  FOR ALL
  USING  (business_id = get_my_business_id() AND has_permission('settings.edit_business'))
  WITH CHECK (business_id = get_my_business_id() AND has_permission('settings.edit_business'));

DROP TRIGGER IF EXISTS trg_refund_settings_updated_at ON public.refund_settings;
CREATE TRIGGER trg_refund_settings_updated_at
  BEFORE UPDATE ON public.refund_settings
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ── employees: manager PIN + caller attempt lockout ─────────────────────────
ALTER TABLE public.employees
  ADD COLUMN IF NOT EXISTS manager_pin_hash      text,
  ADD COLUMN IF NOT EXISTS pin_auth_attempts     int NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS pin_auth_locked_until timestamptz;

-- ── refunds: approval provenance ────────────────────────────────────────────
ALTER TABLE public.refunds
  ADD COLUMN IF NOT EXISTS approved_by     uuid REFERENCES employees(id),
  ADD COLUMN IF NOT EXISTS approved_at     timestamptz,
  ADD COLUMN IF NOT EXISTS approval_method text;

-- ── refund_authorizations: single-use server-issued grant ───────────────────
CREATE TABLE IF NOT EXISTS public.refund_authorizations (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id        uuid NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  transaction_id     uuid NOT NULL,
  authorized_by      uuid NOT NULL REFERENCES employees(id),
  max_amount         numeric NOT NULL,
  consumed           boolean NOT NULL DEFAULT false,
  consumed_refund_id uuid,
  created_at         timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_refund_auth_lookup
  ON public.refund_authorizations(transaction_id, consumed);
ALTER TABLE public.refund_authorizations ENABLE ROW LEVEL SECURITY;
-- Read-only to business members; writes happen ONLY via the SECURITY DEFINER
-- functions below (which bypass RLS). No write policy = clients can't write.
DROP POLICY IF EXISTS refund_auth_read ON public.refund_authorizations;
CREATE POLICY refund_auth_read ON public.refund_authorizations
  FOR SELECT USING (business_id = get_my_business_id());

-- ── employee_has_permission(): resolve a permission for a SPECIFIC employee ─
CREATE OR REPLACE FUNCTION public.employee_has_permission(p_employee_id uuid, p_code text)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT CASE
    WHEN EXISTS (SELECT 1 FROM user_permissions up JOIN permissions p ON p.id = up.permission_id
      WHERE up.employee_id = p_employee_id AND p.code = p_code AND up.is_granted = false
        AND up.is_active AND (up.expires_at IS NULL OR up.expires_at > now())) THEN false
    WHEN EXISTS (SELECT 1 FROM user_permissions up JOIN permissions p ON p.id = up.permission_id
      WHERE up.employee_id = p_employee_id AND p.code = p_code AND up.is_granted = true
        AND up.is_active AND (up.expires_at IS NULL OR up.expires_at > now())) THEN true
    WHEN EXISTS (SELECT 1 FROM employee_roles er JOIN role_permissions rp ON rp.role_id = er.role_id
      JOIN permissions p ON p.id = rp.permission_id
      WHERE er.employee_id = p_employee_id AND rp.allowed AND p.code = p_code) THEN true
    ELSE false
  END;
$$;

-- ── set_manager_pin(): self, or admin/owner sets another's ──────────────────
CREATE OR REPLACE FUNCTION public.set_manager_pin(p_pin text, p_employee_id uuid DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_biz uuid; v_target uuid;
BEGIN
  v_biz := my_business_id();
  IF v_biz IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  IF p_pin !~ '^[0-9]{4,6}$' THEN RAISE EXCEPTION 'PIN must be 4 to 6 digits'; END IF;

  IF p_employee_id IS NULL THEN
    v_target := get_my_employee_id();
  ELSE
    IF NOT (i_am_super_admin()
            OR EXISTS (SELECT 1 FROM businesses b WHERE b.id = v_biz AND b.owner_id = auth.uid())) THEN
      RAISE EXCEPTION 'Only owners/admins may set another employee''s PIN';
    END IF;
    v_target := p_employee_id;
  END IF;
  IF v_target IS NULL THEN RAISE EXCEPTION 'No employee to set a PIN for'; END IF;

  UPDATE employees
     SET manager_pin_hash      = extensions.crypt(p_pin, extensions.gen_salt('bf')),
         pin_auth_attempts     = 0,
         pin_auth_locked_until = NULL
   WHERE id = v_target AND business_id = v_biz;
END;
$$;

-- ── authorize_refund(): verify a manager PIN, issue an authorization ────────
CREATE OR REPLACE FUNCTION public.authorize_refund(
  p_pin text, p_transaction_id uuid, p_amount numeric)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_biz uuid; v_caller uuid; v_approver uuid; v_auth_id uuid;
BEGIN
  v_biz := my_business_id();
  IF v_biz IS NULL THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  v_caller := get_my_employee_id();

  -- Brute-force lockout on the CALLER (the device attempting authorisations).
  IF v_caller IS NOT NULL AND EXISTS (
    SELECT 1 FROM employees WHERE id = v_caller
      AND pin_auth_locked_until IS NOT NULL AND pin_auth_locked_until > now()
  ) THEN
    RAISE EXCEPTION 'LOCKED: too many attempts, try again later';
  END IF;

  SELECT e.id INTO v_approver
  FROM   employees e
  WHERE  e.business_id = v_biz AND e.is_active AND e.manager_pin_hash IS NOT NULL
    AND  e.manager_pin_hash = extensions.crypt(p_pin, e.manager_pin_hash)
    AND  public.employee_has_permission(e.id, 'pos.approve_refund')
  LIMIT  1;

  IF v_approver IS NULL THEN
    IF v_caller IS NOT NULL THEN
      UPDATE employees
         SET pin_auth_attempts = pin_auth_attempts + 1,
             pin_auth_locked_until = CASE WHEN pin_auth_attempts + 1 >= 5
                                          THEN now() + interval '15 minutes'
                                          ELSE pin_auth_locked_until END
       WHERE id = v_caller;
    END IF;
    RAISE EXCEPTION 'INVALID_PIN';
  END IF;

  IF v_caller IS NOT NULL THEN
    UPDATE employees SET pin_auth_attempts = 0, pin_auth_locked_until = NULL WHERE id = v_caller;
  END IF;

  INSERT INTO refund_authorizations (business_id, transaction_id, authorized_by, max_amount)
  VALUES (v_biz, p_transaction_id, v_approver, p_amount)
  RETURNING id INTO v_auth_id;
  RETURN v_auth_id;
END;
$$;

-- ── enforce_refund_approval(): the gate ─────────────────────────────────────
CREATE OR REPLACE FUNCTION public.enforce_refund_approval()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_require boolean; v_threshold numeric; v_caller uuid; v_auth refund_authorizations%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN RETURN NEW; END IF;
  -- Business owner: full authority.
  IF EXISTS (SELECT 1 FROM businesses b WHERE b.id = NEW.business_id AND b.owner_id = auth.uid()) THEN
    NEW.approval_method := coalesce(NEW.approval_method, 'owner');
    RETURN NEW;
  END IF;

  SELECT require_approval, approval_threshold INTO v_require, v_threshold
  FROM refund_settings WHERE business_id = NEW.business_id;

  IF NOT coalesce(v_require, false) THEN RETURN NEW; END IF;            -- feature off
  IF NEW.total_amount <= coalesce(v_threshold, 0) THEN RETURN NEW; END IF; -- under threshold

  v_caller := get_my_employee_id();
  -- Self-approval: the refunder themselves holds approve_refund.
  IF v_caller IS NOT NULL AND public.employee_has_permission(v_caller, 'pos.approve_refund') THEN
    NEW.approved_by := v_caller; NEW.approved_at := now(); NEW.approval_method := 'self';
    RETURN NEW;
  END IF;

  -- Otherwise consume a manager authorization for this transaction + amount.
  SELECT * INTO v_auth
  FROM   refund_authorizations
  WHERE  transaction_id = NEW.transaction_id AND NOT consumed
    AND  max_amount >= NEW.total_amount
    AND  public.employee_has_permission(authorized_by, 'pos.approve_refund')
  ORDER  BY created_at
  LIMIT  1
  FOR UPDATE SKIP LOCKED;

  IF v_auth.id IS NULL THEN
    RAISE EXCEPTION 'REFUND_APPROVAL_REQUIRED: a manager must authorise this refund'
      USING errcode = 'check_violation';
  END IF;

  UPDATE refund_authorizations SET consumed = true, consumed_refund_id = NEW.id WHERE id = v_auth.id;
  NEW.approved_by := v_auth.authorized_by; NEW.approved_at := now(); NEW.approval_method := 'manager_pin';
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_refund_approval ON public.refunds;
CREATE TRIGGER trg_enforce_refund_approval
  BEFORE INSERT ON public.refunds
  FOR EACH ROW EXECUTE FUNCTION enforce_refund_approval();

-- Grants: RPCs callable by authenticated; internal helper not exposed to anon.
REVOKE EXECUTE ON FUNCTION public.set_manager_pin(text, uuid)            FROM public;
REVOKE EXECUTE ON FUNCTION public.authorize_refund(text, uuid, numeric)  FROM public;
GRANT  EXECUTE ON FUNCTION public.set_manager_pin(text, uuid)            TO authenticated;
GRANT  EXECUTE ON FUNCTION public.authorize_refund(text, uuid, numeric)  TO authenticated;
