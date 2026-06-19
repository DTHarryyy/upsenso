-- Fix cross-tenant audit-log forgery (INSERT) and tampering (UPDATE).
-- Previously both policies allowed any authenticated user to write any
-- business's audit rows (with check was only `auth.uid() IS NOT NULL`).
-- Rollback:
--   drop policy audit_logs_insert on public.audit_logs;
--   create policy audit_logs_insert on public.audit_logs for insert to authenticated
--     with check (auth.uid() is not null);
--   drop policy audit_logs_update on public.audit_logs;
--   create policy audit_logs_update on public.audit_logs for update to authenticated
--     using (auth.uid() is not null) with check (auth.uid() is not null);

drop policy if exists audit_logs_insert on public.audit_logs;
create policy audit_logs_insert on public.audit_logs
  for insert to authenticated
  with check (business_id = public.get_my_business_id());

drop policy if exists audit_logs_update on public.audit_logs;
create policy audit_logs_update on public.audit_logs
  for update to authenticated
  using (business_id = public.get_my_business_id())
  with check (business_id = public.get_my_business_id());
