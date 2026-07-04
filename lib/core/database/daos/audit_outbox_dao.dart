import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/audit_outbox_table.dart';

part 'audit_outbox_dao.g.dart';

@DriftAccessor(tables: [AuditOutboxTable])
class AuditOutboxDao extends DatabaseAccessor<AppDatabase>
    with _$AuditOutboxDaoMixin {
  AuditOutboxDao(super.db);

  /// Rows that repeatedly fail stop being retried but are kept for forensics
  /// (a vanishing outbox row would be a silent audit drop — the exact failure
  /// mode this table exists to remove).
  static const int maxAttempts = 10;

  /// Plain insert — joins the CALLER's transaction when invoked inside one,
  /// which is the whole point: the audit intent commits or rolls back with
  /// the business write it describes.
  Future<void> enqueue(String payload) {
    return into(auditOutboxTable)
        .insert(AuditOutboxTableCompanion.insert(payload: payload));
  }

  /// FIFO batch for the drain loop.
  Future<List<AuditOutboxRow>> getPending({int limit = 100}) {
    return (select(auditOutboxTable)
          ..where((t) => t.attempts.isSmallerThanValue(maxAttempts))
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(limit))
        .get();
  }

  Future<void> deleteById(int id) {
    return (delete(auditOutboxTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> markAttempt(int id, String error) {
    return customUpdate(
      'UPDATE audit_outbox SET attempts = attempts + 1, last_error = ? '
      'WHERE id = ?',
      variables: [Variable.withString(error), Variable<int>(id)],
      updates: {auditOutboxTable},
    );
  }
}
