import 'package:drift/drift.dart';

/// Local table for business templates (read-only from server)
/// These are synced from Supabase but not modified locally
class BusinessTemplatesTable extends Table {
  @override
  String get tableName => 'business_templates';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get defaultModules => text()(); // JSON string
  TextColumn get defaultRoles => text()(); // JSON string
  TextColumn get defaultPermissions => text()(); // JSON string
  RealColumn get defaultTaxRate => real().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get localUpdatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
