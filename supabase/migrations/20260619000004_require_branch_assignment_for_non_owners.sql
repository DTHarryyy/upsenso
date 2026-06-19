-- has_branch_access(NULL) previously returned true for ANY authenticated
-- user, letting an employee with no branch assignment write/read branchless
-- rows on expenses/transactions/inventory_movements/shifts/stock_transfers.
-- Only Owner/Super Admin legitimately operate across all branches; everyone
-- else must have an explicit branch assignment.
-- Verified before apply: zero existing NULL-branch rows across all 5 tables
-- gated by this function, so no data becomes inaccessible.
-- Rollback:
--   create or replace function public.has_branch_access(bid uuid)
--   returns boolean language sql stable security definer set search_path to 'public'
--   as $$
--     select case
--       when bid is null then true
--       when exists (select 1 from public.branches b join public.businesses biz
--         on biz.id = b.business_id where b.id = bid and biz.owner_id = auth.uid()) then true
--       else exists (select 1 from public.employee_branches eb
--         join public.employees e on e.id = eb.employee_id
--         where e.auth_user_id = auth.uid() and eb.branch_id = bid)
--     end;
--   $$;

create or replace function public.has_branch_access(bid uuid)
returns boolean
language sql
stable security definer
set search_path to 'public'
as $$
  SELECT
    CASE
      WHEN bid IS NULL THEN public.i_am_super_admin()
      -- owner of the business that owns this branch always has access
      WHEN EXISTS (
        SELECT 1
        FROM public.branches b
        JOIN public.businesses biz ON biz.id = b.business_id
        WHERE b.id = bid
          AND biz.owner_id = auth.uid()
      ) THEN true
      -- employee explicitly assigned to the branch
      ELSE EXISTS (
        SELECT 1
        FROM public.employee_branches eb
        JOIN public.employees e ON e.id = eb.employee_id
        WHERE e.auth_user_id = auth.uid()
          AND eb.branch_id = bid
      )
    END;
$$;
