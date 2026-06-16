import 'package:drift/drift.dart';

/// Local mirror of the Supabase `invoice_sequences` counter.
/// One row per (business_id, month_key). The local counter is used when the
/// Supabase RPC is unreachable (offline); both produce the same format.
class InvoiceSequencesTable extends Table {
  @override
  String get tableName => 'invoice_sequences';

  TextColumn get businessId => text()();
  TextColumn get monthKey => text()(); // 'YYYYMM', e.g. '202606'
  IntColumn get lastValue => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {businessId, monthKey};
}
