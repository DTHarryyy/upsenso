-- =============================================================================
-- Phase 3 — route a submitted PO to its approvers via a notification.
--
-- Audit (2026-06-15) Scenario A gap: when a creator submits a PO it just sits in
-- 'submitted' with nobody told. notifications.* already exists but client INSERT
-- requires i_am_super_admin() (notifications are created server-side), so the
-- correct, offline-first approach is a trigger: when a PO enters 'submitted'
-- (on the synced upsert), insert one notification per active approver.
--
-- Offline-first: no RPC; fires on the normal Drift→Supabase upsert.
-- Best-effort: the insert is wrapped so a notification failure can NEVER roll
-- back / block the PO write itself.
-- =============================================================================

BEGIN;

-- 1. Allow the new notification type (existing constraint omits it).
ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_type_check CHECK (
    type IN ('fraud', 'low_stock', 'sync_conflict', 'expense_approval',
             'po_approval', 'cash_discrepancy', 'system')
  );

-- 2. Trigger function: notify approvers when a PO becomes 'submitted'.
CREATE OR REPLACE FUNCTION public.notify_po_approvers()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only fire on the transition INTO 'submitted' — not on a re-sync of an
  -- already-submitted PO (avoids duplicate notifications).
  IF NEW.status <> 'submitted' THEN
    RETURN NEW;
  END IF;
  IF TG_OP = 'UPDATE' AND OLD.status = 'submitted' THEN
    RETURN NEW;
  END IF;

  -- Best-effort: never let a notification problem roll back the PO write.
  BEGIN
    INSERT INTO public.notifications (
      id, business_id, user_id, type, severity, title, body,
      reference_id, reference_type, is_read, created_at, updated_at
    )
    SELECT
      gen_random_uuid(),
      NEW.business_id,
      e.user_id,
      'po_approval',
      'medium',
      'Purchase order awaiting approval',
      COALESCE(NEW.po_number, 'A purchase order')
        || ' from ' || COALESCE(NEW.supplier_name, 'a supplier')
        || ' needs your approval.',
      NEW.id::text,
      'purchase_order',
      false,
      now(),
      now()
    FROM   employees        e
    JOIN   employee_roles   er ON er.employee_id = e.id
    JOIN   roles            r  ON r.id  = er.role_id
    JOIN   role_permissions  rp ON rp.role_id = r.id
    JOIN   permissions       p  ON p.id  = rp.permission_id
    WHERE  e.business_id = NEW.business_id
      AND  e.is_active   = true
      AND  e.user_id     IS NOT NULL
      AND  p.code        = 'procurement.approve_po';
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'notify_po_approvers failed for PO %: %', NEW.id, SQLERRM;
  END;

  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.notify_po_approvers() FROM anon, public;

-- 3. Attach the trigger (status column changes + new inserts).
DROP TRIGGER IF EXISTS trg_notify_po_approvers ON public.purchase_orders;
CREATE TRIGGER trg_notify_po_approvers
  AFTER INSERT OR UPDATE OF status ON public.purchase_orders
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_po_approvers();

SELECT pg_notify('pgrst', 'reload schema');

COMMIT;
