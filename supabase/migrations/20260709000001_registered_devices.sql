-- =============================================================================
-- M7.1 Phase 4 — device registration + cap (the plan's device meter, §3/§6.2).
--
-- A NEW table, deliberately NOT the existing `devices` audit-chain directory:
--   * `devices` (20260704000002) is a passive label directory whose INSERT is
--     open to any member and must NEVER fail — it's upserted on every audit
--     push. Retrofitting a cap onto it would break audit sync.
--   * `registered_devices` is a different lifecycle: online-only registration,
--     cap-enforced, revocable. Joined to the audit identity by device_uid
--     (DeviceIdentityService mints one uid per install, shared by both).
--
-- Registration is online-only BY CONSTRUCTION (it's an RPC — no offline path),
-- which is what bounds a paid account to its device cap (§6.3). SyncService
-- arms only when cloud is entitled AND this device is registered+unrevoked.
--
-- Writes are RPC-only (SECURITY DEFINER); no direct INSERT/UPDATE policy. The
-- cap check lives inside register_device where RLS can't be bypassed.
--
-- ROLLBACK:
--   DROP FUNCTION IF EXISTS public.register_device(text, text, text);
--   DROP FUNCTION IF EXISTS public.revoke_device(text);
--   DROP FUNCTION IF EXISTS public.touch_device(text);
--   -- restore get_my_entitlement from 20260707000001 (device_count = 0).
--   DROP TABLE IF EXISTS public.registered_devices;
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.registered_devices (
  device_uid    text PRIMARY KEY,   -- == DeviceIdentityService uid / devices.device_uid
  business_id   uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  label         text NOT NULL DEFAULT 'Device',
  platform      text NOT NULL DEFAULT 'unknown',
  registered_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at  timestamptz NOT NULL DEFAULT now(),
  revoked_at    timestamptz
);

CREATE INDEX IF NOT EXISTS idx_registered_devices_business
  ON public.registered_devices (business_id) WHERE revoked_at IS NULL;

ALTER TABLE public.registered_devices ENABLE ROW LEVEL SECURITY;

-- Read: owner/billing-manager sees the device list (revoke UI). No write
-- policy — the RPCs below are the only write path.
DROP POLICY IF EXISTS registered_devices_select ON public.registered_devices;
CREATE POLICY registered_devices_select ON public.registered_devices
  FOR SELECT TO authenticated
  USING (
    business_id = public.get_my_business_id()
    AND (public.has_permission('billing.view')
         OR public.has_permission('billing.manage'))
  );

-- ── register_device — online-only, cap-enforced, idempotent ─────────────────
-- Returns 'registered' | 'cap_reached' (caller stays local + prompts upgrade).
-- Re-registering an existing row refreshes last_seen_at and un-revokes only if
-- there's headroom. A brand-new device counts against max_devices + add-ons.
CREATE OR REPLACE FUNCTION public.register_device(
  p_device_uid text, p_label text DEFAULT 'Device', p_platform text DEFAULT 'unknown'
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_biz        uuid := public.get_my_business_id();
  v_max        int;
  v_active     int;
  v_existing   public.registered_devices%ROWTYPE;
BEGIN
  IF v_biz IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED';
  END IF;

  SELECT * INTO v_existing
  FROM public.registered_devices d
  WHERE d.device_uid = p_device_uid;

  -- Already registered to THIS business and live → just heartbeat.
  IF FOUND AND v_existing.business_id = v_biz AND v_existing.revoked_at IS NULL THEN
    UPDATE public.registered_devices
       SET last_seen_at = now(), label = p_label, platform = p_platform
     WHERE device_uid = p_device_uid;
    RETURN 'registered';
  END IF;

  -- A device_uid registered to a DIFFERENT business must re-home (device sold /
  -- account switched). Treat as new registration below after clearing it.
  SELECT el.max_devices INTO v_max FROM public.effective_limits_for(v_biz) el;

  IF v_max IS NOT NULL THEN
    SELECT count(*) INTO v_active
    FROM public.registered_devices d
    WHERE d.business_id = v_biz AND d.revoked_at IS NULL
      AND d.device_uid <> p_device_uid;
    IF v_active >= v_max THEN
      RETURN 'cap_reached';
    END IF;
  END IF;

  INSERT INTO public.registered_devices
    (device_uid, business_id, label, platform, registered_at, last_seen_at, revoked_at)
  VALUES (p_device_uid, v_biz, p_label, p_platform, now(), now(), NULL)
  ON CONFLICT (device_uid) DO UPDATE SET
    business_id   = v_biz,
    label         = EXCLUDED.label,
    platform      = EXCLUDED.platform,
    registered_at = now(),
    last_seen_at  = now(),
    revoked_at    = NULL;

  RETURN 'registered';
END;
$$;

REVOKE ALL ON FUNCTION public.register_device(text, text, text) FROM public;
GRANT EXECUTE ON FUNCTION public.register_device(text, text, text) TO authenticated;

-- ── revoke_device — frees a device slot (billing.manage) ────────────────────
CREATE OR REPLACE FUNCTION public.revoke_device(p_device_uid text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_biz uuid := public.get_my_business_id();
BEGIN
  IF NOT public.has_permission('billing.manage') THEN
    RAISE EXCEPTION 'UNAUTHORIZED: billing.manage required';
  END IF;
  UPDATE public.registered_devices
     SET revoked_at = now()
   WHERE device_uid = p_device_uid AND business_id = v_biz;
END;
$$;

REVOKE ALL ON FUNCTION public.revoke_device(text) FROM public;
GRANT EXECUTE ON FUNCTION public.revoke_device(text) TO authenticated;

-- ── touch_device — lightweight heartbeat (last_seen_at) ─────────────────────
CREATE OR REPLACE FUNCTION public.touch_device(p_device_uid text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.registered_devices
     SET last_seen_at = now()
   WHERE device_uid = p_device_uid
     AND business_id = public.get_my_business_id()
     AND revoked_at IS NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.touch_device(text) FROM public;
GRANT EXECUTE ON FUNCTION public.touch_device(text) TO authenticated;

-- ── Update get_my_entitlement to report the real device count ────────────────
CREATE OR REPLACE FUNCTION public.get_my_entitlement()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_biz    uuid := public.get_my_business_id();
  v_sub    public.subscriptions%ROWTYPE;
  v_status text := 'free';
  v_limits record;
BEGIN
  IF v_biz IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED';
  END IF;

  SELECT * INTO v_sub FROM public.subscriptions s WHERE s.business_id = v_biz;
  IF FOUND THEN
    v_status := public.effective_sub_status(v_sub);
  END IF;

  SELECT * INTO v_limits FROM public.effective_limits();

  RETURN jsonb_build_object(
    'business_id',         v_biz,
    'plan_code',           COALESCE(v_sub.plan_code, 'free'),
    'plan_version',        COALESCE(v_sub.plan_version, 1),
    'status',              v_status,
    'billing_period',      v_sub.billing_period,
    'trial_end',           v_sub.trial_end,
    'current_period_end',  v_sub.current_period_end,
    'grace_until',         v_sub.grace_until,
    'grandfathered_price', v_sub.grandfathered_price,
    'cloud_enabled',       COALESCE(v_limits.cloud_enabled, false),
    'max_branches',        v_limits.max_branches,
    'max_seats',           v_limits.max_seats,
    'max_devices',         v_limits.max_devices,
    'feature_flags',       COALESCE(v_limits.feature_flags, '{}'::jsonb),
    'device_addons',       COALESCE(v_sub.device_addons, 0),
    'branch_addons',       COALESCE(v_sub.branch_addons, 0),
    'seat_addons',         COALESCE(v_sub.seat_addons, 0),
    'usage', jsonb_build_object(
      'branch_count',
        (SELECT count(*) FROM public.branches b WHERE b.business_id = v_biz),
      'active_seat_count',
        (SELECT count(*) FROM public.employees e
          WHERE e.business_id = v_biz AND e.is_active IS TRUE),
      'device_count',
        (SELECT count(*) FROM public.registered_devices d
          WHERE d.business_id = v_biz AND d.revoked_at IS NULL)
    ),
    'server_time', now()
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_my_entitlement() FROM public;
GRANT EXECUTE ON FUNCTION public.get_my_entitlement() TO authenticated, service_role;
