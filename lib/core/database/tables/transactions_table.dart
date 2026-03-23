import 'package:drift/drift.dart';

/// Local table for completed POS transactions.
/// Syncs to the existing Supabase `transactions` table.
/// Local-only fields (customer_name, payment_method, subtotal, amount_received,
/// change_due, item_count) are NOT sent to Supabase.
class TransactionsTable extends Table {
  @override
  String get tableName => 'transactions';

  TextColumn get id => text()();
  TextColumn get branchId => text().nullable()(); // → branch_id
  TextColumn get cashierId => text()(); // → cashier_id (logged-in user)
  TextColumn get shiftId => text().nullable()(); // → shift_id (null for now)
  RealColumn get totalAmount => real()(); // → total_amount
  RealColumn get discountAmount =>
      real().withDefault(const Constant(0.0))(); // → discount_amount
  RealColumn get taxAmount => real()(); // → tax_amount
  TextColumn get status =>
      text().withDefault(const Constant('completed'))(); // → status
  TextColumn get transactionHash =>
      text().nullable()(); // → transaction_hash (null)
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  // ── Local-only fields (not present in Supabase schema) ──────────────────
  TextColumn get customerName => text().nullable()();
  TextColumn get paymentMethod =>
      text().withDefault(const Constant('cash'))();
  RealColumn get subtotal => real()();
  RealColumn get amountReceived => real().nullable()();
  RealColumn get changeDue => real().nullable()();
  IntColumn get itemCount => integer()();

  // ── Sync tracking (same pattern as every other table) ───────────────────
  /// 0=pendingUpload, 1=pendingUpdate, 2=pendingDelete, 3=synced, 4=failed
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
