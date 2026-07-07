-- =============================================================================
-- M7.1 Phase 3 — the cloud paywall, enforced server-side.
--
-- RESTRICTIVE write policies (INSERT/UPDATE/DELETE) calling has_cloud_access()
-- on every business-data-plane table the client can write. This is what makes
-- "Free = local-only" real: a tampered client that re-enables its SyncService
-- still dies here — the server is the only authority (design §6.3).
--
-- Scope decisions:
--   * WRITES ONLY. SELECT is deliberately NOT gated: a lapsed tenant keeps
--     reading their frozen cloud copy (frozen-not-deleted §7.3, win-back,
--     export). Bounded read egress during grace is accepted COGS.
--   * IDENTITY PLANE IS NOT GATED: businesses, branches, employees,
--     employee_branches, users, roles, permission tables, business_modules,
--     devices (audit-chain directory). Onboarding, login, and permission
--     admin must work on Free — the cloud is the paywall, identity is not.
--     Branch/seat CAPS are separate (20260708000002).
--   * RESTRICTIVE policies AND with the existing permissive tenant/permission
--     policies (pattern: 20260627000003) — nothing is loosened here.
--   * has_cloud_access() is STABLE and wrapped in (SELECT ...) so the planner
--     evaluates it once per statement (InitPlan), not per row. While
--     billing_settings.cloud_gate_enforced = false (the P1 default) it returns
--     TRUE for everyone — this migration is INERT until the flag flips, which
--     happens only after the entitlement-aware client is released.
--   * Table list mirrors lib/core/sync/synced_tables_registry.dart
--     (businessData: true) plus the child tables written through parent
--     remote-DSes (transaction_items, refund_items) and the client-written
--     settings/caches (refund_settings, procurement_settings, sync_conflicts,
--     notifications).
--
-- ROLLBACK (drops only the policies this file adds):
--   DO $$ DECLARE t text; BEGIN
--     FOREACH t IN ARRAY ARRAY[
--       'categories','products','product_variants','product_barcodes',
--       'recipe_lines','inventory_levels','stock_ledger','sync_conflicts',
--       'transactions','transaction_items','refunds','refund_items',
--       'refund_settings','expenses','suppliers','purchase_orders',
--       'purchase_order_lines','goods_receipts','goods_receipt_items',
--       'procurement_settings','customers','receipt_settings','audit_logs',
--       'fraud_flags','notifications']
--     LOOP
--       EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t || '_cloud_gate_ins', t);
--       EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t || '_cloud_gate_upd', t);
--       EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t || '_cloud_gate_del', t);
--     END LOOP;
--   END $$;
--   DROP POLICY IF EXISTS product_images_cloud_gate_ins ON storage.objects;
--   DROP POLICY IF EXISTS product_images_cloud_gate_upd ON storage.objects;
-- =============================================================================

DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    -- keep in lockstep with lib/core/sync/synced_tables_registry.dart
    'categories',
    'products',
    'product_variants',
    'product_barcodes',
    'recipe_lines',
    'inventory_levels',
    'stock_ledger',
    'sync_conflicts',
    'transactions',
    'transaction_items',
    'refunds',
    'refund_items',
    'refund_settings',
    'expenses',
    'suppliers',
    'purchase_orders',
    'purchase_order_lines',
    'goods_receipts',
    'goods_receipt_items',
    'procurement_settings',
    'customers',
    'receipt_settings',
    'audit_logs',
    'fraud_flags',
    'notifications'
  ]
  LOOP
    -- Skip gracefully if an environment lacks one of the tables (dev drift);
    -- prod has all of them.
    IF to_regclass('public.' || t) IS NULL THEN
      RAISE WARNING 'cloud_gate skipped: table public.% does not exist', t;
      CONTINUE;
    END IF;

    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.%I', t || '_cloud_gate_ins', t);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I AS RESTRICTIVE FOR INSERT TO authenticated '
      'WITH CHECK ((SELECT public.has_cloud_access()))',
      t || '_cloud_gate_ins', t);

    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.%I', t || '_cloud_gate_upd', t);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I AS RESTRICTIVE FOR UPDATE TO authenticated '
      'USING ((SELECT public.has_cloud_access()))',
      t || '_cloud_gate_upd', t);

    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON public.%I', t || '_cloud_gate_del', t);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I AS RESTRICTIVE FOR DELETE TO authenticated '
      'USING ((SELECT public.has_cloud_access()))',
      t || '_cloud_gate_del', t);
  END LOOP;
END;
$$;

-- ── Storage: product images ride the same gate ───────────────────────────────
-- (avatars stay ungated — profile identity, not business data.)
DROP POLICY IF EXISTS product_images_cloud_gate_ins ON storage.objects;
CREATE POLICY product_images_cloud_gate_ins ON storage.objects
  AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id <> 'product-images' OR (SELECT public.has_cloud_access())
  );

DROP POLICY IF EXISTS product_images_cloud_gate_upd ON storage.objects;
CREATE POLICY product_images_cloud_gate_upd ON storage.objects
  AS RESTRICTIVE FOR UPDATE TO authenticated
  USING (
    bucket_id <> 'product-images' OR (SELECT public.has_cloud_access())
  );
