-- =============================================================================
-- Stage 2a — audit_logs legacy-column convergence (APPLIED via connector 2026-07-04)
--
-- Source-of-truth note: applied directly through the Supabase connector (the
-- supabase/migrations/ chain is historically drifted and is NOT authoritative).
-- This file is the human-readable record of exactly what was applied.
--
-- WHY: audit_logs had two writer conventions — the app writes (user_id,
-- action_type, description) + the hash chain; the log_permission_change() trigger
-- wrote the legacy (employee_id, action) with no action_type/description. This
-- converges the trigger onto the app's convention so the legacy columns can go.
-- The audit viewer (_fromRemoteRow) was updated in the SAME change to stop
-- reading `action`. Trigger rows stay UNCHAINED (server-attested stream; a
-- device hash chain can't include server-side rows) — by design.
--
-- CLIENT (same release):
--   lib/features/audit_logs/data/repositories/audit_log_repository_impl.dart
--   _fromRemoteRow no longer falls back to row['action'].
--
-- ROLLBACK:
--   ALTER TABLE public.audit_logs ADD COLUMN action text;
--   ALTER TABLE public.audit_logs ADD COLUMN employee_id uuid REFERENCES public.employees(id);
--   (and restore the previous log_permission_change() body writing employee_id/action)
-- =============================================================================

-- 1) Converge the trigger onto the app convention (user_id + action_type + description).
CREATE OR REPLACE FUNCTION public.log_permission_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
  INSERT INTO audit_logs (
    id, business_id, user_id, action_type, entity_type, entity_id, description, metadata, created_at
  )
  VALUES (
    gen_random_uuid(),
    COALESCE(NEW.business_id, OLD.business_id),
    auth.uid()::text,                       -- matches app user_id (auth uid as text)
    'PERMISSION_TABLE_CHANGED',             -- = AuditLogActionType.permissionTableChanged
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),               -- uuid on all three permission tables
    TG_OP || ' on ' || TG_TABLE_NAME,       -- human description (was the viewer's fallback)
    jsonb_build_object('old', to_jsonb(OLD), 'new', to_jsonb(NEW)),
    now()
  );
  RETURN COALESCE(NEW, OLD);
END;
$function$;

-- 2) Drop the now-dead legacy columns (no writer, no reader after the above).
ALTER TABLE public.audit_logs DROP COLUMN IF EXISTS action;
ALTER TABLE public.audit_logs DROP COLUMN IF EXISTS employee_id;
