/// The authoritative list of local tables whose rows sync to Supabase.
///
/// Two consumers must stay in lockstep with SyncService's push order:
///  1. BackfillService.markAllForUpload — re-queues every local row as
///     pendingUpload on a Free→paid upgrade (design §7.2).
///  2. supabase/migrations/20260708000002_cloud_gate_rls.sql — the server
///     tables carrying the has_cloud_access() RESTRICTIVE write policies.
///     (Server-side the set also includes child tables the client writes
///     through parent remote-DSes: transaction_items, refund_items.)
///
/// Adding a `_syncX` to SyncService means adding the table here AND extending
/// the RLS migration — the cross-reference comment lives in both files.
library;

/// One synced table: its SQLite name and whether it is business data
/// (cloud-gated on the server) or identity-plane (never gated — onboarding
/// and login must work on Free).
class SyncedTable {
  final String tableName;
  final bool businessData;

  const SyncedTable(this.tableName, {this.businessData = true});
}

/// Ordered to match SyncService.syncAll's FK-safe push sequence.
const List<SyncedTable> syncedTablesRegistry = [
  // Identity plane — allowed on every tier.
  SyncedTable('branches', businessData: false),
  SyncedTable('businesses', businessData: false),
  SyncedTable('employees', businessData: false),
  SyncedTable('devices', businessData: false), // audit-chain directory

  // Business-data plane — cloud-gated server-side.
  SyncedTable('categories'),
  SyncedTable('products'),
  SyncedTable('product_variants'),
  SyncedTable('product_barcodes'),
  SyncedTable('transactions'),
  SyncedTable('audit_logs'),
  // refunds push their refund_items through the parent DAO (no own
  // sync_status locally); server-side refund_items is still cloud-gated.
  SyncedTable('refunds'),
  SyncedTable('expenses'),
  SyncedTable('inventory_levels'),
  SyncedTable('purchase_orders'),
  SyncedTable('stock_ledger'),
  SyncedTable('receipt_settings'),
  SyncedTable('fraud_flags'),
  SyncedTable('suppliers'),
  SyncedTable('customers'),
  SyncedTable('purchase_order_lines'),
  SyncedTable('goods_receipts'),
  SyncedTable('goods_receipt_items'),
  SyncedTable('recipe_lines'),
];
