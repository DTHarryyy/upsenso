import 'package:drift/drift.dart';

/// Local table for line-items belonging to a completed POS transaction.
/// Stored locally only — no Supabase equivalent table exists.
class TransactionItemsTable extends Table {
  @override
  String get tableName => 'transaction_items';

  TextColumn get id => text()();
  TextColumn get transactionId => text()();
  TextColumn get variantId => text()();
  TextColumn get productName => text()(); // snapshot at sale time
  TextColumn get variantName => text()(); // snapshot at sale time
  RealColumn get unitPrice => real()();
  RealColumn get taxRate => real().nullable()(); // e.g. 12.0 = 12%; null = no tax
  RealColumn get qty => real()();
  RealColumn get lineTotal => real()(); // unitPrice * qty
  RealColumn get lineTax => real()(); // taxAmount

  @override
  Set<Column> get primaryKey => {id};
}
