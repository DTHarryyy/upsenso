import 'package:drift/drift.dart';

/// Local mirror of the Supabase `invoice_sequences` counter.
/// One row per (business_id, month_key). The local counter is used when the
/// Supabase RPC is unreachable (offline); both produce the same format.
class InvoiceSequencesTable extends Table {
  @override
  String get tableName => 'invoice_sequences';

  TextColumn get businessId => text()();
  // No longer a calendar month — InvoiceNumberService always passes a fixed
  // bucket key ('seq') so each business gets one continuously-rising counter.
  // Column name kept as-is to avoid an unnecessary schema migration.
  TextColumn get monthKey => text()();
  IntColumn get lastValue => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {businessId, monthKey};
}
