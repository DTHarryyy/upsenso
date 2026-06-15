-- =============================================================================
-- Seed procurement into the business TEMPLATES so every NEW business gets it.
--
-- Audit (2026-06-15): apply_business_template() seeds a new business's modules
-- and role_permissions from the business_template_* tables. Those tables contain
-- suppliers.* but NO procurement.* — so every newly-created business would
-- repeat the gap that 20260615000001 just backfilled for existing businesses:
--   • business_template_modules            — 0 'procurement' rows
--   • business_template_role_permissions   — 0 'procurement.*' rows
--
-- This adds both, idempotently (NOT EXISTS guards), mirroring the role matrix:
--   Owner (level 1) / Manager (level 2) → view, create_po, approve_po, receive, manage
--   Inventory Staff (level 4)           → view, receive
--   Cashier (level 3)                   → none
--
-- Existing businesses are untouched (they were fixed by 20260615000001 and
-- already have the procurement module enabled). Templates only take effect at
-- business creation, so no effective_permissions recompute is needed here.
--
-- Rollback:
--   DELETE FROM business_template_role_permissions WHERE permission_code LIKE 'procurement.%';
--   DELETE FROM business_template_modules          WHERE module_code = 'procurement';
-- =============================================================================

-- ── 1. Enable the procurement module on every template ───────────────────────
INSERT INTO business_template_modules (template_id, module_code, sort_order)
SELECT t.id, 'procurement', 13
FROM   business_templates t
WHERE  NOT EXISTS (
  SELECT 1 FROM business_template_modules m
  WHERE  m.template_id = t.id
    AND  m.module_code = 'procurement'
);

-- ── 2. Owner & Branch Manager — full procurement ─────────────────────────────
INSERT INTO business_template_role_permissions (template_role_id, permission_code, is_granted)
SELECT tr.id, v.code, true
FROM   business_template_roles tr
CROSS  JOIN (VALUES
         ('procurement.view'),
         ('procurement.create_po'),
         ('procurement.approve_po'),
         ('procurement.receive'),
         ('procurement.manage')
       ) AS v(code)
WHERE  tr.level IN (1, 2)
  AND  NOT EXISTS (
    SELECT 1 FROM business_template_role_permissions x
    WHERE  x.template_role_id = tr.id
      AND  x.permission_code  = v.code
  );

-- ── 3. Inventory Staff — view + physical receiving only ──────────────────────
INSERT INTO business_template_role_permissions (template_role_id, permission_code, is_granted)
SELECT tr.id, v.code, true
FROM   business_template_roles tr
CROSS  JOIN (VALUES
         ('procurement.view'),
         ('procurement.receive')
       ) AS v(code)
WHERE  tr.level = 4
  AND  NOT EXISTS (
    SELECT 1 FROM business_template_role_permissions x
    WHERE  x.template_role_id = tr.id
      AND  x.permission_code  = v.code
  );
