import 'package:drift/drift.dart';

/// Local cache of business templates (read-only, synced from server).
/// Run `dart run build_runner build --delete-conflicting-outputs` after
/// modifying this file to regenerate app_database.g.dart.
class BusinessTemplatesTable extends Table {
  @override
  String get tableName => 'business_templates';

  TextColumn get id => text()();

  /// Stable machine-readable key matching business_templates.code on server.
  TextColumn get code => text().withDefault(const Constant(''))();

  TextColumn get name => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get localUpdatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
