-- =============================================================================
-- Fix: has_permission() must run SECURITY DEFINER.
--
-- has_permission() is the shared RLS helper behind every permission-gated
-- procurement policy (po_biz_isolation, gr_biz_isolation, gri_biz_isolation,
-- proc_settings_write). It reads role_permissions, but was defined
-- SECURITY INVOKER, so it executed with the caller's (authenticated) privileges.
--
-- 20260619000006 revoked SELECT on role_permissions from authenticated on the
-- (incorrect) assumption that the table is only read via SECURITY DEFINER
-- functions. That broke has_permission: every PO / GoodsReceipt /
-- GoodsReceiptItem / settings write now fails its RLS WITH CHECK with
-- "42501 permission denied for table role_permissions".
--
-- Re-granting SELECT is the wrong fix: role_permissions has FORCE RLS with zero
-- policies (deny-all), so an invoker read would see no rows and silently deny
-- every legitimate sync instead.
--
-- The correct, consistent fix is to align has_permission with its siblings
-- my_business_id / get_my_permissions: SECURITY DEFINER, owned by the postgres
-- role (BYPASSRLS), with search_path pinned to public. The table stays fully
-- locked down (no API grant, FORCE RLS) and is reached only through definer
-- helpers. Body is unchanged — behavior-preserving.
--
-- Rollback:
--   ALTER FUNCTION public.has_permission(text) SECURITY INVOKER;
--   GRANT SELECT ON public.role_permissions TO authenticated;
-- =============================================================================

create or replace function public.has_permission(permission_code text)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $function$
  select exists (
    select 1
    from employees e
    join employee_roles er on er.employee_id = e.id
    join roles r on r.id = er.role_id
    join role_permissions rp on rp.role_id = r.id
    join permissions p on p.id = rp.permission_id
    where e.user_id = auth.uid()
      and p.code = permission_code
  );
$function$;

-- Direct-call surface hardening: a SECURITY DEFINER helper should not be
-- callable by unauthenticated roles. RLS policy evaluation for authenticated is
-- unaffected since EXECUTE is granted explicitly below.
revoke execute on function public.has_permission(text) from public;
grant  execute on function public.has_permission(text) to authenticated, service_role;
