import 'package:drift/drift.dart';

/// Drift table that caches business module on/off state locally.
///
/// Keyed by (businessId, moduleCode) — same composite PK as the Supabase
/// `business_modules` table.  Populated by [BusinessModulesDao] during
/// [PermissionService.syncModules].
///
/// This table is schema version 28.
@DataClassName('BusinessModuleRow')
class BusinessModulesTable extends Table {
  @override
  String get tableName => 'business_modules_local';

  TextColumn get businessId => text().named('business_id')();
  TextColumn get moduleCode => text().named('module_code')();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Last time this row was written from Supabase.
  DateTimeColumn get syncedAt => dateTime().named('synced_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {businessId, moduleCode};
}
