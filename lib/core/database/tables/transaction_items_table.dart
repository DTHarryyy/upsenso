import 'package:drift/drift.dart';

class TransactionItemsTable extends Table {
  @override
  String get tableName => 'transaction_items';

  TextColumn get id => text()();
  TextColumn get transactionId => text()();
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
