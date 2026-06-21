-- =============================================================================
-- UPSENSO — PURGE TEST DATA (one-time, manual). NOT a migration.
-- =============================================================================
-- DESTRUCTIVE. Deletes ALL tenant data and keeps only seed/reference tables
-- (modules, permissions, business_templates*). Use ONLY when promoting a project
-- to production (Option A) after confirming there is no real business data.
--
-- BEFORE RUNNING:
--   1. Confirm this is the project you intend to make PRODUCTION.
--   2. Confirm PITR / a fresh backup exists (so a mistake is recoverable).
--   3. Confirm every business here is test data:
--        SELECT id, name, created_at FROM businesses ORDER BY created_at;
--
-- NOTE: This cleans the public schema only. Orphaned test logins in auth.users
--       (employees.auth_user_id is SET NULL on auth delete) must be removed
--       separately via the dashboard or an auth-schema script.
-- =============================================================================

BEGIN;

-- ── Deepest children first (FK order; some are ON DELETE NO ACTION) ──────────
DELETE FROM public.refund_items;
DELETE FROM public.refunds;
DELETE FROM public.transaction_payments;
DELETE FROM public.transaction_items;
DELETE FROM public.transactions;
DELETE FROM public.stock_ledger;
DELETE FROM public.inventory_levels;
DELETE FROM public.recipe_lines;
DELETE FROM public.purchase_order_lines;
DELETE FROM public.purchase_orders;
DELETE FROM public.stock_transfers;
DELETE FROM public.shifts;
DELETE FROM public.expenses;
DELETE FROM public.fraud_flags;
DELETE FROM public.notifications;
DELETE FROM public.audit_logs;

-- ── Permission resolution + overrides ────────────────────────────────────────
DELETE FROM public.effective_permissions;
DELETE FROM public.permission_snapshot_versions;
DELETE FROM public.user_permissions;
DELETE FROM public.branch_permissions;
DELETE FROM public.employee_permissions;
DELETE FROM public.employee_roles;
DELETE FROM public.employee_branches;

-- ── Catalog + per-business config ────────────────────────────────────────────
DELETE FROM public.product_variants;
DELETE FROM public.products;
DELETE FROM public.categories;
DELETE FROM public.units;
DELETE FROM public.suppliers;
DELETE FROM public.receipt_settings;
DELETE FROM public.business_settings;
DELETE FROM public.invoice_sequences;
DELETE FROM public.business_modules;
DELETE FROM public.sync_conflicts;

-- ── Principals + org ─────────────────────────────────────────────────────────
DELETE FROM public.employees;
DELETE FROM public.roles WHERE business_id IS NOT NULL; -- keep any global/system roles
DELETE FROM public.branches;
DELETE FROM public.users;       -- public.users tenant rows (auth.users handled separately)
DELETE FROM public.businesses;

-- KEPT (seed/reference — do NOT delete): modules, permissions, business_templates,
-- business_template_categories, business_template_modules,
-- business_template_role_permissions, business_template_roles, business_template_settings.

-- Sanity check before committing — expect tenant tables empty, seed tables intact.
-- SELECT 'businesses' t, count(*) FROM public.businesses
-- UNION ALL SELECT 'permissions', count(*) FROM public.permissions
-- UNION ALL SELECT 'modules', count(*) FROM public.modules
-- UNION ALL SELECT 'business_templates', count(*) FROM public.business_templates;

COMMIT;
