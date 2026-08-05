-- =============================================================================
-- Owner manager-PIN support.
--
-- Business owners never get a row in `employees` (deliberate — see
-- my_business_id()'s COALESCE-to-businesses.owner_id fallback and
-- has_permission()'s owner fast path). set_manager_pin()/authorize_refund() from
-- 20260627000013_refund_approval_foundation.sql never accounted for that: an
-- owner calling set_manager_pin() to set their OWN PIN hit
-- `get_my_employee_id() IS NULL` -> "No employee to set a PIN for".
--
-- Fix: store the owner's PIN on businesses.owner_pin_hash instead of employees,
-- and teach authorize_refund()/enforce_refund_approval() to recognise an
-- owner-issued authorization alongside employee-issued ones. Deliberately NOT
-- giving owners an employees row — that would inflate seat/employee counts
-- (get_my_entitlement(), employees_cap_insert RLS) and break the client's
-- "no employees row = literal owner" detection (employees_page._isLiteralOwner,
-- employees_repository_impl._actingAsLiteralOwner).
--
-- No new lockout columns needed: authorize_refund()'s brute-force lockout is
-- already tracked on the CALLER's employees.pin_auth_attempts (the device
-- attempting authorisation), independent of whose PIN is being tried.
--
-- ROLLBACK:
--   ALTER TABLE refund_authorizations DROP CONSTRAINT refund_auth_authorizer_chk,
--     DROP COLUMN authorized_by_owner, ALTER COLUMN authorized_by SET NOT NULL
--     (safe only if no authorized_by_owner=true rows exist yet);
--   ALTER TABLE businesses DROP COLUMN owner_pin_hash;
--   CREATE OR REPLACE the three functions below with their bodies from
--   20260627000013_refund_approval_foundation.sql.
-- =============================================================================

ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS owner_pin_hash text;

ALTER TABLE public.refund_authorizations
  ALTER COLUMN authorized_by DROP NOT NULL,
  ADD COLUMN IF NOT EXISTS authorized_by_owner boolean NOT NULL DEFAULT false;

ALTER TABLE public.refund_authorizations
  DROP CONSTRAINT IF EXISTS refund_auth_authorizer_chk;
ALTER TABLE public.refund_authorizations
  ADD CONSTRAINT refund_auth_authorizer_chk CHECK (
    (authorized_by IS NOT NULL AND NOT authorized_by_owner) OR
    (authorized_by IS NULL AND authorized_by_owner)
  );

-- ── set_manager_pin(): owner (no employees row) falls back to businesses ────
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
    IF v_target IS NULL THEN
      IF EXISTS (SELECT 1 FROM businesses b WHERE b.id = v_biz AND b.owner_id = auth.uid()) THEN
        UPDATE businesses
           SET owner_pin_hash = extensions.crypt(p_pin, extensions.gen_salt('bf'))
         WHERE id = v_biz;
        RETURN;
      END IF;
      RAISE EXCEPTION 'No employee to set a PIN for';
    END IF;
  ELSE
    IF NOT (i_am_super_admin()
            OR EXISTS (SELECT 1 FROM businesses b WHERE b.id = v_biz AND b.owner_id = auth.uid())) THEN
      RAISE EXCEPTION 'Only owners/admins may set another employee''s PIN';
    END IF;
    v_target := p_employee_id;
  END IF;

  UPDATE employees
     SET manager_pin_hash      = extensions.crypt(p_pin, extensions.gen_salt('bf')),
         pin_auth_attempts     = 0,
         pin_auth_locked_until = NULL
   WHERE id = v_target AND business_id = v_biz;
END;
$$;

-- ── authorize_refund(): try employee PIN, then owner PIN ────────────────────
CREATE OR REPLACE FUNCTION public.authorize_refund(
  p_pin text, p_transaction_id uuid, p_amount numeric)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_biz uuid; v_caller uuid; v_approver uuid; v_owner_match boolean; v_auth_id uuid;
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
    SELECT true INTO v_owner_match
    FROM   businesses b
    WHERE  b.id = v_biz AND b.owner_pin_hash IS NOT NULL
      AND  b.owner_pin_hash = extensions.crypt(p_pin, b.owner_pin_hash);
  END IF;

  IF v_approver IS NULL AND NOT coalesce(v_owner_match, false) THEN
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

  INSERT INTO refund_authorizations
    (business_id, transaction_id, authorized_by, authorized_by_owner, max_amount)
  VALUES (v_biz, p_transaction_id, v_approver, coalesce(v_owner_match, false), p_amount)
  RETURNING id INTO v_auth_id;
  RETURN v_auth_id;
END;
$$;

-- ── enforce_refund_approval(): consumption now honours authorized_by_owner ──
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

  -- Otherwise consume a manager (or owner) authorization for this transaction + amount.
  SELECT * INTO v_auth
  FROM   refund_authorizations
  WHERE  transaction_id = NEW.transaction_id AND NOT consumed
    AND  max_amount >= NEW.total_amount
    AND  (authorized_by_owner OR public.employee_has_permission(authorized_by, 'pos.approve_refund'))
  ORDER  BY created_at
  LIMIT  1
  FOR UPDATE SKIP LOCKED;

  IF v_auth.id IS NULL THEN
    RAISE EXCEPTION 'REFUND_APPROVAL_REQUIRED: a manager must authorise this refund'
      USING errcode = 'check_violation';
  END IF;

  UPDATE refund_authorizations SET consumed = true, consumed_refund_id = NEW.id WHERE id = v_auth.id;
  NEW.approved_by := v_auth.authorized_by;
  NEW.approved_at := now();
  NEW.approval_method := CASE WHEN v_auth.authorized_by_owner THEN 'owner_pin' ELSE 'manager_pin' END;
  RETURN NEW;
END;
$$;
