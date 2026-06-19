import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/audit_logs/domain/entities/audit_log.dart';
import 'package:pos/features/audit_logs/domain/repositories/i_audit_log_repository.dart';

class AuditLogRepositoryImpl implements IAuditLogRepository {
  final AuditLogsDao _dao;

  AuditLogRepositoryImpl({required AuditLogsDao dao}) : _dao = dao;

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
}
