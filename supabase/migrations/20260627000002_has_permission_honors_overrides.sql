-- =============================================================================
-- Make has_permission() honor per-employee and per-branch permission overrides.
--
-- WHY
--   has_permission() is the single RLS oracle behind every permission-gated
--   write: purchase_orders, procurement_settings, goods_receipts, expenses, and
--   the employee create / role-assignment guards. Until now it evaluated ONLY
--   role_permissions (+ owner bypass), so user_permissions overrides were never
--   enforced server-side:
--     • an explicit DENY override was bypassable via the REST API (security hole)
--     • an explicit ALLOW override never let an RLS-gated write through, so a
--       permission granted in the UI still failed on the server (functional gap)
--
--   This aligns has_permission() with the exact hierarchy compute_employee_
--   permissions() already writes into effective_permissions, so the server and
--   the client now agree on every decision:
--     owner bypass
--       > user_deny  > branch_deny
--       > user_allow > branch_allow
--       > role_allow
--       > deny
--
--   Owner bypass stays FIRST and scoped to my_business_id(), so an owner can
--   never be locked out by an override and never inherits rights in a business
--   where they are only staff. is_active and expires_at are respected.
--
-- DELIBERATELY OUT OF SCOPE
--   Layer 0 (module_disabled) is NOT enforced here. has_permission() has never
--   gated on module state and adding it could newly block writes for businesses
--   with missing/misconfigured business_modules rows. Module gating remains a
--   separate concern. Per-branch overrides use the caller's employees.branch_id;
--   the override UI today only creates business-wide (branch_id IS NULL) rows.
--
-- ROLLBACK
--   Restore the prior definition from 20260623000002_harden_has_permission.sql
--   (owner bypass + role_permissions only). No schema change.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.has_permission(permission_code text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  WITH me AS (
    -- The branch lives in employee_branches (there is no employees.branch_id);
    -- resolve a single branch the same way get_my_permissions() does so the
    -- server decision matches the client's effective_permissions snapshot.
    SELECT e.id AS employee_id,
           (SELECT eb.branch_id FROM employee_branches eb
            WHERE eb.employee_id = e.id LIMIT 1) AS branch_id
    FROM   employees e
    WHERE  e.auth_user_id = auth.uid()
      AND  e.is_active   IS TRUE
    LIMIT  1
  )
  -- Owner of the active business holds every permission within it.
  SELECT EXISTS (
    SELECT 1 FROM businesses b
    WHERE b.id = my_business_id()
      AND b.owner_id = auth.uid()
  )
  OR COALESCE((
    SELECT CASE
      -- user_deny: explicit per-employee DENY (business-wide or this branch).
      WHEN EXISTS (
        SELECT 1
        FROM   user_permissions up
        JOIN   permissions p ON p.id = up.permission_id
        WHERE  up.employee_id = me.employee_id
          AND  p.code         = permission_code
          AND  up.is_granted  IS FALSE
          AND  up.is_active   IS TRUE
          AND  (up.branch_id IS NULL OR up.branch_id = me.branch_id)
          AND  (up.expires_at IS NULL OR up.expires_at > now())
      ) THEN false

      -- branch_deny: explicit branch-level DENY.
      WHEN EXISTS (
        SELECT 1
        FROM   branch_permissions bp
        JOIN   permissions p ON p.id = bp.permission_id
        WHERE  bp.branch_id  = me.branch_id
          AND  p.code        = permission_code
          AND  bp.is_granted IS FALSE
      ) THEN false

      -- user_allow: explicit per-employee ALLOW (business-wide or this branch).
      WHEN EXISTS (
        SELECT 1
        FROM   user_permissions up
        JOIN   permissions p ON p.id = up.permission_id
        WHERE  up.employee_id = me.employee_id
          AND  p.code         = permission_code
          AND  up.is_granted  IS TRUE
          AND  up.is_active   IS TRUE
          AND  (up.branch_id IS NULL OR up.branch_id = me.branch_id)
          AND  (up.expires_at IS NULL OR up.expires_at > now())
      ) THEN true

      -- branch_allow: explicit branch-level ALLOW.
      WHEN EXISTS (
        SELECT 1
        FROM   branch_permissions bp
        JOIN   permissions p ON p.id = bp.permission_id
        WHERE  bp.branch_id  = me.branch_id
          AND  p.code        = permission_code
          AND  bp.is_granted IS TRUE
      ) THEN true

      -- role_allow: granted by the employee's role(s).
      WHEN EXISTS (
        SELECT 1
        FROM   employee_roles  er
        JOIN   role_permissions rp ON rp.role_id     = er.role_id
        JOIN   permissions      p  ON p.id           = rp.permission_id
        WHERE  er.employee_id = me.employee_id
          AND  rp.allowed     IS TRUE
          AND  p.code         = permission_code
      ) THEN true

      ELSE false
    END
    FROM me
  ), false);
$function$;

REVOKE EXECUTE ON FUNCTION public.has_permission(text) FROM public;
GRANT  EXECUTE ON FUNCTION public.has_permission(text) TO authenticated, service_role;
