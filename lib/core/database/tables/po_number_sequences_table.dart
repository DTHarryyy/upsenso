import 'package:drift/drift.dart';

/// Local mirror of the Supabase `po_number_sequences` counter.
/// One row per (business_id, month_key='YYYYMM'). Used to assign a sequential
/// PO number offline; the Supabase RPC assigns it online. Both produce the same
/// `PO-YYYYMM-NNNN` format.
class PoNumberSequencesTable extends Table {
  @override
  String get tableName => 'po_number_sequences';

  TextColumn get businessId => text()();
  TextColumn get monthKey => text()();
  IntColumn get lastValue => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {businessId, monthKey};
}
