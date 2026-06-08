-- =============================================================================
-- UPSENSO — Live Database Schema Audit Query  (READ-ONLY — no changes)
-- Run this in the Supabase SQL editor or via: supabase db execute
-- =============================================================================

-- ── 1. All tables in public schema ──────────────────────────────────────────
SELECT
  t.table_name,
  t.table_type,
  obj_description(
    (quote_ident(t.table_schema) || '.' || quote_ident(t.table_name))::regclass,
    'pg_class'
  ) AS table_comment
FROM information_schema.tables t
WHERE t.table_schema = 'public'
ORDER BY t.table_name;

-- ── 2. Column definitions for every table ───────────────────────────────────
SELECT
  c.table_name,
  c.column_name,
  c.data_type,
  c.udt_name,
  c.is_nullable,
  c.column_default
FROM information_schema.columns c
WHERE c.table_schema = 'public'
ORDER BY c.table_name, c.ordinal_position;

-- ── 3. Primary and foreign keys ──────────────────────────────────────────────
SELECT
  tc.table_name,
  kcu.column_name,
  tc.constraint_name,
  tc.constraint_type,
  ccu.table_name  AS foreign_table,
  ccu.column_name AS foreign_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage   kcu
  ON kcu.constraint_name = tc.constraint_name
LEFT JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_schema = 'public'
  AND tc.constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY', 'UNIQUE')
ORDER BY tc.table_name, tc.constraint_type;

-- ── 4. Indexes ───────────────────────────────────────────────────────────────
SELECT
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- ── 5. RLS status per table ──────────────────────────────────────────────────
SELECT
  relname              AS table_name,
  relrowsecurity       AS rls_enabled,
  relforcerowsecurity  AS rls_forced
FROM pg_class
WHERE relnamespace = 'public'::regnamespace
  AND relkind = 'r'
ORDER BY relname;

-- ── 6. All RLS policies ──────────────────────────────────────────────────────
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ── 7. All functions in public schema ────────────────────────────────────────
SELECT
  routine_name,
  routine_type,
  security_type,
  data_type AS return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
ORDER BY routine_name;

-- ── 8. All triggers ──────────────────────────────────────────────────────────
SELECT
  trigger_name,
  event_object_table AS table_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- ── 9. Permission system health check ────────────────────────────────────────
-- Shows which expected tables exist vs. which are missing.
SELECT
  expected.table_name,
  CASE WHEN actual.table_name IS NOT NULL THEN '✓ EXISTS' ELSE '✗ MISSING' END AS status
FROM (VALUES
  ('businesses'),
  ('branches'),
  ('employees'),
  ('employee_roles'),
  ('employee_branches'),
  ('roles'),
  ('permissions'),
  ('role_permissions'),
  ('modules'),
  ('business_modules'),
  ('user_permissions'),
  ('branch_permissions'),
  ('effective_permissions'),
  ('permission_snapshot_versions'),
  ('audit_logs'),
  ('transactions'),
  ('transaction_items'),
  ('products'),
  ('product_variants'),
  ('categories'),
  ('inventory_levels'),
  ('expenses'),
  ('shifts')
) AS expected(table_name)
LEFT JOIN information_schema.tables actual
  ON actual.table_name  = expected.table_name
  AND actual.table_schema = 'public'
ORDER BY expected.table_name;
