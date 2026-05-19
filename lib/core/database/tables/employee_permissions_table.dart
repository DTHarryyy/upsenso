import 'package:drift/drift.dart';

/// Drift table that caches the per-employee permission matrix locally.
///
/// Keyed by [authUserId] (Supabase auth.uid()).
/// [permissionsJson] stores a JSON-encoded [Map<String, bool>].
///
/// This table is schema version 26.
@DataClassName('EmployeePermissionsRow')
class EmployeePermissionsTable extends Table {
  @override
  String get tableName => 'employee_permissions_cache';

  /// Supabase auth.uid() — also the Drift primary key.
  TextColumn get authUserId => text()();

  /// The employee record UUID in the employees table.
  /// Nullable for the rare case where the record hasn't synced yet.
  TextColumn get employeeId => text().nullable()();

  /// JSON-encoded `Map<String, bool>`: `{"pos.use": true, ...}`.
  TextColumn get permissionsJson => text().withDefault(const Constant('{}'))();

  /// Timestamp of the last successful sync from Supabase.
  /// Null when the row was seeded locally from the role matrix.
  DateTimeColumn get syncedAt => dateTime().nullable()();

  /// Last time this row was written (by load or sync).
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {authUserId};
}
