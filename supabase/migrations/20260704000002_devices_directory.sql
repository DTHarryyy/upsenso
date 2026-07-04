-- =============================================================================
-- Device directory (normalization, 2026-07-03 fix plan §4c)
--
-- One row per audit chain identity (device_uid). The human label used to be
-- repeated on every audit_logs row and flapped between "Web · chrome" /
-- "Web · safari" for a single physical device; it now lives here once. Audit
-- rows keep device_uid as the reference (kept as text, not a hard FK, so a
-- lagging device row can never block an audit push).
--
-- Access mirrors audit_logs.verify: a device directory reveals how many
-- installs a business runs and their platforms, so it is owner/verify-gated,
-- not readable by cashiers.
--
-- ROLLBACK:
--   DROP TABLE IF EXISTS public.devices;   -- (drops its policies with it)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.devices (
  device_uid     text PRIMARY KEY,
  business_id    uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  label          text NOT NULL,
  platform       text NOT NULL DEFAULT 'unknown',
  first_seen_at  timestamptz NOT NULL DEFAULT now(),
  last_seen_at   timestamptz NOT NULL DEFAULT now(),
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_devices_business ON public.devices (business_id);

ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;

-- INSERT/UPDATE: any authenticated member of the business may register/refresh
-- its own device (the client upserts on every audit write). Scoped to the
-- caller's business so one tenant can't write another's directory.
DROP POLICY IF EXISTS devices_write_own_business ON public.devices;
CREATE POLICY devices_write_own_business ON public.devices
  FOR INSERT TO authenticated
  WITH CHECK (business_id = public.get_my_business_id());

DROP POLICY IF EXISTS devices_update_own_business ON public.devices;
CREATE POLICY devices_update_own_business ON public.devices
  FOR UPDATE TO authenticated
  USING (business_id = public.get_my_business_id())
  WITH CHECK (business_id = public.get_my_business_id());

-- SELECT: owner/verify only, matching the audit directory sensitivity.
DROP POLICY IF EXISTS devices_select_verify ON public.devices;
CREATE POLICY devices_select_verify ON public.devices
  FOR SELECT TO authenticated
  USING (
    business_id = public.get_my_business_id()
    AND public.has_permission('audit_logs.verify')
  );
