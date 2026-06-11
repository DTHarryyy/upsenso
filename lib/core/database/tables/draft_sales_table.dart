import 'package:drift/drift.dart';

/// Local-only table for held / suspended sales ("Save for Later").
///
/// A draft is a mutable snapshot of an in-progress cart — NOT a transaction.
/// It never deducts inventory and never appears in reports or sales history.
/// On checkout it is converted into a real `transactions` row and soft-deleted.
///
/// Phase 1 is device-local: drafts are not synced to Supabase. The sync
/// triplet columns exist so a future cross-device phase can opt in without a
/// second migration.
class DraftSalesTable extends Table {
  @override
  String get tableName => 'draft_sales';

  TextColumn get id => text()();
  TextColumn get businessId => text().nullable()();
  TextColumn get branchId => text().nullable()();
  TextColumn get cashierId => text()();

  /// Optional human label e.g. "Table 5", "Mrs. Cruz".
  TextColumn get label => text().nullable()();
  TextColumn get customerName => text().nullable()();

  // ── Snapshot totals (for list display without joining items) ──────────────
  RealColumn get subtotal => real()();
  RealColumn get taxAmount => real()();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get totalAmount => real()();
  IntColumn get itemCount => integer()();

  // ── Discount snapshot (so it restores exactly on resume) ──────────────────
  /// 'percentage' | 'fixed' | null
  TextColumn get discountType => text().nullable()();
  RealColumn get discountValue => real().nullable()();

  /// open | converted | voided
  TextColumn get status => text().withDefault(const Constant('open'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Soft delete — set when converted or discarded.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  // ── Sync tracking (unused in Phase 1; reserved for cross-device sync) ─────
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
