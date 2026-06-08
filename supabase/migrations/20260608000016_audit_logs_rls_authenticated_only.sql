-- Simplify audit_logs INSERT policy to only require authentication.
-- Read access is already restricted by the audit_admin_only SELECT policy
-- (owner/admin roles only). Write access just needs a valid session — the
-- business_id association is enforced at the app layer, not the DB layer.

DROP POLICY IF EXISTS audit_logs_employee_insert ON public.audit_logs;
DROP POLICY IF EXISTS audit_logs_insert_system ON public.audit_logs;

CREATE POLICY audit_logs_insert ON public.audit_logs
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);
