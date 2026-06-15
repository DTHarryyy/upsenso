-- =============================================================================
-- Backfill procurement role_permissions for EVERY business.
--
-- Audit (2026-06-15) found that procurement.* permissions were wired into
-- role_permissions for only one business's system-role copies. A second
-- business held the permission CODES but had no procurement role wiring, so its
-- employees resolved procurement access only via the app's offline
-- DefaultPermissionMatrix fallback — and would be DENIED once server-side
-- enforcement (RPCs / permission-aware RLS) lands.
--
-- This wires the procurement grants by role NAME, so it covers every business's
-- copy of each system role. It mirrors the intended role matrix:
--   Business Owner  → view, create_po, approve_po, receive, manage
--   Branch Manager  → view, create_po, approve_po, receive, manage
--   Inventory Staff → view, receive            (directory + physical receiving)
--   Cashier         → none
--
-- suppliers.view / suppliers.manage are already wired for all roles and are not
-- touched here. All statements are idempotent (ON CONFLICT DO NOTHING), so
-- re-running — or running against the already-correct business — is a no-op.
-- Rollback: DELETE FROM role_permissions USING permissions p, roles r
--   WHERE role_permissions.permission_id = p.id
--     AND role_permissions.role_id = r.id
--     AND p.code LIKE 'procurement.%'
--     AND r.name IN ('Business Owner','Branch Manager','Inventory Staff');
-- =============================================================================

-- ── Business Owner & Branch Manager — full procurement ───────────────────────
INSERT INTO role_permissions (role_id, permission_id, allowed)
SELECT r.id, p.id, true
FROM   roles r
CROSS  JOIN permissions p
WHERE  r.name IN ('Business Owner', 'Branch Manager')
  AND  p.code IN (
         'procurement.view',
         'procurement.create_po',
         'procurement.approve_po',
         'procurement.receive',
         'procurement.manage'
       )
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- ── Inventory Staff — view + physical receiving only ─────────────────────────
INSERT INTO role_permissions (role_id, permission_id, allowed)
SELECT r.id, p.id, true
FROM   roles r
CROSS  JOIN permissions p
WHERE  r.name = 'Inventory Staff'
  AND  p.code IN ('procurement.view', 'procurement.receive')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- =============================================================================
-- Recompute effective_permissions for all active employees so the new grants
-- appear in their snapshots immediately (no re-login required). Mirrors the
-- recompute block in 20260609000001_backfill_missing_permission_codes.sql.
-- =============================================================================
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
