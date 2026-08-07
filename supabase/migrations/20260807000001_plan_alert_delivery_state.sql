     cv vc  -- Durable, service-only transition state for plan-limit FCM delivery.
CREATE TABLE IF NOT EXISTS public.plan_alert_delivery_state (
  business_id uuid NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  alert_kind text NOT NULL CHECK (alert_kind IN ('resource_over_cap', 'device_cap')),
  subject_key text NOT NULL DEFAULT '',
  is_active boolean NOT NULL DEFAULT false,
  signature text NOT NULL DEFAULT '',
  delivery_status text NOT NULL DEFAULT 'idle'
    CHECK (delivery_status IN ('idle', 'pending', 'sent')),
  attempt_count int NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  last_attempt_at timestamptz,
  last_sent_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, alert_kind, subject_key)
);

ALTER TABLE public.plan_alert_delivery_state ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.plan_alert_delivery_state FROM public, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.plan_alert_delivery_state TO service_role;

CREATE OR REPLACE FUNCTION public.claim_plan_alert_delivery(
  p_business uuid,
  p_alert_kind text,
  p_subject_key text,
  p_is_active boolean,
  p_signature text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.plan_alert_delivery_state%ROWTYPE;
BEGIN
  IF p_alert_kind NOT IN ('resource_over_cap', 'device_cap') THEN
    RAISE EXCEPTION 'INVALID_ALERT_KIND';
  END IF;

  -- Serialize concurrent webhook/client evaluations for the same condition.
  PERFORM pg_advisory_xact_lock(hashtextextended(
    p_business::text || ':' || p_alert_kind || ':' || COALESCE(p_subject_key, ''),
    0
  ));

  SELECT * INTO v_row
  FROM public.plan_alert_delivery_state
  WHERE business_id = p_business
    AND alert_kind = p_alert_kind
    AND subject_key = COALESCE(p_subject_key, '')
  FOR UPDATE;

  IF NOT p_is_active THEN
    INSERT INTO public.plan_alert_delivery_state
      (business_id, alert_kind, subject_key, is_active, signature,
       delivery_status, attempt_count, last_attempt_at, updated_at)
    VALUES
      (p_business, p_alert_kind, COALESCE(p_subject_key, ''), false,
       COALESCE(p_signature, ''), 'idle', 0, NULL, now())
    ON CONFLICT (business_id, alert_kind, subject_key) DO UPDATE SET
      is_active = false, signature = EXCLUDED.signature,
      delivery_status = 'idle', attempt_count = 0,
      last_attempt_at = NULL, updated_at = now();
    RETURN false;
  END IF;

  IF NOT FOUND OR NOT v_row.is_active THEN
    INSERT INTO public.plan_alert_delivery_state
      (business_id, alert_kind, subject_key, is_active, signature,
       delivery_status, attempt_count, last_attempt_at, updated_at)
    VALUES
      (p_business, p_alert_kind, COALESCE(p_subject_key, ''), true,
       COALESCE(p_signature, ''), 'pending', 1, now(), now())
    ON CONFLICT (business_id, alert_kind, subject_key) DO UPDATE SET
      is_active = true, signature = EXCLUDED.signature,
      delivery_status = 'pending', attempt_count = 1,
      last_attempt_at = now(), updated_at = now();
    RETURN true;
  END IF;

  IF v_row.delivery_status = 'pending'
     AND (v_row.last_attempt_at IS NULL OR v_row.last_attempt_at < now() - interval '5 minutes') THEN
    UPDATE public.plan_alert_delivery_state SET
      attempt_count = attempt_count + 1,
      last_attempt_at = now(),
      signature = COALESCE(p_signature, ''),
      updated_at = now()
    WHERE business_id = p_business
      AND alert_kind = p_alert_kind
      AND subject_key = COALESCE(p_subject_key, '');
    RETURN true;
  END IF;

  RETURN false;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_plan_alert_sent(
  p_business uuid,
  p_alert_kind text,
  p_subject_key text
)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE public.plan_alert_delivery_state SET
    delivery_status = 'sent', last_sent_at = now(), updated_at = now()
  WHERE business_id = p_business
    AND alert_kind = p_alert_kind
    AND subject_key = COALESCE(p_subject_key, '')
    AND is_active IS TRUE;
$$;

REVOKE ALL ON FUNCTION public.claim_plan_alert_delivery(uuid, text, text, boolean, text)
  FROM public, anon, authenticated;
REVOKE ALL ON FUNCTION public.mark_plan_alert_sent(uuid, text, text)
  FROM public, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.claim_plan_alert_delivery(uuid, text, text, boolean, text)
  TO service_role;
GRANT EXECUTE ON FUNCTION public.mark_plan_alert_sent(uuid, text, text)
  TO service_role;
