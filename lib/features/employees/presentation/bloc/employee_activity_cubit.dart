import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/audit_logs/domain/repositories/i_audit_log_repository.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';
import 'package:pos/features/employees/presentation/bloc/employee_activity_state.dart';

/// Resolves Last Login, Device, and Recent Activity for the Security &
/// Activity card.
///
/// Reads straight from Supabase rather than the local audit trail: the
/// employee being viewed may have logged in / acted on a different device
/// than the one viewing this page, and audit logs only sync device → server,
/// never back down — so the local DB can't be relied on here.
class EmployeeActivityCubit extends Cubit<EmployeeActivityState> {
  final IAuditLogRepository _repository;

  EmployeeActivityCubit(this._repository) : super(EmployeeActivityLoading());

  Future<void> load(Employee employee) async {
    final authUserId = employee.authUserId;
    // No auth account (e.g. record-only employee) — nothing to derive.
    if (authUserId == null || authUserId.isEmpty) {
      emit(EmployeeActivityLoaded());
      return;
    }
    try {
      final loginLogs = await _repository.getRemoteUserLogs(
        businessId: employee.businessId,
        userId: authUserId,
        actionType: AuditLogActionType.userLogin.value,
        limit: 1,
      );
      final recentLogs = await _repository.getRemoteUserLogs(
        businessId: employee.businessId,
        userId: authUserId,
        limit: 1,
      );

      final lastLoginLog = loginLogs.isNotEmpty ? loginLogs.first : null;
      final deviceId = lastLoginLog?.deviceId;
      final device =
          (deviceId != null && deviceId.isNotEmpty && deviceId != 'unknown')
              ? deviceId
              : null;
      final recentLog = recentLogs.isNotEmpty ? recentLogs.first : null;

      emit(
        EmployeeActivityLoaded(
          lastLogin: lastLoginLog?.createdAt,
          device: device,
          recentActivityLabel: recentLog?.actionType.displayLabel,
          recentActivityTime: recentLog?.createdAt,
        ),
      );
    } catch (e, st) {
      debugPrint('[EmployeeActivityCubit] Error in load: $e\n$st');
      emit(EmployeeActivityLoaded());
    }
  }
}
