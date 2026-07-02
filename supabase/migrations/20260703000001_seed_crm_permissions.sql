-- =============================================================================
-- Seed the crm.* permission codes that exist in the app's PermissionKeys but
-- were never added to the server permissions table.
--
-- Audit (2026-07-03) found that 20260702000001_crm_customers.sql added RLS
-- policies calling has_permission('crm.manage') on the new `customers` table,
-- but no migration ever seeded crm.view / crm.manage / nav.customers into
-- `permissions`. Effect of the gap (same shape as the prior recipe/ingredient
-- gap fixed in 20260627000007):
--   • has_permission('crm.manage') can never resolve permission_id for a code
--     that doesn't exist in `permissions`, so its role_allow branch never
--     matches — every non-owner write to `customers` (INSERT/UPDATE) is
--     rejected by RLS regardless of the employee's role or client-side
--     permission. Owner bypass is the only reason it appeared to work at all.
--   • The client's online (RolePermissionMatrix) and offline
--     (DefaultPermissionMatrix) matrices both say Branch Manager/Cashier should
--     have crm access — the server silently disagreed.
--   • Per-employee overrides for crm.view/crm.manage could never be granted
--     via set_employee_permission_override, since that RPC also resolves
--     permission_id by code.
--
-- Mirrors the app role matrix (see DefaultPermissionMatrix / RolePermissionMatrix):
--   Business Owner  → crm.view, crm.manage, nav.customers
--   Branch Manager  → crm.view, crm.manage, nav.customers
--   Cashier         → crm.view only (can attach an existing customer at the
--                      till; quick-add / edit / archive stays manager-level)
--   Inventory Staff → none
--
-- Owner bypass in has_permission() means Business Owner never strictly needs a
-- role_permissions row to pass RLS, but 'Business Owner' is still wired below
-- (matching the recipe/ingredient and procurement precedents) for
-- defense-in-depth and so any tooling that reads role_permissions directly
-- (rather than calling has_permission()) sees a consistent grant.
--
-- Wired by role NAME so it covers every business's copy of each system role,
-- plus business_template_role_permissions so new businesses inherit it. All
-- statements are idempotent (WHERE NOT EXISTS / ON CONFLICT DO NOTHING).
--
-- ROLLBACK:
--   DELETE FROM role_permissions rp USING permissions p
--     WHERE rp.permission_id = p.id AND p.code IN ('crm.view','crm.manage','nav.customers');
--   DELETE FROM business_template_role_permissions
--     WHERE permission_code IN ('crm.view','crm.manage','nav.customers');
--   DELETE FROM permissions
--     WHERE code IN ('crm.view','crm.manage','nav.customers');
-- =============================================================================

-- ── 1. Seed the missing permission codes ────────────────────────────────────
INSERT INTO permissions (code, action, module_code, display_name, is_dangerous)
SELECT v.code, v.action, v.module_code, v.display_name, false
FROM (VALUES
  ('crm.view',      'view',     'crm', 'View Customers'),
  ('crm.manage',    'manage',   'crm', 'Manage Customers'),
  ('nav.customers', 'navigate', 'crm', 'Navigate to Customers')
) AS v(code, action, module_code, display_name)
WHERE NOT EXISTS (SELECT 1 FROM permissions p WHERE p.code = v.code);

-- ── 2. Wire role_permissions — Business Owner & Branch Manager (full) ───────
INSERT INTO role_permissions (role_id, permission_id, allowed)
SELECT r.id, p.id, true
FROM   roles r
CROSS  JOIN permissions p
WHERE  r.name IN ('Business Owner', 'Branch Manager')
  AND  p.code IN ('crm.view', 'crm.manage', 'nav.customers')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- ── 3. Wire role_permissions — Cashier (view only) ───────────────────────────
INSERT INTO role_permissions (role_id, permission_id, allowed)
SELECT r.id, p.id, true
FROM   roles r
CROSS  JOIN permissions p
WHERE  r.name = 'Cashier'
  AND  p.code = 'crm.view'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Inventory Staff intentionally gets no crm.* grant (matches DefaultPermissionMatrix).

-- ── 4. Seed template role permissions so new businesses inherit them ────────
INSERT INTO business_template_role_permissions (template_role_id, permission_code, is_granted)
SELECT tr.id, v.code, true
FROM   business_template_roles tr
CROSS  JOIN (VALUES
  ('crm.view'), ('crm.manage'), ('nav.customers')
) AS v(code)
WHERE  tr.name IN ('Business Owner', 'Branch Manager')
  AND  NOT EXISTS (
    SELECT 1 FROM business_template_role_permissions x
    WHERE x.template_role_id = tr.id AND x.permission_code = v.code
  );

INSERT INTO business_template_role_permissions (template_role_id, permission_code, is_granted)
SELECT tr.id, 'crm.view', true
FROM   business_template_roles tr
WHERE  tr.name = 'Cashier'
  AND  NOT EXISTS (
    SELECT 1 FROM business_template_role_permissions x
    WHERE x.template_role_id = tr.id AND x.permission_code = 'crm.view'
  );

-- ── 5. Recompute effective_permissions so grants appear without re-login ────
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
