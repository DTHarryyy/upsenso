-- =============================================================================
-- M7.1 Phase 2 — seed billing permission codes (billing.view / billing.manage /
-- nav.billing) into the server permission catalog.
--
-- Owner-only by default, exactly like audit_logs.verify (20260703000002):
-- has_permission() owner-bypass already grants owners everything; seeding the
-- codes is what makes per-employee OVERRIDES resolvable (a business may grant
-- a trusted manager billing.view read-only). Client matrices mirror this:
-- role_permission_matrix.dart / default_permission_matrix.dart deny billing
-- for branch_manager / cashier / inventory_staff.
--
-- ROLLBACK:
--   DELETE FROM role_permissions rp USING permissions p
--     WHERE rp.permission_id = p.id
--       AND p.code IN ('billing.view', 'billing.manage', 'nav.billing');
--   DELETE FROM business_template_role_permissions
--     WHERE permission_code IN ('billing.view', 'billing.manage', 'nav.billing');
--   DELETE FROM permissions
--     WHERE code IN ('billing.view', 'billing.manage', 'nav.billing');
-- =============================================================================

INSERT INTO permissions (code, action, module_code, display_name, is_dangerous)
SELECT v.code, v.action, 'billing', v.display_name, v.is_dangerous
FROM (VALUES
  ('billing.view',   'view',   'View Billing',   false),
  ('billing.manage', 'manage', 'Manage Billing', true),
  ('nav.billing',    'nav',    'Billing Menu',   false)
) AS v(code, action, display_name, is_dangerous)
WHERE NOT EXISTS (SELECT 1 FROM permissions p WHERE p.code = v.code);

INSERT INTO role_permissions (role_id, permission_id, allowed)
SELECT r.id, p.id, true
FROM   roles r
CROSS  JOIN permissions p
WHERE  r.name = 'Business Owner'
  AND  p.code IN ('billing.view', 'billing.manage', 'nav.billing')
ON CONFLICT (role_id, permission_id) DO NOTHING;

INSERT INTO business_template_role_permissions (template_role_id, permission_code, is_granted)
SELECT tr.id, v.code, true
FROM   business_template_roles tr
CROSS  JOIN (VALUES ('billing.view'), ('billing.manage'), ('nav.billing')) AS v(code)
WHERE  tr.name = 'Business Owner'
  AND  NOT EXISTS (
    SELECT 1 FROM business_template_role_permissions x
    WHERE x.template_role_id = tr.id AND x.permission_code = v.code
  );

-- Recompute effective_permissions so any existing employee overrides resolve
-- without a re-login (same sweep as 20260703000002).
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT DISTINCT e.id AS employee_id, eb.branch_id
    FROM   employees        e
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
