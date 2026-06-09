-- =============================================================================
-- Backfill two missing permission codes and fix one wrong module_code.
--
-- Gaps found by comparing PermissionKeys.all (Dart) vs the live permissions
-- table:
--   1. pos.approve_void   — new key added in the permission-system cleanup;
--                           needed so approve-void-transaction is distinct from
--                           pos.void_sale in the 6-layer hierarchy.
--   2. audit_logs.delete  — new key that separates "delete audit log entries"
--                           from "view audit logs" (previously both mapped to
--                           audit_logs.view, which is dangerous).
--   3. products.delete    — row already exists but module_code = 'pos'.
--                           All other products.* rows use module_code = 'pos'
--                           (matching the existing DB convention), so this is
--                           correct — no change needed here.
--
-- All statements are idempotent (ON CONFLICT DO NOTHING).
-- =============================================================================

-- 1. pos.approve_void
--    Granted to Business Owner and Branch Manager (mirrors pos.void_sale access
--    pattern: manager can approve what cashier cannot).
INSERT INTO permissions (code, action, description, display_name, module_code,
                         is_dangerous, risk_level, requires_confirmation,
                         requires_manager_pin, audit_level)
VALUES (
  'pos.approve_void',
  'approve_void',
  'Approve a void-transaction request raised by a cashier',
  'Approve Void Transaction',
  'pos',
  false,
  'high',
  true,
  false,
  'detailed'
)
ON CONFLICT (code) DO NOTHING;

-- Wire pos.approve_void into role_permissions for Business Owner and Branch Manager.
INSERT INTO role_permissions (role_id, permission_id, allowed)
SELECT r.id, p.id, true
FROM   roles r
CROSS  JOIN permissions p
WHERE  p.code = 'pos.approve_void'
  AND  r.name IN ('Business Owner', 'Branch Manager')
ON CONFLICT (role_id, permission_id) DO NOTHING;


-- 2. audit_logs.delete
--    Only Business Owner gets this. Branch Manager intentionally excluded
--    (they cannot view audit logs at all, let alone delete them).
INSERT INTO permissions (code, action, description, display_name, module_code,
                         is_dangerous, risk_level, requires_confirmation,
                         requires_manager_pin, audit_level)
VALUES (
  'audit_logs.delete',
  'delete',
  'Delete or purge audit log entries',
  'Delete Audit Logs',
  'audit_logs',
  true,
  'critical',
  true,
  false,
  'immutable'
)
ON CONFLICT (code) DO NOTHING;

-- Wire audit_logs.delete into role_permissions for Business Owner only.
INSERT INTO role_permissions (role_id, permission_id, allowed)
SELECT r.id, p.id, true
FROM   roles r
CROSS  JOIN permissions p
WHERE  p.code = 'audit_logs.delete'
  AND  r.name = 'Business Owner'
ON CONFLICT (role_id, permission_id) DO NOTHING;


-- =============================================================================
-- Recompute effective_permissions for all active employees so the new codes
-- show up in their snapshots immediately (no re-login required).
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
