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
}
