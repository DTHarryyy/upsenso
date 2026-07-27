-- =============================================================================
-- M7.1 Phase 1 — Billing foundation: plans, subscriptions, entitlement engine.
--
-- Design: docs/UPSENSO_SUBSCRIPTION_AND_LIMITS_DESIGN.md (v3, 2026-07-06).
-- The paywall is the cloud (§3): Free is local-only, paid tiers buy sync +
-- devices + branches + seats. This migration ships the *server* half only —
-- schema, seeds, the entitlement oracle (has_cloud_access), and the 14-day
-- "cloud's on us" trial trigger (§4.4). It is deliberately inert for current
-- clients: billing_settings.cloud_gate_enforced defaults to FALSE, so
-- has_cloud_access() returns true for everyone until the entitlement-aware
-- client ships (Phase 3 flips the flag — that flip is the deploy gate).
--
-- Key decisions (§4.9 grandfathering):
--   * plans is versioned (PK code,version). Repricing = new version for new
--     customers; existing subscriptions keep resolving their pinned version.
--   * subscriptions carries entitlement_snapshot jsonb — price + limits +
--     feature_flags frozen at purchase. effective_limits() reads the snapshot
--     + addon columns, NEVER live plan rows, so a catalog edit can't touch an
--     existing customer.
--   * Annual price is never stored: always price_monthly × 10 (2 months free,
--     §5.1) — one rule, no drift.
--   * subscription_events is hash-chained (M1 pattern, 20260703000002):
--     canonical = business_id|seq|event_type|actor|payload::text|created_at,
--     hash = sha256(prev_hash || '|' || canonical) hex. Append-only (no
--     UPDATE/DELETE policies); UNIQUE(business_id, seq) blocks forks.
--   * All subscription/limit WRITES are service-role only (§8): the billing
--     tables have zero authenticated write policies. Grants happen through
--     admin_grant_subscription (20260707000002) — called identically by a
--     human admin and the PayMongo webhook.
--   * One trial per device (anti-farming): businesses.signup_device_uid is
--     recorded into trial_claims at trial start; a reused uid gets
--     trial_end = now() (lands on Free immediately, nothing is blocked).
--
-- ROLLBACK:
--   DROP TRIGGER  IF EXISTS trg_grant_initial_trial ON public.businesses;
--   DROP FUNCTION IF EXISTS public.grant_initial_trial();
--   DROP FUNCTION IF EXISTS public.get_my_entitlement();
--   DROP FUNCTION IF EXISTS public.has_cloud_access();
--   DROP FUNCTION IF EXISTS public.effective_limits();
--   DROP FUNCTION IF EXISTS public.effective_limits_for(uuid);
--   DROP FUNCTION IF EXISTS public.effective_sub_status(public.subscriptions);
--   DROP FUNCTION IF EXISTS public.record_subscription_event(uuid, text, text, jsonb);
--   DROP TABLE IF EXISTS public.trial_claims;
--   DROP TABLE IF EXISTS public.billing_webhook_events;
--   DROP TABLE IF EXISTS public.billing_payments;
--   DROP TABLE IF EXISTS public.subscription_events;
--   DROP TABLE IF EXISTS public.subscriptions;
--   DROP TABLE IF EXISTS public.plan_addons;
--   DROP TABLE IF EXISTS public.plan_limits;
--   DROP TABLE IF EXISTS public.plans;
--   DROP TABLE IF EXISTS public.billing_settings;
--   ALTER TABLE public.businesses DROP COLUMN IF EXISTS signup_device_uid;
-- =============================================================================

-- ── 1. billing_settings — singleton enforcement switch ───────────────────────
CREATE TABLE IF NOT EXISTS public.billing_settings (
  id                  int  PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  -- FALSE = has_cloud_access() passes everyone (pre-entitlement clients keep
  -- working). Flipped to TRUE manually once the Phase 2/3 client is released.
  cloud_gate_enforced boolean NOT NULL DEFAULT false,
  trial_days          int     NOT NULL DEFAULT 14,
  updated_at          timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public.billing_settings (id) VALUES (1)
ON CONFLICT (id) DO NOTHING;

-- ── 2. Plan catalog (versioned) ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.plans (
  code          text    NOT NULL,
  version       int     NOT NULL,
  name          text    NOT NULL,
  -- Annual is DERIVED (price_monthly × 10, discount_months_free = 2). Never stored.
  price_monthly numeric NOT NULL CHECK (price_monthly >= 0),
  is_active     boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (code, version)
);

CREATE TABLE IF NOT EXISTS public.plan_limits (
  plan_code     text    NOT NULL,
  plan_version  int     NOT NULL,
  cloud_enabled boolean NOT NULL,
  -- NULL limit = unlimited (enterprise).
  max_branches  int,
  max_seats     int,
  max_devices   int,
  feature_flags jsonb   NOT NULL DEFAULT '{}'::jsonb,
  PRIMARY KEY (plan_code, plan_version),
  FOREIGN KEY (plan_code, plan_version) REFERENCES public.plans (code, version)
);

CREATE TABLE IF NOT EXISTS public.plan_addons (
  code          text    PRIMARY KEY CHECK (code IN ('device', 'branch', 'seat')),
  name          text    NOT NULL,
  price_monthly numeric NOT NULL CHECK (price_monthly >= 0),
  unit_qty      int     NOT NULL DEFAULT 1,
  is_active     boolean NOT NULL DEFAULT true
);

-- ── 3. Subscriptions (one per business; service-role writes only) ────────────
CREATE TABLE IF NOT EXISTS public.subscriptions (
  business_id          uuid PRIMARY KEY REFERENCES public.businesses (id) ON DELETE CASCADE,
  plan_code            text NOT NULL,
  plan_version         int  NOT NULL,
  billing_period       text NOT NULL DEFAULT 'monthly'
                       CHECK (billing_period IN ('monthly', 'annual')),
  -- Price + limits + feature_flags pinned at grant time (§4.9). The oracle
  -- functions below resolve from THIS, never from live plans/plan_limits.
  entitlement_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  device_addons        int  NOT NULL DEFAULT 0 CHECK (device_addons >= 0),
  branch_addons        int  NOT NULL DEFAULT 0 CHECK (branch_addons >= 0),
  seat_addons          int  NOT NULL DEFAULT 0 CHECK (seat_addons  >= 0),
  status               text NOT NULL
                       CHECK (status IN ('trialing', 'active', 'past_due', 'canceled')),
  current_period_start timestamptz,
  current_period_end   timestamptz,
  trial_end            timestamptz,
  grace_until          timestamptz,
  -- Signup price kept for life while subscribed (§4.9 #1).
  grandfathered_price  numeric,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now()
);

-- ── 4. subscription_events — append-only, hash-chained (M1 pattern) ──────────
CREATE TABLE IF NOT EXISTS public.subscription_events (
  id            uuid   PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id   uuid   NOT NULL,
  seq           bigint NOT NULL,
  event_type    text   NOT NULL,
  actor         text   NOT NULL,   -- 'webhook' | 'admin' | 'system'
  payload       jsonb  NOT NULL DEFAULT '{}'::jsonb,
  previous_hash text,
  hash          text   NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (business_id, seq)
);

-- ── 5. Payments + webhook idempotency ledger ─────────────────────────────────
CREATE TABLE IF NOT EXISTS public.billing_payments (
  id           uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id  uuid    NOT NULL REFERENCES public.businesses (id) ON DELETE CASCADE,
  provider     text    NOT NULL DEFAULT 'paymongo',
  provider_ref text    UNIQUE,      -- checkout session / payment intent id
  kind         text    NOT NULL CHECK (kind IN ('plan', 'addon')),
  plan_code    text,
  plan_version int,
  billing_period text,
  addon_code   text,
  addon_qty    int,
  amount       numeric NOT NULL CHECK (amount >= 0),
  currency     text    NOT NULL DEFAULT 'PHP',
  status       text    NOT NULL DEFAULT 'pending'
               CHECK (status IN ('pending', 'paid', 'failed', 'expired')),
  is_test      boolean NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now(),
  paid_at      timestamptz
);

CREATE INDEX IF NOT EXISTS idx_billing_payments_business
  ON public.billing_payments (business_id);

CREATE TABLE IF NOT EXISTS public.billing_webhook_events (
  provider_event_id text PRIMARY KEY,
  received_at       timestamptz NOT NULL DEFAULT now(),
  payload           jsonb
);

-- ── 6. Trial anti-farming: one trial per signup device ───────────────────────
CREATE TABLE IF NOT EXISTS public.trial_claims (
  device_uid  text PRIMARY KEY,
  business_id uuid NOT NULL,
  claimed_at  timestamptz NOT NULL DEFAULT now()
);

-- Nullable + additive: the client stamps its DeviceIdentityService uid at
-- business creation (Phase 2 wiring). NULL (older clients) fails open — trial
-- granted; the guard only tightens once new clients send it.
ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS signup_device_uid text;

-- ── 7. RLS ────────────────────────────────────────────────────────────────────
ALTER TABLE public.billing_settings       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plans                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_limits            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_addons            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_events    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.billing_payments       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.billing_webhook_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trial_claims           ENABLE ROW LEVEL SECURITY;

-- Catalog + settings: world-readable to signed-in users (the plan picker),
-- never writable from the client.
DROP POLICY IF EXISTS billing_settings_select ON public.billing_settings;
CREATE POLICY billing_settings_select ON public.billing_settings
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS plans_select ON public.plans;
CREATE POLICY plans_select ON public.plans
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS plan_limits_select ON public.plan_limits;
CREATE POLICY plan_limits_select ON public.plan_limits
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS plan_addons_select ON public.plan_addons;
CREATE POLICY plan_addons_select ON public.plan_addons
  FOR SELECT TO authenticated USING (true);

-- Tenant-scoped reads; NO write policies (service-role only, §8).
DROP POLICY IF EXISTS subscriptions_select_own ON public.subscriptions;
CREATE POLICY subscriptions_select_own ON public.subscriptions
  FOR SELECT TO authenticated
  USING (business_id = public.get_my_business_id());

DROP POLICY IF EXISTS subscription_events_select_own ON public.subscription_events;
CREATE POLICY subscription_events_select_own ON public.subscription_events
  FOR SELECT TO authenticated
  USING (business_id = public.get_my_business_id());

DROP POLICY IF EXISTS billing_payments_select_own ON public.billing_payments;
CREATE POLICY billing_payments_select_own ON public.billing_payments
  FOR SELECT TO authenticated
  USING (business_id = public.get_my_business_id());

-- billing_webhook_events / trial_claims: no policies at all — service-role
-- and definer functions only.

-- ── 8. Hash-chained event writer ─────────────────────────────────────────────
-- Canonical form (documented contract, verified by the client):
--   business_id|seq|event_type|actor|payload::text|created_at(ISO)
--   hash = sha256(coalesce(previous_hash,'') || '|' || canonical) hex
-- Serialized per business via an advisory xact lock so seq can't race/fork.
CREATE OR REPLACE FUNCTION public.record_subscription_event(
  p_business uuid, p_type text, p_actor text, p_payload jsonb DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = extensions, public
AS $$
DECLARE
  v_prev_seq  bigint;
  v_prev_hash text;
  v_seq       bigint;
  v_now       timestamptz := now();
  v_canonical text;
  v_hash      text;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtext('sub_events:' || p_business::text));

  SELECT e.seq, e.hash INTO v_prev_seq, v_prev_hash
  FROM public.subscription_events e
  WHERE e.business_id = p_business
  ORDER BY e.seq DESC
  LIMIT 1;

  v_seq := COALESCE(v_prev_seq, 0) + 1;
  v_canonical := p_business::text || '|' || v_seq::text || '|' || p_type || '|'
              || p_actor || '|' || p_payload::text || '|'
              || to_char(v_now AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"');
  v_hash := encode(digest(COALESCE(v_prev_hash, '') || '|' || v_canonical, 'sha256'), 'hex');

  INSERT INTO public.subscription_events
    (business_id, seq, event_type, actor, payload, previous_hash, hash, created_at)
  VALUES
    (p_business, v_seq, p_type, p_actor, p_payload, v_prev_hash, v_hash, v_now);
END;
$$;

REVOKE ALL ON FUNCTION public.record_subscription_event(uuid, text, text, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.record_subscription_event(uuid, text, text, jsonb) TO service_role;

-- ── 9. Status oracle — pure timestamp math, no cron needed ───────────────────
-- 'active'   : paid period still running (canceled keeps access to period end)
-- 'past_due' : period over but inside grace (full access, escalating banners)
-- 'trialing' : inside the 14-day cloud-on-us window, never paid yet
-- 'free'     : never paid (or trial over) on the free plan
-- 'lapsed'   : paid before, grace exhausted — behaves as free-local (§7.3)
CREATE OR REPLACE FUNCTION public.effective_sub_status(s public.subscriptions)
RETURNS text
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT CASE
    WHEN s.current_period_end IS NOT NULL AND now() <= s.current_period_end
      THEN 'active'
    WHEN s.grace_until IS NOT NULL AND now() <= s.grace_until
         AND s.current_period_end IS NOT NULL AND s.status <> 'canceled'
      THEN 'past_due'
    WHEN s.status = 'trialing' AND s.trial_end IS NOT NULL AND now() < s.trial_end
      THEN 'trialing'
    WHEN s.current_period_end IS NULL
      THEN 'free'
    ELSE 'lapsed'
  END;
$$;

REVOKE ALL ON FUNCTION public.effective_sub_status(public.subscriptions) FROM public;
GRANT EXECUTE ON FUNCTION public.effective_sub_status(public.subscriptions)
  TO authenticated, service_role;

-- ── 10. Effective limits — snapshot + add-ons, never live plan rows ──────────
-- Free/lapsed resolve from the live free-plan limits (we only ever RAISE free,
-- §4.2); everything else resolves from the pinned snapshot (§4.9). Add-on
-- columns extend the caps. The `_for(uuid)` variant exists for triggers,
-- which must key off the ROW's business, not the caller's context.
CREATE OR REPLACE FUNCTION public.effective_limits_for(p_business uuid)
RETURNS TABLE (
  cloud_enabled boolean, max_branches int, max_seats int, max_devices int,
  feature_flags jsonb
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sub    public.subscriptions%ROWTYPE;
  v_status text;
BEGIN
  SELECT * INTO v_sub
  FROM public.subscriptions s
  WHERE s.business_id = p_business;

  IF FOUND THEN
    v_status := public.effective_sub_status(v_sub);
  END IF;

  IF FOUND AND v_status IN ('trialing', 'active', 'past_due') THEN
    RETURN QUERY SELECT
      COALESCE((v_sub.entitlement_snapshot ->> 'cloud_enabled')::boolean, false),
      CASE WHEN v_sub.entitlement_snapshot ? 'max_branches'
           AND (v_sub.entitlement_snapshot ->> 'max_branches') IS NOT NULL
        THEN (v_sub.entitlement_snapshot ->> 'max_branches')::int + v_sub.branch_addons
        ELSE NULL END,
      CASE WHEN v_sub.entitlement_snapshot ? 'max_seats'
           AND (v_sub.entitlement_snapshot ->> 'max_seats') IS NOT NULL
        THEN (v_sub.entitlement_snapshot ->> 'max_seats')::int + v_sub.seat_addons
        ELSE NULL END,
      CASE WHEN v_sub.entitlement_snapshot ? 'max_devices'
           AND (v_sub.entitlement_snapshot ->> 'max_devices') IS NOT NULL
        THEN (v_sub.entitlement_snapshot ->> 'max_devices')::int + v_sub.device_addons
        ELSE NULL END,
      COALESCE(v_sub.entitlement_snapshot -> 'feature_flags', '{}'::jsonb);
  ELSE
    -- free / lapsed / no row at all
    RETURN QUERY SELECT
      pl.cloud_enabled, pl.max_branches, pl.max_seats, pl.max_devices, pl.feature_flags
    FROM public.plan_limits pl
    WHERE pl.plan_code = 'free' AND pl.plan_version = 1;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.effective_limits()
RETURNS TABLE (
  cloud_enabled boolean, max_branches int, max_seats int, max_devices int,
  feature_flags jsonb
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT * FROM public.effective_limits_for(public.get_my_business_id());
$$;

REVOKE ALL ON FUNCTION public.effective_limits_for(uuid) FROM public;
GRANT EXECUTE ON FUNCTION public.effective_limits_for(uuid) TO authenticated, service_role;
REVOKE ALL ON FUNCTION public.effective_limits() FROM public;
GRANT EXECUTE ON FUNCTION public.effective_limits() TO authenticated, service_role;

-- ── 11. The cloud gate — the single oracle the RESTRICTIVE RLS will call ─────
-- STABLE ⇒ policies written as (SELECT public.has_cloud_access()) evaluate
-- once per statement (InitPlan), not per row. While cloud_gate_enforced is
-- false this is a constant TRUE — zero behavior change for shipped clients.
CREATE OR REPLACE FUNCTION public.has_cloud_access()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    NOT COALESCE((SELECT bs.cloud_gate_enforced FROM public.billing_settings bs WHERE bs.id = 1), false)
    OR EXISTS (
      SELECT 1
      FROM public.subscriptions s
      WHERE s.business_id = public.get_my_business_id()
        AND public.effective_sub_status(s) IN ('trialing', 'active', 'past_due')
        AND COALESCE((s.entitlement_snapshot ->> 'cloud_enabled')::boolean, false)
    );
$$;

REVOKE ALL ON FUNCTION public.has_cloud_access() FROM public;
GRANT EXECUTE ON FUNCTION public.has_cloud_access() TO authenticated, service_role;

-- ── 12. One-round-trip entitlement fetch for the client cache ────────────────
-- device_count is 0 until Phase 4 introduces registered_devices (this function
-- is replaced there). server_time anchors the client's clock-tamper clamp.
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
      'device_count', 0
    ),
    'server_time', now()
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_my_entitlement() FROM public;
GRANT EXECUTE ON FUNCTION public.get_my_entitlement() TO authenticated, service_role;

-- ── 13. Trial trigger — every new business gets "cloud's on us" (§4.4) ───────
-- Snapshot = Starter limits (the trial IS a Starter taste) but plan_code stays
-- 'free': when the trial lapses, effective_sub_status lands on 'free' with no
-- further transition needed. A reused signup device gets trial_end = now()
-- (immediately 'free') — nothing is blocked, they just don't re-taste the cloud.
CREATE OR REPLACE FUNCTION public.grant_initial_trial()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_days     int;
  v_snapshot jsonb;
  v_reused   boolean := false;
BEGIN
  IF EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.business_id = NEW.id) THEN
    RETURN NEW;   -- idempotent (backfill / re-fire safety)
  END IF;

  SELECT bs.trial_days INTO v_days FROM public.billing_settings bs WHERE bs.id = 1;
  v_days := COALESCE(v_days, 14);

  IF NEW.signup_device_uid IS NOT NULL THEN
    v_reused := EXISTS (
      SELECT 1 FROM public.trial_claims tc WHERE tc.device_uid = NEW.signup_device_uid
    );
  END IF;

  SELECT jsonb_build_object(
           'plan_code', 'starter', 'plan_version', pl.plan_version,
           'price_monthly', p.price_monthly,
           'cloud_enabled', pl.cloud_enabled,
           'max_branches', pl.max_branches, 'max_seats', pl.max_seats,
           'max_devices', pl.max_devices, 'feature_flags', pl.feature_flags,
           'source', 'trial')
  INTO v_snapshot
  FROM public.plan_limits pl
  JOIN public.plans p ON p.code = pl.plan_code AND p.version = pl.plan_version
  WHERE pl.plan_code = 'starter' AND pl.plan_version = 1;

  INSERT INTO public.subscriptions
    (business_id, plan_code, plan_version, status, trial_end,
     entitlement_snapshot, grandfathered_price)
  VALUES
    (NEW.id, 'free', 1, 'trialing',
     CASE WHEN v_reused THEN now() ELSE now() + make_interval(days => v_days) END,
     COALESCE(v_snapshot, '{}'::jsonb), 0);

  IF NOT v_reused AND NEW.signup_device_uid IS NOT NULL THEN
    INSERT INTO public.trial_claims (device_uid, business_id)
    VALUES (NEW.signup_device_uid, NEW.id)
    ON CONFLICT (device_uid) DO NOTHING;
  END IF;

  PERFORM public.record_subscription_event(
    NEW.id,
    CASE WHEN v_reused THEN 'trial_denied_device_reuse' ELSE 'trial_started' END,
    'system',
    jsonb_build_object('trial_days', CASE WHEN v_reused THEN 0 ELSE v_days END,
                       'signup_device_uid', NEW.signup_device_uid));
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_grant_initial_trial ON public.businesses;
CREATE TRIGGER trg_grant_initial_trial
  AFTER INSERT ON public.businesses
  FOR EACH ROW EXECUTE FUNCTION public.grant_initial_trial();

-- ── 14. Seeds — plans v1 per the §4 tier table ───────────────────────────────
INSERT INTO public.plans (code, version, name, price_monthly, is_active) VALUES
  ('free',       1, 'Free',       0,    true),
  ('starter',    1, 'Starter',    199,  true),
  ('growth',     1, 'Growth',     499,  true),
  -- Defined, not launched (§4): switched on when M6/M7.2 ship.
  ('business',   1, 'Business',   1299, false),
  ('enterprise', 1, 'Enterprise', 0,    false)
ON CONFLICT (code, version) DO NOTHING;

INSERT INTO public.plan_limits
  (plan_code, plan_version, cloud_enabled, max_branches, max_seats, max_devices, feature_flags)
VALUES
  ('free',       1, false, 1,    2,    1,
   '{"crm": false,  "procurement": false, "reports": "basic", "cloud_audit": false}'),
  ('starter',    1, true,  1,    3,    2,
   '{"crm": "basic", "procurement": false, "reports": "basic", "cloud_audit": true}'),
  ('growth',     1, true,  3,    10,   5,
   '{"crm": "full",  "procurement": true,  "reports": "full",  "cloud_audit": true}'),
  ('business',   1, true,  10,   50,   20,
   '{"crm": "full",  "procurement": true,  "reports": "full",  "cloud_audit": true, "accounting": true, "multi_currency": true}'),
  ('enterprise', 1, true,  NULL, NULL, NULL,
   '{"crm": "full",  "procurement": true,  "reports": "full",  "cloud_audit": true, "accounting": true, "multi_currency": true}')
ON CONFLICT (plan_code, plan_version) DO NOTHING;

INSERT INTO public.plan_addons (code, name, price_monthly, unit_qty) VALUES
  ('device', 'Extra device', 49, 1),
  ('branch', 'Extra branch', 99, 1),
  ('seat',   'Extra seat',   29, 1)
ON CONFLICT (code) DO NOTHING;

-- ── 15. Backfill — any pre-existing business gets the standard trial ─────────
-- (Prod is at zero tenants post 2026-07-04 reset; this covers dev/staging and
-- any signup that lands between migration batches.)
DO $$
DECLARE
  b RECORD;
BEGIN
  FOR b IN
    SELECT bz.id, bz.signup_device_uid
    FROM public.businesses bz
    WHERE NOT EXISTS (SELECT 1 FROM public.subscriptions s WHERE s.business_id = bz.id)
  LOOP
    INSERT INTO public.subscriptions
      (business_id, plan_code, plan_version, status, trial_end,
       entitlement_snapshot, grandfathered_price)
    SELECT b.id, 'free', 1, 'trialing',
           now() + make_interval(days => (SELECT trial_days FROM public.billing_settings WHERE id = 1)),
           jsonb_build_object(
             'plan_code', 'starter', 'plan_version', 1,
             'price_monthly', p.price_monthly, 'cloud_enabled', pl.cloud_enabled,
             'max_branches', pl.max_branches, 'max_seats', pl.max_seats,
             'max_devices', pl.max_devices, 'feature_flags', pl.feature_flags,
             'source', 'backfill'),
           0
    FROM public.plan_limits pl
    JOIN public.plans p ON p.code = pl.plan_code AND p.version = pl.plan_version
    WHERE pl.plan_code = 'starter' AND pl.plan_version = 1;

    PERFORM public.record_subscription_event(
      b.id, 'trial_started', 'system', '{"source": "backfill"}'::jsonb);
  END LOOP;
END;
$$;
