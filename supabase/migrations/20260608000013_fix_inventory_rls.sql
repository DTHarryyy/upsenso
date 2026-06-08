-- Fix inventory_levels RLS and has_branch_access so business owners can sync
-- inventory even before branches/employees exist on the server.
--
-- Problem 1: has_branch_access only checks employee_branches; owners have no
--   employee records, so it always returned false for them.
-- Problem 2: branch_inventory policy used = get_my_business_id() which is
--   non-deterministic when a user owns multiple businesses.

-- Update has_branch_access to short-circuit for business owners.
CREATE OR REPLACE FUNCTION public.has_branch_access(bid uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    CASE
      WHEN bid IS NULL THEN true
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

-- Replace branch_inventory policy to use IN (handles multi-business owners)
-- and also allow inserts for branches not yet pushed to server (branch FK missing).
DROP POLICY IF EXISTS branch_inventory ON public.inventory_levels;

CREATE POLICY branch_inventory ON public.inventory_levels
  FOR ALL
  USING (
    business_id IN (
      SELECT business_id FROM public.employees WHERE auth_user_id = auth.uid()
      UNION
      SELECT id FROM public.businesses WHERE owner_id = auth.uid()
    )
  )
  WITH CHECK (
    business_id IN (
      SELECT business_id FROM public.employees WHERE auth_user_id = auth.uid()
      UNION
      SELECT id FROM public.businesses WHERE owner_id = auth.uid()
    )
  );
