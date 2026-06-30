import 'package:pos/features/audit_logs/domain/entities/audit_log.dart';

abstract class IAuditLogRepository {
  /// Returns a paginated, filterable list of audit logs for a business.
  Future<List<AuditLog>> getLogs({
    required String businessId,
    String? branchId,
    String? userId,
    String? actionType,
    DateTime? from,
    DateTime? to,
    int limit = 200,
  });

  /// Stream that re-emits whenever new logs are written locally.
  Stream<List<AuditLog>> watchLogs({
    required String businessId,
    String? branchId,
    String? userId,
    String? actionType,
    int limit = 200,
  });

  /// Fetches history older than the on-device retention window directly from
  /// the server — the device only mirrors a rolling recent window locally
  /// (see auditLogLocalWindowDays), so anything older than that has to be
  /// read live rather than from the local cache.
  ///
  /// Throws [AuditLogOfflineException] when there's no usable connection —
  /// callers should show a connectivity-specific state, not a generic error.
  Future<List<AuditLog>> getOlderFromServer({
    required String businessId,
    required DateTime from,
    DateTime? before,
    int limit = 200,
  });
}

/// Thrown by [IAuditLogRepository.getOlderFromServer] when there's no
/// connection to reach the server — distinct from other failures so the UI
/// can show the "you're offline" state instead of a generic error.
class AuditLogOfflineException implements Exception {
  const AuditLogOfflineException();

  @override
  String toString() => 'AuditLogOfflineException: no connection to the server';
}
