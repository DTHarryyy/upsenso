-- Enforce the RBAC rule "Owner / Super Admin cannot be removed" at the DB layer.
-- Blocks hard-delete and deactivation (is_active true->false) of an owner row,
-- so a UI-only restriction can no longer be bypassed via a crafted request.
-- Rollback:
--   drop trigger if exists trg_protect_owner_employee on public.employees;
--   drop function if exists public.protect_owner_employee();

create or replace function public.protect_owner_employee()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  norm text;
begin
  norm := replace(replace(lower(coalesce(old.role_name, '')), ' ', ''), '_', '');
  if norm in ('owner', 'businessowner', 'superadmin') then
    if tg_op = 'DELETE' then
      raise exception 'Cannot remove the business owner (employee %).', old.id
        using errcode = 'check_violation';
    elsif tg_op = 'UPDATE'
          and coalesce(new.is_active, true) = false
          and coalesce(old.is_active, true) = true then
      raise exception 'Cannot deactivate the business owner (employee %).', old.id
        using errcode = 'check_violation';
    end if;
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_protect_owner_employee on public.employees;
create trigger trg_protect_owner_employee
  before update or delete on public.employees
  for each row execute function public.protect_owner_employee();

-- Trigger functions must not be reachable via PostgREST RPC.
revoke execute on function public.protect_owner_employee() from public, anon, authenticated;
