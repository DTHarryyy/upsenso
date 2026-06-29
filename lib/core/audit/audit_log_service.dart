import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/device/device_info_service.dart';
import 'package:pos/core/session/active_business_context.dart';
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
  final ActiveBusinessContext _activeBusinessContext;
  final DeviceInfoService _deviceInfoService;
  static const _uuid = Uuid();

  AuditLogService({
    required AuditLogsDao dao,
    required AuthContextDao authContextDao,
    required ActiveBusinessContext activeBusinessContext,
    required DeviceInfoService deviceInfoService,
  }) : _dao = dao,
       _authContextDao = authContextDao,
       _activeBusinessContext = activeBusinessContext,
       _deviceInfoService = deviceInfoService;

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
      // Resolve from the AUTHORITATIVE active session first; fall back to the
      // single cached auth row only for cold-start writes before AuthBloc has
      // bound the active context. Never resolve a tenant from a "first row"
      // lookup of an arbitrary account.
      final active = _activeBusinessContext;
      final ctx = active.hasBusiness ? null : await _authContextDao.getAny();
      final activeBusinessId = active.businessId ?? ctx?.businessId;

      final resolvedBusinessId = businessId ?? activeBusinessId ?? '';
      final resolvedBranchId = branchId ?? active.branchId ?? ctx?.branchId ?? '';
      final resolvedUserId = userId ?? active.userId ?? ctx?.userId ?? '';
      // Prefer explicitly supplied name, then active/cached full name.
      final resolvedUserName = userName ?? active.fullName ?? ctx?.fullName;
      final resolvedBranchNameSource =
          active.branchName ?? ctx?.branchName;
      // Use branch name from context; fall back to 'All Branches' when the
      // resolved user has no assigned branch (Business Owner / all-branch access).
      final resolvedBranchName =
          resolvedBranchNameSource?.trim().isNotEmpty == true
          ? resolvedBranchNameSource
          : (resolvedBranchId.isEmpty ? 'All Branches' : null);

      if (resolvedBusinessId.isEmpty) return; // no session — skip silently

      final deviceLabel = await _deviceInfoService.getDeviceLabel();

      // Tenant guard: if a session is active, never write a log attributed to a
      // different business than the active one. Drop it rather than corrupt
      // another tenant's audit trail.
      if (activeBusinessId != null &&
          activeBusinessId.isNotEmpty &&
          resolvedBusinessId != activeBusinessId) {
        debugPrint(
          '[AuditLogService] dropped log for $resolvedBusinessId — '
          'active business is $activeBusinessId',
        );
        return;
      }

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
          deviceId: Value(deviceLabel),
        ),
      );
    } catch (e, st) {
      // Audit logging must never crash the caller.
      debugPrint('[AUDIT] Failed to write log: $e\n$st');
    }
  }
}
