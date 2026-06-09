-- =============================================================================
-- UPSENSO — Normalize and secure the notifications table
-- =============================================================================
-- The table already exists but is critically under-defined:
--   • Missing 8 columns the Flutter app reads/writes
--   • Zero GRANTs to `authenticated` → every PostgREST query fails with 42501
--   • Single FOR ALL policy scoped to `public` role (includes anon) — insecure
--   • No updated_at, no soft-delete, no type/severity columns
--   • employee_id (FK to employees) should be user_id (FK to auth.users) so
--     the realtime subscription can filter by auth.uid() without a join
--
-- This migration is purely additive + policy replacement — no columns removed,
-- no data lost.
-- =============================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Add missing columns
-- ─────────────────────────────────────────────────────────────────────────────

-- The app reads `body` not `message`. Keep `message` for now (additive-only
-- rule), but add `body` as the canonical column. A later cleanup migration
-- can drop `message` once all callers are migrated.
ALTER TABLE public.notifications
  -- auth.users FK — scopes notification to one employee's auth identity.
  -- NULL = business-wide, visible to all owner/admin users.
  ADD COLUMN IF NOT EXISTS user_id        uuid          REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Notification category and urgency.
  ADD COLUMN IF NOT EXISTS type           text          NOT NULL DEFAULT 'system',
  ADD COLUMN IF NOT EXISTS severity       text          NOT NULL DEFAULT 'low',

  -- Canonical body column (app reads `body`; `message` column left in place).
  ADD COLUMN IF NOT EXISTS body           text          NOT NULL DEFAULT '',

  -- Optional deep-link to the entity that triggered this notification.
  ADD COLUMN IF NOT EXISTS reference_id   text,
  ADD COLUMN IF NOT EXISTS reference_type text,

  -- Soft-delete (CLAUDE.md: never hard-delete business data).
  ADD COLUMN IF NOT EXISTS is_deleted     boolean       NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS deleted_at     timestamptz,

  -- Offline-first sync contract: updated_at required on every synced entity.
  ADD COLUMN IF NOT EXISTS updated_at     timestamptz   NOT NULL DEFAULT now();


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Tighten existing columns
-- ─────────────────────────────────────────────────────────────────────────────

-- is_read was nullable — semantically it is always true or false.
ALTER TABLE public.notifications
  ALTER COLUMN is_read SET NOT NULL,
  ALTER COLUMN is_read SET DEFAULT false;

-- created_at was nullable — it should always be set.
ALTER TABLE public.notifications
  ALTER COLUMN created_at SET NOT NULL,
  ALTER COLUMN created_at SET DEFAULT now();


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Backfill new columns for any existing rows
-- ─────────────────────────────────────────────────────────────────────────────

-- Populate `body` from `message` for rows that existed before this migration.
UPDATE public.notifications
SET body = COALESCE(message, '')
WHERE body = '';

-- Populate user_id from the employee's auth_user_id so existing rows are
-- correctly scoped (employee_id → employees.auth_user_id → auth.users.id).
UPDATE public.notifications n
SET    user_id = e.auth_user_id
FROM   public.employees e
WHERE  e.id       = n.employee_id
  AND  n.user_id  IS NULL
  AND  n.employee_id IS NOT NULL;


-- ─────────────────────────────────────────────────────────────────────────────
-- 4. CHECK constraints for enum safety
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check,
  DROP CONSTRAINT IF EXISTS notifications_severity_check,
  DROP CONSTRAINT IF EXISTS notifications_reference_check;

ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_type_check CHECK (
    type IN ('fraud', 'low_stock', 'sync_conflict', 'expense_approval',
             'cash_discrepancy', 'system')
  ),
  ADD CONSTRAINT notifications_severity_check CHECK (
    severity IN ('high', 'medium', 'low')
  ),
  -- reference_id and reference_type must both be set or both be NULL.
  ADD CONSTRAINT notifications_reference_check CHECK (
    (reference_id IS NULL) = (reference_type IS NULL)
  );


-- ─────────────────────────────────────────────────────────────────────────────
-- 5. updated_at auto-maintenance trigger
-- ─────────────────────────────────────────────────────────────────────────────

DROP TRIGGER IF EXISTS trg_notifications_updated_at ON public.notifications;
CREATE TRIGGER trg_notifications_updated_at
  BEFORE UPDATE ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Indexes
-- ─────────────────────────────────────────────────────────────────────────────

-- Primary list query: all non-deleted notifications for a business, newest first.
CREATE INDEX IF NOT EXISTS idx_notifications_business_created
  ON public.notifications (business_id, created_at DESC)
  WHERE is_deleted = false;

-- Unread badge count.
CREATE INDEX IF NOT EXISTS idx_notifications_business_unread
  ON public.notifications (business_id, is_read)
  WHERE is_read = false AND is_deleted = false;

-- Per-user filtering (auth.uid() lookup).
CREATE INDEX IF NOT EXISTS idx_notifications_user
  ON public.notifications (user_id)
  WHERE user_id IS NOT NULL AND is_deleted = false;

-- Type-based tab filtering.
CREATE INDEX IF NOT EXISTS idx_notifications_type
  ON public.notifications (business_id, type)
  WHERE is_deleted = false;


-- ─────────────────────────────────────────────────────────────────────────────
-- 7. Replace RLS policies
-- ─────────────────────────────────────────────────────────────────────────────
-- Old policy: biz_isolation_notifications — FOR ALL, role=public, no WITH CHECK.
-- Issues:
--   a. `public` role includes `anon` — unauthenticated users could hit RLS.
--   b. FOR ALL with no WITH CHECK means INSERT/UPDATE bypass the write check.
--   c. No per-employee scoping — any business employee saw all notifications.
-- Replace with explicit per-operation policies on `authenticated` only.

DROP POLICY IF EXISTS biz_isolation_notifications ON public.notifications;

-- SELECT: owner/admin sees all; employee sees own + business-wide (user_id NULL).
CREATE POLICY notifications_select
  ON public.notifications
  FOR SELECT
  TO authenticated
  USING (
    business_id = my_business_id()
    AND is_deleted = false
    AND (
      i_am_super_admin()
      OR user_id IS NULL
      OR user_id = auth.uid()
    )
  );

-- INSERT: owner/admin only (backend service role bypasses RLS entirely).
CREATE POLICY notifications_insert
  ON public.notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (
    business_id = my_business_id()
    AND i_am_super_admin()
  );

-- UPDATE: owner/admin can update anything; employee can only mark their own as read.
CREATE POLICY notifications_update
  ON public.notifications
  FOR UPDATE
  TO authenticated
  USING (
    business_id = my_business_id()
    AND is_deleted = false
    AND (
      i_am_super_admin()
      OR user_id = auth.uid()
    )
  )
  WITH CHECK (
    business_id = my_business_id()
    AND (
      i_am_super_admin()
      OR user_id = auth.uid()
    )
  );

-- DELETE: intentionally no policy — soft-delete only via is_deleted.
-- The repository's delete() must UPDATE is_deleted=true, not issue a DELETE.


-- ─────────────────────────────────────────────────────────────────────────────
-- 8. GRANTs
-- ─────────────────────────────────────────────────────────────────────────────

-- Strip anon access entirely.
REVOKE ALL ON public.notifications FROM anon, public;

-- Authenticated: SELECT + INSERT + UPDATE allowed; RLS enforces row-level scope.
-- DELETE withheld — soft-delete only.
GRANT SELECT, INSERT, UPDATE ON public.notifications TO authenticated;


-- ─────────────────────────────────────────────────────────────────────────────
-- 9. Register in modules seed
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO public.modules (code, name, description, icon, sort_order, is_system)
VALUES ('notifications', 'Notifications', 'Business alerts and system notifications', 'notifications', 12, true)
ON CONFLICT (code) DO UPDATE SET
  name        = EXCLUDED.name,
  description = EXCLUDED.description,
  icon        = EXCLUDED.icon,
  sort_order  = EXCLUDED.sort_order,
  is_system   = EXCLUDED.is_system;


-- ─────────────────────────────────────────────────────────────────────────────
-- 10. Enable Realtime publication
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE  pubname    = 'supabase_realtime'
      AND  schemaname = 'public'
      AND  tablename  = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 11. Reload PostgREST schema cache
-- ─────────────────────────────────────────────────────────────────────────────

SELECT pg_notify('pgrst', 'reload schema');

COMMIT;
