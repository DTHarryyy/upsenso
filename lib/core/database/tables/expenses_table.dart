import 'package:drift/drift.dart';

@DataClassName('ExpenseRow')
class ExpensesTable extends Table {
  @override
  String get tableName => 'expenses';

  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get branchId => text().nullable()();
  TextColumn get branchName => text().nullable()();
  TextColumn get category => text()();
  TextColumn get vendor => text()();
  RealColumn get amount => real()();

  /// 'pending' | 'approved' | 'rejected' | 'draft'
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  TextColumn get submittedById => text()();
  TextColumn get submittedByName => text()();
  TextColumn get approvedById => text().nullable()();
  TextColumn get approvedByName => text().nullable()();
  TextColumn get note => text().nullable()();

  DateTimeColumn get expenseDate => dateTime()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// 0=pendingUpload, 1=pendingUpdate, 2=pendingDelete, 3=synced, 4=failed
  IntColumn get syncStatus =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
