-- Fix: business owners cannot read their own audit_logs.
--
-- audit_admin_only (SELECT) gated on:
--   business_id = get_my_business_id() AND current_user_role() = ANY('{owner,admin}')
-- current_user_role() resolves role via employees -> employee_roles -> roles
-- keyed on auth.uid(). Owners have no employees row (see
-- 20260626154405_fix_owner_fallback_role_name_label.sql and app-side handling
-- in PermissionService), so current_user_role() returns NULL for an owner and
-- the policy denies them — owners get zero rows from this table today.
--
-- Fix: swap the role check for i_am_super_admin(), the helper already used
-- elsewhere (e.g. can_read_all_branches() in 20260627000014) specifically
-- because it covers both cases: businesses.owner_id = auth.uid() (no employees
-- row needed) OR an active employee whose role name is
-- admin/owner/super admin/superadmin. It is a strict superset of the old
-- check, so this only grants reads owners should already have — it narrows
-- nothing for the admin-employee case that already worked.
--
-- This is a direct replace (not a bolted-on second policy) because
-- audit_admin_only is SELECT-only, not FOR ALL — there is no shared
-- USING/WITH CHECK to entangle with write behavior (contrast with the
-- bolt-on approach in 20260627000014, which was needed because those
-- policies are FOR ALL).
--
-- ROLLBACK:
--   drop policy if exists audit_admin_only on public.audit_logs;
--   create policy audit_admin_only on public.audit_logs
--     for select to authenticated
--     using (
--       business_id = get_my_business_id()
--       and current_user_role() = any (array['owner', 'admin'])
--     );

drop policy if exists audit_admin_only on public.audit_logs;
create policy audit_admin_only on public.audit_logs
  for select to authenticated
  using (
    business_id = public.get_my_business_id()
    and public.i_am_super_admin()
  );
