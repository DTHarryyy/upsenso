import 'package:drift/drift.dart';

/// Line items for a held / suspended sale. Mirrors `transaction_items` but
/// belongs to a [DraftSalesTable] row and is mutable.
class DraftSaleItemsTable extends Table {
  @override
  String get tableName => 'draft_sale_items';

  TextColumn get id => text()();
  TextColumn get draftId => text()();
  TextColumn get variantId => text()();
  TextColumn get productName => text()();
  TextColumn get variantName => text()();
  RealColumn get unitPrice => real()();
  RealColumn get taxRate => real().nullable()();
  RealColumn get qty => real()();
  RealColumn get lineTotal => real()();
  RealColumn get lineTax => real()();

  @override
  Set<Column> get primaryKey => {id};
}
