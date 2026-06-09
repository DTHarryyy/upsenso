import 'package:drift/drift.dart';

@DataClassName('EmployeeRow')
class EmployeesTable extends Table {
  @override
  String get tableName => 'employees';

  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get authUserId => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get fullName => text().nullable()();
  TextColumn get roleId => text().nullable()();

  /// Denormalized from roles join — avoids a local join on every read.
  TextColumn get roleName => text().nullable()();

  /// Denormalized primary branch from employee_branches join table.
  TextColumn get branchId => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().nullable()();

  /// 0=pendingUpload, 1=pendingUpdate, 2=pendingDelete, 3=synced, 4=failed
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
