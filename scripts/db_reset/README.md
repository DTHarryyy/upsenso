# DB Reset — Fresh Production Launch (2026-07-04)

One-time scripts that reset the **Upsenso** Supabase project
(`dmhyfezuravbjpoxjesb`) to a clean, zero-tenant state for launch. They remove all
test/dev data (businesses, users, transactions, uploads) while preserving schema,
RLS, functions, triggers, and the global reference catalogs the app needs.

**These are DML-only. No schema/DDL, no migration, no version bump.**

## Prerequisite (BLOCKING)
A verified backup must exist first. Taken on 2026-07-04 to
`backups/reset-20260704/` (JSON snapshots + MANIFEST). Do not run these without it.

## Run order (as `postgres`, e.g. Supabase SQL editor / MCP execute_sql)
1. `01_truncate_tenant_data.sql` — empty all 47 tenant/transactional tables.
2. `02_delete_auth_users.sql`   — delete all auth users (cascades to sessions/identities/tokens).
3. `03_purge_storage.sql`       — empty the 3 storage buckets.
4. `04_verify.sql`              — confirm all zero + catalogs unchanged.

## Preserved (the 8 global catalog tables — never touched)
`permissions` (100), `modules` (16), `business_templates` (10),
`business_template_roles` (40), `business_template_role_permissions` (2500),
`business_template_modules` (75), `business_template_categories` (53),
`business_template_settings`. A new signup rebuilds every per-business row from
these via the `apply_business_template` RPC.
