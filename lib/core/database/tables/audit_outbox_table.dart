import 'package:drift/drift.dart';

/// Staging queue that makes audit logging atomic with the business write it
/// describes: the caller inserts an outbox row INSIDE its own Drift
/// transaction (so a refund can never commit without its audit intent), and
/// AuditLogService.drainOutbox() later turns each row into a chained
/// audit_logs entry, deleting the outbox row in the same transaction as the
/// chained insert. Local-only — never synced.
@DataClassName('AuditOutboxRow')
class AuditOutboxTable extends Table {
  @override
  String get tableName => 'audit_outbox';

  IntColumn get id => integer().autoIncrement()();

  /// JSON-encoded audit intent (action_type, entity, description, metadata,
  /// business/branch/user ids, enqueued_at) — see AuditLogService.
  TextColumn get payload => text()();

  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
