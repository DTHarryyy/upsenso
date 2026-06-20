import 'package:drift/drift.dart';

/// Header row for one refund event against a transaction. Append-only —
/// refunds are never edited or merged, only inserted, so concurrent offline
/// refunds on different devices can't clobber each other under LWW sync.
/// Syncs to the Supabase `refunds` table.
class RefundsTable extends Table {
  @override
  String get tableName => 'refunds';

  TextColumn get id => text()();
  TextColumn get transactionId => text()(); // → transaction_id (FK)
  TextColumn get businessId => text()(); // → business_id (tenant, NOT NULL)
  TextColumn get branchId => text().nullable()(); // → branch_id
  TextColumn get refundedBy => text()(); // → refunded_by (user id)
  RealColumn get totalAmount => real()(); // → total_amount
  RealColumn get taxAmount =>
      real().withDefault(const Constant(0.0))(); // → tax_amount
  TextColumn get reason => text().nullable()(); // → reason
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  // Delta-sync cursor — mirrors the client_updated_at LWW pattern used by
  // every other synced table, even though refund rows themselves are never
  // updated after insert (kept for pull-cursor consistency).
  DateTimeColumn get clientUpdatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  // ── Sync tracking (same pattern as every other table) ───────────────────
  /// 0=pendingUpload, 1=pendingUpdate, 2=pendingDelete, 3=synced, 4=failed
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
