import 'package:drift/drift.dart';

@DataClassName('AuditLogRow')
class AuditLogsTable extends Table {
  @override
  String get tableName => 'audit_logs';

  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get branchId => text()();
  TextColumn get userId => text()();
  TextColumn get actionType => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text().nullable()();
  TextColumn get description => text()();

  /// JSON-encoded map of additional context (amounts, names, etc.)
  TextColumn get metadata => text().withDefault(const Constant('{}'))();

  TextColumn get deviceId => text().withDefault(const Constant('unknown'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 0=pendingUpload, 3=synced, 4=failed  (audit logs are append-only)
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
