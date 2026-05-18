import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';

/// Lightweight, fire-and-forget service for writing audit log entries.
///
/// Usage from any module:
/// ```dart
/// sl<AuditLogService>().log(
///   actionType: AuditLogActionType.saleCreated,
///   entityType: 'transaction',
///   entityId: tx.id,
///   description: 'Sale of \$${tx.totalAmount}',
///   metadata: {'total': tx.totalAmount, 'items': items.length},
/// );
/// ```
///
/// All writes are local-first (Drift). The SyncService picks them up in the
/// background and pushes them to Supabase.
class AuditLogService {
  final AuditLogsDao _dao;
  final AuthContextDao _authContextDao;
  static const _uuid = Uuid();

  AuditLogService({
    required AuditLogsDao dao,
    required AuthContextDao authContextDao,
  }) : _dao = dao,
       _authContextDao = authContextDao;

  /// Write an audit log entry.  Fire-and-forget — errors are swallowed so
  /// audit logging never breaks the caller's flow.
  ///
  /// [businessId], [branchId], [userId] can be omitted; they are resolved
  /// from the cached auth context when not provided.
  /// [entityName] is the human-readable name of the affected entity
  /// (e.g. product name, user display name).
  Future<void> log({
    required AuditLogActionType actionType,
    required String entityType,
    String? entityId,
    String? entityName,
    String? userName,
    required String description,
    Map<String, dynamic> metadata = const {},
    String? businessId,
    String? branchId,
    String? userId,
  }) async {
    try {
      final ctx = await _authContextDao.getAny();
      final resolvedBusinessId = businessId ?? ctx?.businessId ?? '';
      final resolvedBranchId = branchId ?? ctx?.branchId ?? '';
      final resolvedUserId = userId ?? ctx?.userId ?? '';
      // Prefer explicitly supplied name, then fall back to auth context full name.
      final resolvedUserName = userName ?? ctx?.fullName;
      // Use branch name from context; fall back to 'All Branches' when the
      // resolved user has no assigned branch (Super Admin / all-branch access).
      final resolvedBranchName = ctx?.branchName?.trim().isNotEmpty == true
          ? ctx!.branchName
          : (resolvedBranchId.isEmpty ? 'All Branches' : null);

      if (resolvedBusinessId.isEmpty) return; // no session — skip silently

      final enrichedMetadata = {
        ...metadata,
        if (resolvedUserName != null && resolvedUserName.isNotEmpty)
          '_user_name': resolvedUserName,
        if (resolvedBranchName != null && resolvedBranchName.isNotEmpty)
          '_branch_name': resolvedBranchName,
        if (entityName != null && entityName.isNotEmpty)
          '_entity_name': entityName,
      };

      await _dao.insert(
        AuditLogsTableCompanion.insert(
          id: _uuid.v4(),
          businessId: resolvedBusinessId,
          branchId: resolvedBranchId,
          userId: resolvedUserId,
          actionType: actionType.value,
          entityType: entityType,
          entityId: Value(entityId),
          description: description,
          metadata: Value(jsonEncode(enrichedMetadata)),
        ),
      );
    } catch (e, st) {
      // Audit logging must never crash the caller.
      debugPrint('[AUDIT] Failed to write log: $e\n$st');
    }
  }
}
