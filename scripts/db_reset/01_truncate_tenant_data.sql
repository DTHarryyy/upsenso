-- Phase 1 — Empty every tenant/transactional table in `public`.
-- Preserves exactly the 8 global catalog tables (keep-list below).
-- CASCADE resolves FK order; RESTART IDENTITY resets identity sequences.
-- Catalog tables are only referenced *by* tenant tables (never the reverse),
-- so CASCADE cannot reach them. Verify with 04_verify.sql afterward.
DO $$
DECLARE
  keep text[] := ARRAY[
    'permissions','modules','business_templates',
    'business_template_roles','business_template_role_permissions',
    'business_template_modules','business_template_categories',
    'business_template_settings'
  ];
  tbls text;
BEGIN
  SELECT string_agg(format('public.%I', tablename), ', ')
    INTO tbls
  FROM pg_tables
  WHERE schemaname = 'public'
    AND tablename <> ALL(keep);

  RAISE NOTICE 'Truncating: %', tbls;
  EXECUTE format('TRUNCATE TABLE %s RESTART IDENTITY CASCADE', tbls);
END $$;
