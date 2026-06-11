-- =============================================================================
-- Register the Held / Suspended Sales permission codes server-side.
--
-- Client note: the app already grants these to the correct roles at runtime via
-- the DefaultPermissionMatrix fallback in PermissionService.can(), so EXISTING
-- users get access without this migration. This migration exists for
-- consistency so the codes appear in the permissions table, the owner's
-- permission-management UI lists them, and get_my_permissions() returns them
-- explicitly in each employee's effective_permissions snapshot.
--
-- New keys (mirror Dart PermissionKeys):
--   pos.hold_sale   — hold (suspend) the current sale and resume it later.
--   nav.held_sales  — see/open the Held Sales screen.
--
-- SELF-VERIFYING: instead of hard-coding enum values (risk_level / audit_level)
-- and role names — which differ per deployment — every value is DERIVED from
-- the existing `pos.use` / `nav.pos` rows. This means:
--   • No enum/CHECK guessing — the new rows reuse known-valid values.
--   • No role-name guessing — grants mirror exactly the roles that already
--     have pos.use / nav.pos granted (cashier / manager / owner).
--   • If nav.* permissions are NOT table-backed, that block is a safe no-op
--     (its SELECT yields no row), so nothing spurious is inserted.
-- All statements are idempotent (ON CONFLICT DO NOTHING).
-- =============================================================================

-- 1. pos.hold_sale ------------------------------------------------------------
--    Mirrors pos.use's risk/audit profile (a routine POS capability).
INSERT INTO permissions (code, action, description, display_name, module_code,
                         is_dangerous, risk_level, requires_confirmation,
                         requires_manager_pin, audit_level)
SELECT 'pos.hold_sale',
       'hold_sale',
       'Hold (suspend) the current sale and resume it later',
       'Hold Sales',
       src.module_code,
       false,
       src.risk_level,
       false,
       false,
       src.audit_level
FROM   permissions src
WHERE  src.code = 'pos.use'
ON CONFLICT (code) DO NOTHING;

-- Grant pos.hold_sale to exactly the roles that already have pos.use granted.
INSERT INTO role_permissions (role_id, permission_id, allowed)
SELECT rp.role_id, pnew.id, true
FROM   role_permissions rp
JOIN   permissions puse ON puse.id = rp.permission_id AND puse.code = 'pos.use'
CROSS  JOIN permissions pnew
WHERE  pnew.code = 'pos.hold_sale'
  AND  rp.allowed = true
ON CONFLICT (role_id, permission_id) DO NOTHING;


-- 2. nav.held_sales -----------------------------------------------------------
--    Only created if nav.* codes are table-backed; otherwise a safe no-op.
INSERT INTO permissions (code, action, description, display_name, module_code,
                         is_dangerous, risk_level, requires_confirmation,
                         requires_manager_pin, audit_level)
SELECT 'nav.held_sales',
       'held_sales',
       'Access the Held Sales screen',
       'Held Sales (Navigation)',
       src.module_code,
       false,
       src.risk_level,
       false,
       false,
       src.audit_level
FROM   permissions src
WHERE  src.code = 'nav.pos'
ON CONFLICT (code) DO NOTHING;

-- Grant nav.held_sales to exactly the roles that already have nav.pos granted.
INSERT INTO role_permissions (role_id, permission_id, allowed)
SELECT rp.role_id, pnew.id, true
FROM   role_permissions rp
JOIN   permissions pnav ON pnav.id = rp.permission_id AND pnav.code = 'nav.pos'
CROSS  JOIN permissions pnew
WHERE  pnew.code = 'nav.held_sales'
  AND  rp.allowed = true
ON CONFLICT (role_id, permission_id) DO NOTHING;


-- =============================================================================
-- Recompute effective_permissions for all active employees so the new codes
-- appear in their snapshots immediately (no re-login required).
-- Copied verbatim from 20260609000001_backfill_missing_permission_codes.sql.
-- =============================================================================
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT DISTINCT e.id AS employee_id, eb.branch_id
    FROM   employees       e
    JOIN   employee_branches eb ON eb.employee_id = e.id
    WHERE  e.is_active = true
  LOOP
    BEGIN
      PERFORM compute_employee_permissions(r.employee_id, r.branch_id);
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'recompute skipped employee=% branch=%: %',
        r.employee_id, r.branch_id, SQLERRM;
    END;
  END LOOP;
END;
$$;
