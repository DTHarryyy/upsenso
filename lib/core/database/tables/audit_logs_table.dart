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

  // ── Tamper-evident hash chain (M1) ─────────────────────────────────────
  // Nullable: rows written before v53 form the "pre-chain segment" and are
  // skipped by the verifier — no destructive backfill.

  /// Monotonic counter per (business_id, device_uid); clock-independent order.
  IntColumn get seq => integer().nullable()();

  /// `entry_hash` of the previous row in this device chain; genesis = 64 zeros.
  TextColumn get prevHash => text().nullable()();

  /// SHA-256 over prev_hash + canonical payload (see audit_hash.dart).
  TextColumn get entryHash => text().nullable()();

  /// Stable installation uid (DeviceIdentityService) — NOT the display label
  /// in [deviceId], which is non-unique and regenerated per cold start.
  TextColumn get deviceUid => text().nullable()();

  /// Canonicalization version the stored hash was computed under. NULL/1 =
  /// legacy rows (hash recompute skipped by the verifier; link/seq checks
  /// still run); 2+ = current rules in audit_hash.dart. Lets the canonical
  /// form evolve without mass-false-positiving history.
  IntColumn get hashVersion => integer().nullable()();

  /// 0=pendingUpload, 3=synced, 4=failed  (audit logs are append-only)
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
