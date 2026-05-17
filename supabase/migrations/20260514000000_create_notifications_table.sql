-- =============================================================================
-- Upsenso POS — Notifications Table
-- =============================================================================
-- Creates the `notifications` table, a guard trigger that prevents clients
-- from mutating any field other than `is_read`, enables RLS, and adds
-- performance indexes.
--
-- Sections:
--   1  Table definition
--   2  Guard trigger  (only is_read may be updated by authenticated clients)
--   3  RLS enable
--   4  Policies
--   5  Indexes
-- =============================================================================


-- =============================================================================
-- 1 · TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.notifications (
  id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id    uuid        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id        uuid        REFERENCES public.users(id) ON DELETE SET NULL,
  type           text        NOT NULL
                               CHECK (type IN (
                                 'fraud',
                                 'low_stock',
                                 'sync_conflict',
                                 'expense_approval',
                                 'cash_discrepancy',
                                 'system'
                               )),
  severity       text        NOT NULL DEFAULT 'low'
                               CHECK (severity IN ('high', 'medium', 'low')),
  title          text        NOT NULL,
  body           text        NOT NULL DEFAULT '',
  is_read        boolean     NOT NULL DEFAULT false,
  reference_id   uuid,
  reference_type text,
  created_at     timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.notifications
  IS 'Business-scoped alert and notification inbox for the POS system.';

COMMENT ON COLUMN public.notifications.user_id
  IS 'NULL = broadcast to all business staff; non-null = personal notification for a specific user.';

COMMENT ON COLUMN public.notifications.type
  IS 'Category: fraud | low_stock | sync_conflict | expense_approval | cash_discrepancy | system.';

COMMENT ON COLUMN public.notifications.severity
  IS 'high | medium | low — drives icon colour and sort priority in the UI.';

COMMENT ON COLUMN public.notifications.reference_id
  IS 'Optional UUID of the entity that triggered this notification (e.g. a product, expense, or transaction).';

COMMENT ON COLUMN public.notifications.reference_type
  IS 'Table/entity name for reference_id, e.g. ''products'', ''expenses'', ''transactions''.';


-- =============================================================================
-- 2 · GUARD TRIGGER — only `is_read` may be mutated by clients
-- =============================================================================
-- Prevents any authenticated UPDATE from changing immutable columns.
-- The service role (backend / edge functions) bypasses RLS and triggers
-- by connecting with the Postgres superuser, so it is unaffected.

CREATE OR REPLACE FUNCTION public.notifications_guard_update()
  RETURNS trigger
  LANGUAGE plpgsql
  SET search_path = public
AS $$
BEGIN
  IF (
    NEW.business_id    IS DISTINCT FROM OLD.business_id    OR
    NEW.user_id        IS DISTINCT FROM OLD.user_id        OR
    NEW.type           IS DISTINCT FROM OLD.type           OR
    NEW.severity       IS DISTINCT FROM OLD.severity       OR
    NEW.title          IS DISTINCT FROM OLD.title          OR
    NEW.body           IS DISTINCT FROM OLD.body           OR
    NEW.reference_id   IS DISTINCT FROM OLD.reference_id   OR
    NEW.reference_type IS DISTINCT FROM OLD.reference_type OR
    NEW.created_at     IS DISTINCT FROM OLD.created_at
  ) THEN
    RAISE EXCEPTION
      'notifications: immutable fields cannot be changed; only is_read may be updated';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notifications_guard_update
  BEFORE UPDATE ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.notifications_guard_update();


-- =============================================================================
-- 3 · ENABLE RLS
-- =============================================================================

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;


-- =============================================================================
-- 4 · POLICIES
-- =============================================================================
-- Convention used throughout this project:
--   - Helper functions (my_business_id, i_am_super_admin) are SECURITY DEFINER
--     and never re-enter the policy they are called from, preventing recursion.
--   - No INSERT policy for `authenticated` → clients cannot create notifications.
--     Notifications are created exclusively by Postgres triggers, Edge Functions,
--     or backend jobs running under the service role.
-- =============================================================================

-- ── SELECT ────────────────────────────────────────────────────────────────────
-- Broadcast notifications (user_id IS NULL) are visible to all business staff.
-- Personal notifications (user_id = <uuid>) are visible only to the addressed
-- user and to Super Admins.
CREATE POLICY "notifications_select" ON public.notifications
  FOR SELECT TO authenticated
  USING (
    business_id = public.my_business_id()
    AND (
      user_id IS NULL               -- broadcast → whole business
      OR user_id = auth.uid()       -- personal → addressed user only
      OR public.i_am_super_admin()  -- Super Admin sees everything
    )
  );


-- ── INSERT ────────────────────────────────────────────────────────────────────
-- No policy for authenticated role.
-- service_role bypasses RLS entirely and is the only writer.


-- ── UPDATE ────────────────────────────────────────────────────────────────────
-- Any staff member may mark visible notifications as read.
-- The guard trigger above prevents changing any field other than is_read.
-- USING  : row must be visible to this user (same rules as SELECT)
-- WITH CHECK : new row must stay in the same business
CREATE POLICY "notifications_update" ON public.notifications
  FOR UPDATE TO authenticated
  USING (
    business_id = public.my_business_id()
    AND (
      user_id IS NULL
      OR user_id = auth.uid()
      OR public.i_am_super_admin()
    )
  )
  WITH CHECK (
    business_id = public.my_business_id()
  );


-- ── DELETE ────────────────────────────────────────────────────────────────────
-- Staff may dismiss broadcasts or their own personal notifications.
-- Super Admin may purge any notification in the business.
CREATE POLICY "notifications_delete" ON public.notifications
  FOR DELETE TO authenticated
  USING (
    business_id = public.my_business_id()
    AND (
      user_id IS NULL
      OR user_id = auth.uid()
      OR public.i_am_super_admin()
    )
  );


-- =============================================================================
-- 5 · INDEXES
-- =============================================================================

-- Primary query: all notifications for a business, newest first
CREATE INDEX IF NOT EXISTS idx_notifications_business_created
  ON public.notifications (business_id, created_at DESC);

-- Unread badge count (partial index — small, fast)
CREATE INDEX IF NOT EXISTS idx_notifications_unread
  ON public.notifications (business_id, is_read)
  WHERE is_read = false;

-- Personal notification lookup by user
CREATE INDEX IF NOT EXISTS idx_notifications_user
  ON public.notifications (user_id)
  WHERE user_id IS NOT NULL;

-- Filter by type (fraud dashboard, stock panel)
CREATE INDEX IF NOT EXISTS idx_notifications_type
  ON public.notifications (business_id, type);

-- Realtime filter match on business_id (used by the Flutter Realtime subscription)
CREATE INDEX IF NOT EXISTS idx_notifications_business_id
  ON public.notifications (business_id);
