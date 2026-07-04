-- Phase 4 — Verification. Expect all-zero deletes and unchanged catalogs.

-- (a) Every per-tenant/transactional table + auth + storage must be 0:
SELECT
  (SELECT count(*) FROM auth.users)              AS auth_users,        -- 0
  (SELECT count(*) FROM public.businesses)       AS businesses,        -- 0
  (SELECT count(*) FROM public.users)            AS app_users,         -- 0
  (SELECT count(*) FROM public.employees)        AS employees,         -- 0
  (SELECT count(*) FROM public.transactions)     AS transactions,      -- 0
  (SELECT count(*) FROM public.refunds)          AS refunds,           -- 0
  (SELECT count(*) FROM public.audit_logs)       AS audit_logs,        -- 0
  (SELECT count(*) FROM public.roles)            AS roles,             -- 0
  (SELECT count(*) FROM public.role_permissions) AS role_permissions,  -- 0
  (SELECT count(*) FROM public.business_modules) AS business_modules,  -- 0
  (SELECT count(*) FROM public.categories)       AS categories,        -- 0
  (SELECT count(*) FROM storage.objects
     WHERE bucket_id IN ('avatars','business-logos','product-images')) AS storage_objs; -- 0

-- (b) Catalogs must be UNCHANGED:
SELECT
  (SELECT count(*) FROM public.permissions)        AS permissions,        -- 100
  (SELECT count(*) FROM public.modules)            AS modules,            -- 16
  (SELECT count(*) FROM public.business_templates) AS business_templates, -- 10
  (SELECT count(*) FROM public.business_template_role_permissions) AS bt_role_perms; -- 2500

-- (c) Belt-and-suspenders: any public table still holding rows (should be
--     only the 8 catalog tables):
SELECT relname, n_live_tup
FROM pg_stat_user_tables
WHERE schemaname = 'public' AND n_live_tup > 0
ORDER BY relname;
