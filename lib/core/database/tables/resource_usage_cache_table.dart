import 'package:drift/drift.dart';

/// Cached structural-resource usage counts ("2 of 3 seats") for the billing
/// UI meters. Written only by the entitlement sync path; informational only —
/// the server RLS counts live rows when it actually enforces a cap.
///
/// This table is schema version 58.
@DataClassName('ResourceUsageCacheRow')
class ResourceUsageCacheTable extends Table {
  @override
  String get tableName => 'resource_usage_cache';

  TextColumn get businessId => text()();

  IntColumn get branchCount => integer().withDefault(const Constant(0))();
  IntColumn get activeSeatCount => integer().withDefault(const Constant(0))();
  IntColumn get deviceCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {businessId};
}
