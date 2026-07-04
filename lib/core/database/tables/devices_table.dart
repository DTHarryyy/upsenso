import 'package:drift/drift.dart';

/// One row per audit chain identity (device_uid) — the normalized home for a
/// device's display label, which used to be repeated on every audit_logs row
/// (and flapped between "Web · chrome"/"Web · safari" for one physical device
/// on 2026-07-03). The label is resolved once per uid and lives here; audit
/// rows reference the uid.
///
/// Synced so the owner's verify UI can name every device by a stable label,
/// not just the ones whose audit rows it happened to pull.
@DataClassName('DeviceRow')
class DevicesTable extends Table {
  @override
  String get tableName => 'devices';

  /// Stable installation uid (DeviceIdentityService) — the chain key.
  TextColumn get deviceUid => text()();

  TextColumn get businessId => text()();

  /// Human label, e.g. "Pixel 7 · Android 14" / "Web · chrome". Resolved once.
  TextColumn get label => text()();

  /// 'web' | 'android' | 'ios' | 'windows' | 'macos' | 'linux' | 'unknown'.
  TextColumn get platform => text().withDefault(const Constant('unknown'))();

  DateTimeColumn get firstSeenAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSeenAt => dateTime().withDefault(currentDateAndTime)();

  /// 0=pendingUpload, 1=pendingUpdate, 3=synced, 4=failed
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {deviceUid};
}
