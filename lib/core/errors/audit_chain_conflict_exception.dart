/// Marker written into audit_logs.sync_error when a push is rejected by the
/// server's ux_audit_chain unique index — i.e. the server already holds a
/// DIFFERENT row at this (business, device, seq). That's never a benign
/// retry: it means local history diverged from synced history (tampering,
/// or a chain restart that genesis-resume should have prevented). The
/// AUDIT_TAMPER fraud rule scans for this marker.
const String kChainConflictMarker = 'CHAIN_CONFLICT';

/// Thrown by the audit push path instead of swallowing 23505 when the
/// violated constraint is the chain index rather than the id primary key.
class AuditChainConflictException implements Exception {
  final String auditLogId;
  final String detail;

  AuditChainConflictException({required this.auditLogId, required this.detail});

  @override
  String toString() =>
      'AuditChainConflictException($auditLogId): $kChainConflictMarker $detail';
}
