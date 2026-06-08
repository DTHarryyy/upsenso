-- Add an UPDATE policy to audit_logs so upsert/merge paths are never silently
-- blocked by RLS when no UPDATE policy exists.
-- Audit logs are append-only in practice, but PostgREST upsert always evaluates
-- the UPDATE path internally regardless of ignoreDuplicates.

CREATE POLICY audit_logs_update ON public.audit_logs
  FOR UPDATE TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);
