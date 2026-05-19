import 'package:drift/drift.dart';

@DataClassName('EmployeeRow')
class EmployeesTable extends Table {
  @override
  String get tableName => 'employees';

  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get branchId => text()();

  /// Nullable – employee identity is decoupled from auth accounts.
  TextColumn get authUserId => text().nullable()();

  TextColumn get employeeCode => text()();
  TextColumn get fullName => text()();
  TextColumn get email => text()();
  TextColumn get phone => text().nullable()();

  /// 'owner' | 'branch_manager' | 'cashier' | 'inventory_staff'
  TextColumn get role => text()();

  /// 'active' | 'suspended' | 'archived'
  TextColumn get status => text().withDefault(const Constant('active'))();

  TextColumn get profileImageUrl => text().nullable()();
  DateTimeColumn get hiredAt => dateTime()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// 0=pendingUpload, 1=pendingUpdate, 2=pendingDelete, 3=synced, 4=failed
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
