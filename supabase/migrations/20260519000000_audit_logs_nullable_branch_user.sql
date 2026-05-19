-- ============================================================
-- Make branch_id and user_id nullable in audit_logs.
--
-- Audit logs written by owners / global admins may not have a
-- specific branch context.  Sending an empty-string fallback as a
-- UUID is a parse error; NULL is the correct representation for
-- "no branch / no user attributable".
-- ============================================================

ALTER TABLE public.audit_logs
  ALTER COLUMN branch_id DROP NOT NULL,
  ALTER COLUMN user_id   DROP NOT NULL;

-- Update the insert policy to allow NULL user_id (e.g. system-level logs
-- from owners who have no specific branch/user context yet, or background
-- sync processes).  Non-null user_id must still match the caller's auth.uid().
DROP POLICY IF EXISTS "audit_logs_insert" ON public.audit_logs;

CREATE POLICY "audit_logs_insert"
  ON public.audit_logs
  FOR INSERT
  WITH CHECK (
    business_id = public.my_business_id()
    AND (user_id IS NULL OR user_id = auth.uid())
  );
