-- =============================================================================
-- Seed role priorities. APPLIED to production 2026-06-23 (remote version
-- 20260623135805).
--
-- All roles had priority = 0, which made current_user_role()'s ORDER BY priority
-- DESC arbitrary and blocked any priority-based anti-escalation (0 >= 0). Higher
-- = more authority. Cashier and Inventory Staff are intentional peers. Unknown /
-- custom roles are left untouched (stay low, which is conservative for
-- escalation). No employees existed at apply time, so no resolved role flipped.
--
-- ROLLBACK: UPDATE public.roles SET priority = 0
--   WHERE name IN ('Super Admin','Business Owner','Owner','Branch Manager','Cashier','Inventory Staff');
-- =============================================================================

UPDATE public.roles SET priority = CASE name
  WHEN 'Super Admin'     THEN 110
  WHEN 'Business Owner'  THEN 100
  WHEN 'Owner'           THEN 100
  WHEN 'Branch Manager'  THEN 50
  WHEN 'Cashier'         THEN 10
  WHEN 'Inventory Staff' THEN 10
  ELSE priority
END
WHERE name IN ('Super Admin','Business Owner','Owner','Branch Manager','Cashier','Inventory Staff');
