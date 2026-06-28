import 'package:drift/drift.dart';

/// Immutable history of every stock movement.
/// All stock changes MUST go through this table — direct writes to
/// inventory_levels are done by the repository after inserting here.
class StockLedgerTable extends Table {
  @override
  String get tableName => 'stock_ledger';

  TextColumn get id => text()();
  TextColumn get variantId => text()();
  TextColumn get productId => text()();

  /// NOT NULL — every movement must be traced to a specific branch.
  /// Historical rows migrated from v17 carry the sentinel value 'unknown'.
  TextColumn get branchId => text()();
  TextColumn get businessId => text()();

  /// 'IN' for incoming stock, 'OUT' for outgoing stock.
  TextColumn get changeType => text()();

  /// Always a positive value (direction determined by [changeType]).
  /// REAL to support fractional products (sellBy='fraction').
  RealColumn get quantity => real()();

  /// Stock level for this variant+branch immediately before this movement.
  /// Null for rows migrated from v17 (pre-snapshot era).
  RealColumn get quantityBefore => real().nullable()();

  /// Stock level for this variant+branch immediately after this movement.
  /// Null for rows migrated from v17 (pre-snapshot era).
  RealColumn get quantityAfter => real().nullable()();

  /// One of: 'Sale', 'Restock', 'Damage', 'Transfer', 'Adjustment'
  TextColumn get reason => text()();
  TextColumn get note => text().nullable()();

  /// Traceability of what caused this movement: 'sale', 'purchase_order',
  /// 'recipe_consumption', 'adjustment', etc. Lets audit/fraud queries tell a
  /// sale apart from a manual adjustment. Synced to Supabase, where server-side
  /// RLS cross-references [sourceId] against the real source document (see
  /// stock_ledger_source_document_check) — never trust this pair client-side.
  TextColumn get sourceType => text().nullable()();

  /// ID of the originating document (transaction id, refund id, PO id, …).
  /// No DB-level foreign key, but RLS verifies it against the real table for
  /// every source_type that has one — see [sourceType].
  TextColumn get sourceId => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 0=pendingUpload, 3=synced, 4=failed
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
