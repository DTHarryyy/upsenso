-- =============================================================================
-- Seed the recipe/ingredient permission codes that exist in the app's
-- PermissionKeys but were never added to the server permissions table.
--
-- Audit (2026-06-27) found 4 client keys missing server-side:
--   recipes.manage, ingredients.manage, ingredients.view, nav.recipes
-- Effect of the gap: has_permission() returns false for these for everyone but
-- owners (no permission row -> no role grant), and the online (server) and
-- offline (DefaultPermissionMatrix) matrices disagree. It also blocks any
-- server-side RLS gating of recipe_lines.
--
-- This mirrors the role matrix in DefaultPermissionMatrix: every role EXCEPT
-- Cashier gets the recipe/ingredient permissions (same tier as inventory mgmt).
-- Wired by role NAME so it covers every business's copy of each system role,
-- plus the business_template_role_permissions so new businesses inherit them.
-- All statements are idempotent (WHERE NOT EXISTS / ON CONFLICT DO NOTHING).
--
-- No server enforcement is attached here (recipe_lines RLS is a separate step);
-- this only makes the permission catalogue + role grants consistent.
--
-- ROLLBACK:
--   DELETE FROM role_permissions rp USING permissions p
--     WHERE rp.permission_id = p.id
--       AND p.code IN ('recipes.manage','ingredients.manage','ingredients.view','nav.recipes');
--   DELETE FROM business_template_role_permissions
--     WHERE permission_code IN ('recipes.manage','ingredients.manage','ingredients.view','nav.recipes');
--   DELETE FROM permissions
--     WHERE code IN ('recipes.manage','ingredients.manage','ingredients.view','nav.recipes');
-- =============================================================================

-- ── 1. Seed the missing permission codes ────────────────────────────────────
INSERT INTO permissions (code, action, module_code, display_name, is_dangerous)
SELECT v.code, v.action, v.module_code, v.display_name, false
FROM (VALUES
  ('ingredients.view',   'view',     'ingredients', 'View Ingredients'),
  ('ingredients.manage', 'manage',   'ingredients', 'Manage Ingredients'),
  ('recipes.manage',     'manage',   'recipes',     'Manage Recipes'),
  ('nav.recipes',        'navigate', 'recipes',     'Navigate to Recipes')
) AS v(code, action, module_code, display_name)
WHERE NOT EXISTS (SELECT 1 FROM permissions p WHERE p.code = v.code);

-- ── 2. Wire role_permissions for every non-Cashier role ─────────────────────
INSERT INTO role_permissions (role_id, permission_id, allowed)
SELECT r.id, p.id, true
FROM   roles r
CROSS  JOIN permissions p
WHERE  r.name IN ('Business Owner', 'Branch Manager', 'Inventory Staff')
  AND  p.code IN ('ingredients.view', 'ingredients.manage', 'recipes.manage', 'nav.recipes')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- ── 3. Seed template role permissions so new businesses inherit them ────────
INSERT INTO business_template_role_permissions (template_role_id, permission_code, is_granted)
SELECT tr.id, v.code, true
FROM   business_template_roles tr
CROSS  JOIN (VALUES
  ('ingredients.view'), ('ingredients.manage'), ('recipes.manage'), ('nav.recipes')
) AS v(code)
WHERE  tr.name IN ('Business Owner', 'Branch Manager', 'Inventory Staff')
  AND  NOT EXISTS (
    SELECT 1 FROM business_template_role_permissions x
    WHERE x.template_role_id = tr.id AND x.permission_code = v.code
  );

-- ── 4. Recompute effective_permissions so grants appear without re-login ────
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
