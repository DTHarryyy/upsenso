-- =============================================================================
-- get_my_business_context(): the no-employee-row owner fallback hardcoded the
-- role_name literal as 'Super Admin', so any owner without an employees row
-- (the normal case per fix(security) 20260623134842/135338) surfaced "Super
-- Admin" in the UI wherever a screen read user.roleName without normalizing
-- it through displayRoleName(). No 'Super Admin' role exists in public.roles
-- (verified read-only 2026-06-26) -- this was purely a literal in this
-- function, not stored role data. Aligning the literal to 'Business Owner'
-- matches the only real role row for owners.
--
-- Every consumer already treats 'super admin' as an alias of 'business owner'
-- (lib/core/const/font_utils.dart displayRoleName, lib/core/branch/
-- branch_cubit.dart _isOwner, role_permission_matrix.dart superAdmin/owner
-- aliases, public.i_am_super_admin()), and no other DB function calls
-- get_my_business_context() (verified via pg_proc.prosrc scan), so this is a
-- pure relabeling with no behavioral or permission impact.
--
-- ROLLBACK: re-run this same CREATE OR REPLACE with 'Super Admin' in place of
-- 'Business Owner' in the fallback branch below.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_my_business_context()
 RETURNS TABLE(business_id uuid, role_id uuid, role_name text, business_name text, branch_id uuid, branch_name text, full_name text, template_id uuid, template_name text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  -- Primary: user has an employee record
  RETURN QUERY
  SELECT
    e.business_id,
    e.role_id,
    r.name                             AS role_name,
    biz.name                           AS business_name,
    eb.branch_id,
    br.name                            AS branch_name,
    COALESCE(e.full_name, u.full_name) AS full_name,
    biz.template_id,
    bt.name                            AS template_name
  FROM public.employees e
  JOIN  public.businesses         biz ON biz.id = e.business_id
  LEFT JOIN public.roles           r  ON r.id   = e.role_id
  LEFT JOIN public.employee_branches eb ON eb.employee_id = e.id
  LEFT JOIN public.branches        br  ON br.id  = eb.branch_id
  LEFT JOIN public.users           u   ON u.id   = v_uid
  LEFT JOIN public.business_templates bt ON bt.id = biz.template_id
  WHERE (e.auth_user_id = v_uid OR e.user_id = v_uid)
    AND e.is_active = true
  LIMIT 1;

  IF FOUND THEN RETURN; END IF;

  -- Fallback: user owns a business but has no employee record yet
  RETURN QUERY
  SELECT
    biz.id                    AS business_id,
    NULL::uuid                AS role_id,
    'Business Owner'::text    AS role_name,
    biz.name                  AS business_name,
    NULL::uuid                AS branch_id,
    NULL::text                AS branch_name,
    COALESCE(u.full_name, '') AS full_name,
    biz.template_id,
    bt.name                   AS template_name
  FROM public.businesses biz
  LEFT JOIN public.users           u  ON u.id   = v_uid
  LEFT JOIN public.business_templates bt ON bt.id = biz.template_id
  WHERE biz.owner_id = v_uid
  LIMIT 1;
END;
$function$;
