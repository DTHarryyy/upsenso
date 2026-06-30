import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/audit_logs/data/datasources/audit_log_remote_ds.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/audit_logs/domain/entities/audit_log.dart';
import 'package:pos/features/audit_logs/domain/repositories/i_audit_log_repository.dart';

class AuditLogRepositoryImpl implements IAuditLogRepository {
  final AuditLogsDao _dao;
  final AuditLogRemoteDs _remoteDs;
  final ConnectivityService _connectivityService;

  AuditLogRepositoryImpl({
    required AuditLogsDao dao,
    required AuditLogRemoteDs remoteDs,
    required ConnectivityService connectivityService,
  }) : _dao = dao,
       _remoteDs = remoteDs,
       _connectivityService = connectivityService;

  @override
  Future<List<AuditLog>> getLogs({
    required String businessId,
    String? branchId,
    String? userId,
    String? actionType,
    DateTime? from,
    DateTime? to,
    int limit = 200,
  }) async {
    final rows = await _dao.getByBusiness(
      businessId,
      branchId: branchId,
      userId: userId,
      actionType: actionType,
      from: from,
      to: to,
      limit: limit,
    );
    return rows.map(_toEntity).toList();
  }

  @override
  Stream<List<AuditLog>> watchLogs({
    required String businessId,
    String? branchId,
    String? userId,
    String? actionType,
    int limit = 200,
  }) {
    return _dao
        .watchByBusiness(
          businessId,
          branchId: branchId,
          userId: userId,
          actionType: actionType,
          limit: limit,
        )
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<List<AuditLog>> getOlderFromServer({
    required String businessId,
    required DateTime from,
    DateTime? before,
    int limit = 200,
  }) async {
    if (!await _connectivityService.isConnected) {
      throw const AuditLogOfflineException();
    }
    final rows = await _remoteDs.getAuditLogsInRange(
      businessId,
      from: from,
      before: before,
      limit: limit,
    );
    return rows.map(_fromRemoteRow).toList();
  }

  @override
  Future<List<AuditLog>> getRemoteUserLogs({
    required String businessId,
    required String userId,
    String? actionType,
    List<String>? excludeActionTypes,
    int limit = 1,
  }) async {
    final rows = await _remoteDs.getByUser(
      businessId,
      userId,
      actionType: actionType,
      excludeActionTypes: excludeActionTypes,
      limit: limit,
    );
    return rows.map(_toEntityFromRemote).toList();
  }

  AuditLog _toEntityFromRemote(Map<String, dynamic> row) {
    final rawMetadata = row['metadata'];
    final metadata = rawMetadata is Map
        ? Map<String, dynamic>.from(rawMetadata)
        : <String, dynamic>{};
    return AuditLog(
      id: row['id'] as String,
      businessId: row['business_id'] as String,
      branchId: row['branch_id'] as String? ?? '',
      userId: row['user_id'] as String? ?? '',
      actionType:
          AuditLogActionTypeX.fromValue(row['action_type'] as String? ?? '') ??
          AuditLogActionType.syncStarted,
      entityType: row['entity_type'] as String? ?? '',
      entityId: row['entity_id'] as String?,
      description: row['description'] as String? ?? '',
      metadata: metadata,
      deviceId: row['device_id'] as String? ?? 'unknown',
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      syncStatus: 1,
    );
  }

  AuditLog _toEntity(AuditLogRow row) {
    Map<String, dynamic> meta = {};
    try {
      meta = Map<String, dynamic>.from(jsonDecode(row.metadata) as Map);
    } catch (e, st) {
      debugPrint('[AuditLogRepo] Malformed metadata for ${row.id}: $e\n$st');
    }

    return AuditLog(
      id: row.id,
      businessId: row.businessId,
      branchId: row.branchId,
      userId: row.userId,
      actionType:
          AuditLogActionTypeX.fromValue(row.actionType) ??
          AuditLogActionType.syncStarted,
      entityType: row.entityType,
      entityId: row.entityId,
      description: row.description,
      metadata: meta,
      deviceId: row.deviceId,
      createdAt: row.createdAt,
      syncStatus: row.syncStatus,
    );
  }

  /// Maps a raw row fetched live from the server — never persisted locally,
  /// so this mirrors [AuditLogsDao.upsertFromServer]'s defensive handling
  /// rather than sharing code with it (different layer, different output
  /// type). Same two gaps apply: trg_user_perm_audit / trg_branch_perm_audit
  /// / trg_module_audit write rows with no `action_type` or `description`.
  AuditLog _fromRemoteRow(Map<String, dynamic> row) {
    final actionTypeValue =
        row['action_type'] as String? ?? 'PERMISSION_TABLE_CHANGED';
    final description =
        row['description'] as String? ??
        '${row['action']} on ${row['entity_type']}';
    // metadata is jsonb — the Supabase client already decodes it to a Map.
    final metadata = row['metadata'] is Map
        ? Map<String, dynamic>.from(row['metadata'] as Map)
        : <String, dynamic>{};

    return AuditLog(
      id: row['id'] as String,
      businessId: row['business_id'] as String,
      branchId: row['branch_id'] as String? ?? '',
      userId: row['user_id'] as String? ?? '',
      actionType:
          AuditLogActionTypeX.fromValue(actionTypeValue) ??
          AuditLogActionType.syncStarted,
      entityType: row['entity_type'] as String,
      entityId: row['entity_id'] as String?,
      description: description,
      metadata: metadata,
      deviceId: row['device_id'] as String? ?? 'unknown',
      createdAt: DateTime.parse(row['created_at'] as String),
      syncStatus: SyncStatus.synced.toInt(),
    );
  }
}
