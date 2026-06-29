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

  /// Fetches a user's most recent logs directly from Supabase — online-only,
  /// no local fallback. Use when the viewer's device may not hold the
  /// target user's local audit trail (e.g. a different employee's activity).
  Future<List<AuditLog>> getRemoteUserLogs({
    required String businessId,
    required String userId,
    String? actionType,
    List<String>? excludeActionTypes,
    int limit = 1,
  });
}
