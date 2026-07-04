import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/fraud_flags_dao.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/features/alert/data/alert_model.dart';
import 'package:pos/features/alert/presentation/cubit/fraud_state.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';

class FraudCubit extends Cubit<FraudState> {
  final FraudFlagsDao _flagsDao;
  final AppDatabase _db;
  final PermissionService _permissionService;
  final ActiveBusinessContext _activeBusinessContext;
  final AuditLogService _auditLogService;

  StreamSubscription<List<FraudFlagRow>>? _sub;
  Map<String, String> _nameByUserId = const {};
  Map<String, String> _branchNameById = const {};
  String? _ownerUserId;

  FraudCubit({
    required FraudFlagsDao flagsDao,
    required AppDatabase db,
    required PermissionService permissionService,
    required ActiveBusinessContext activeBusinessContext,
    required AuditLogService auditLogService,
  })  : _flagsDao = flagsDao,
        _db = db,
        _permissionService = permissionService,
        _activeBusinessContext = activeBusinessContext,
        _auditLogService = auditLogService,
        super(const FraudLoading());

  bool get canResolve =>
      _permissionService.can(PermissionKeys.fraudResolve);

  /// Client mirror of the server's self-resolution block: you never triage a
  /// flag that implicates YOU. RLS enforces this regardless of the UI.
  bool canResolveAlert(FraudAlert alert) {
    if (!canResolve) return false;
    final me = _activeBusinessContext.userId;
    if (alert.subjectUserId == null || me == null) return true;
    if (alert.subjectUserId == me && me != _ownerUserId) return false;
    return true;
  }

  Future<void> load() async {
    final businessId = _activeBusinessContext.businessId;
    if (businessId == null || businessId.isEmpty) {
      emit(const FraudError('No active business.'));
      return;
    }
    try {
      await _loadLookups(businessId);

      // Client mirror of the server's branch scoping: without cross-branch
      // access, only your own branch's flags are shown.
      final branchId = _permissionService
              .can(PermissionKeys.dataCrossBranchAccess)
          ? null
          : ((_activeBusinessContext.branchId?.isNotEmpty ?? false)
              ? _activeBusinessContext.branchId
              : null);

      await _sub?.cancel();
      _sub = _flagsDao
          .watchByBusiness(businessId, branchId: branchId)
          .listen((rows) {
        if (isClosed) return;
        emit(FraudLoaded(
          alerts: [
            for (final row in rows)
              FraudAlert.fromRow(
                row,
                nameFor: _nameFor,
                branchNameFor: _branchNameFor,
              ),
          ],
        ));
      });
    } catch (e, st) {
      debugPrint('[FraudCubit] Error in load: $e\n$st');
      if (!isClosed) {
        emit(const FraudError('Could not load fraud alerts.'));
      }
    }
  }

  Future<void> setStatus(
    FraudAlert alert,
    AlertStatus status,
    String? note,
  ) async {
    // Permission checks live in business logic, not just hidden UI.
    if (!canResolveAlert(alert)) return;
    try {
      await _flagsDao.resolve(
        id: alert.id,
        status: status.dbValue,
        resolvedBy: _activeBusinessContext.userId ?? '',
        resolutionNote: note,
      );
      _auditLogService.log(
        actionType: AuditLogActionType.fraudFlagResolved,
        entityType: 'fraud_flag',
        entityId: alert.id,
        description:
            'Fraud alert "${alert.title}" marked ${status.dbValue}',
        metadata: {
          'rule_code': alert.ruleCode,
          'status': status.dbValue,
          'note': ?note,
        },
      );
    } catch (e, st) {
      debugPrint('[FraudCubit] Error in setStatus: $e\n$st');
    }
  }

  Future<void> _loadLookups(String businessId) async {
    final employees = await _db
        .customSelect(
          'SELECT user_id, auth_user_id, full_name FROM employees '
          'WHERE business_id = ?',
          variables: [Variable.withString(businessId)],
        )
        .get();
    final names = <String, String>{};
    for (final r in employees) {
      final name = r.readNullable<String>('full_name') ?? '';
      if (name.isEmpty) continue;
      final userId = r.readNullable<String>('user_id');
      final authUserId = r.readNullable<String>('auth_user_id');
      if (userId != null && userId.isNotEmpty) names[userId] = name;
      if (authUserId != null && authUserId.isNotEmpty) names[authUserId] = name;
    }
    _nameByUserId = names;

    final branches = await _db
        .customSelect(
          'SELECT id, name FROM branches WHERE business_id = ?',
          variables: [Variable.withString(businessId)],
        )
        .get();
    _branchNameById = {
      for (final r in branches)
        r.read<String>('id'): r.readNullable<String>('name') ?? 'Branch',
    };

    final owner = await _db
        .customSelect(
          'SELECT owner_id FROM businesses WHERE id = ? LIMIT 1',
          variables: [Variable.withString(businessId)],
        )
        .getSingleOrNull();
    _ownerUserId = owner?.readNullable<String>('owner_id');
  }

  String _nameFor(String userId) {
    if (userId == _ownerUserId) return 'Owner';
    return _nameByUserId[userId] ?? 'Unknown user';
  }

  String _branchNameFor(String? branchId) {
    // A null branch means the flag is not scoped to one branch (audit-chain
    // tampering spanning devices, control-plane changes). "Business-wide" reads
    // truthfully; "All branches" wrongly implied every branch was involved.
    if (branchId == null || branchId.isEmpty) return 'Business-wide';
    return _branchNameById[branchId] ?? 'Branch';
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
