-- =============================================================================
-- Harden has_permission() into the single, correct authorization oracle for RLS.
--
-- 20260623000001 made it SECURITY DEFINER (fixing the 42501 grant error). This
-- migration fixes the remaining correctness/consistency gaps that surfaced once
-- the function could actually read role_permissions again:
--
--   1. OWNER BYPASS. Businesses are operated by their owner (businesses.owner_id)
--      who has no employees row. The old function only traversed
--      employees->employee_roles->role_permissions, so it returned false for
--      every owner -> every permission-gated procurement write was denied.
--      my_business_id() already has an owner fallback; this aligns has_permission
--      with it and with the documented "Owner = all permissions" rule. The bypass
--      is scoped to my_business_id() so an owner of one business never inherits
--      rights in a business where they are only a staff member.
--
--   2. CANONICAL AUTH COLUMN. Join on employees.auth_user_id (the real auth.uid()
--      column per 20260608000014), not the legacy user_id that a trigger backfills.
--      Matches my_business_id() / get_my_permissions().
--
--   3. HONOUR rp.allowed. role_permissions.allowed can be false (explicit deny);
--      the old function checked row existence only, so a deny would grant. Now
--      requires allowed = true, matching get_my_permissions().
--
--   4. RESPECT is_active. Deactivated employees must lose all permissions.
--
-- Behaviour for an active employee with genuine grants is unchanged. Body stays
-- SECURITY DEFINER with search_path pinned to public; EXECUTE re-asserted to the
-- authenticated roles only (declarative).
--
-- Rollback: restore the prior definition from 20260623000001 (user_id join,
-- no owner bypass, no allowed/is_active filters).
-- =============================================================================

create or replace function public.has_permission(permission_code text)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $function$
  -- Owner of the active business holds every permission within it.
  select exists (
    select 1 from businesses b
    where b.id = my_business_id()
      and b.owner_id = auth.uid()
  )
  or exists (
    select 1
    from employees e
    join employee_roles   er on er.employee_id = e.id
    join role_permissions rp on rp.role_id     = er.role_id
    join permissions      p  on p.id           = rp.permission_id
    where e.auth_user_id = auth.uid()
      and e.is_active is true
      and rp.allowed   is true
      and p.code = permission_code
  );
$function$;

revoke execute on function public.has_permission(text) from public;
grant  execute on function public.has_permission(text) to authenticated, service_role;
