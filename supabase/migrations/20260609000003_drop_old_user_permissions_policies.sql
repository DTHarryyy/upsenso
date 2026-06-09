-- =============================================================================
-- Drop legacy user_permissions RLS policies that pre-date the explicit split.
--
-- up_read   — superseded by user_permissions_select (same logic, new name)
-- up_write  — superseded by user_permissions_insert / _update / _delete
--             (splitting FOR ALL into explicit verbs is the security improvement)
-- =============================================================================

DROP POLICY IF EXISTS "up_read"  ON user_permissions;
DROP POLICY IF EXISTS "up_write" ON user_permissions;
