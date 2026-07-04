import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/daos/fraud_flags_dao.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';

/// One-time cleanup of the false-positive flags from the 2026-07-03 fraud
/// incident (see docs/UPSENSO_FRAUD_FALSE_POSITIVE_FIX_PLAN.md, P0.4).
///
/// The rules AUDIT_TAMPER / ORPHANED_RECORD / TIME_REVERSAL false-positived on
/// stale-mirror and chain-reconciliation artifacts; every such flag detected
/// *before this fixed build first ran* is one of them. They are dismissed
/// (never hard-deleted — that would destroy the forensic record) and pushed
/// to the server with their resolution, and one chained audit entry records
/// the cleanup. Gated by `fraud.resolve`; runs once per install.
class FraudMaintenanceService {
  static const _doneKey = 'fraud_maintenance_v1_done';

  static const Set<String> _falsePositiveRules = {
    'AUDIT_TAMPER',
    'ORPHANED_RECORD',
    'TIME_REVERSAL',
  };

  final SharedPreferences _prefs;
  final FraudFlagsDao _flagsDao;
  final PermissionService _permissionService;
  final ActiveBusinessContext _activeBusinessContext;
  final AuditLogService _auditLogService;

  FraudMaintenanceService({
    required SharedPreferences prefs,
    required FraudFlagsDao flagsDao,
    required PermissionService permissionService,
    required ActiveBusinessContext activeBusinessContext,
    required AuditLogService auditLogService,
  })  : _prefs = prefs,
        _flagsDao = flagsDao,
        _permissionService = permissionService,
        _activeBusinessContext = activeBusinessContext,
        _auditLogService = auditLogService;

  /// Idempotent: safe to call on every startup. No-ops once done, when there
  /// is no session, or when the current user can't resolve flags (another
  /// device/session with the permission handles it, so the flag stays unset).
  Future<void> runIfNeeded() async {
    try {
      if (_prefs.getBool(_doneKey) ?? false) return;
      if (!_permissionService.can(PermissionKeys.fraudResolve)) return;
      final businessId = _activeBusinessContext.businessId;
      if (businessId == null || businessId.isEmpty) return;

      final resolvedBy = _activeBusinessContext.userId ?? '';
      // Everything of these rules detected before now (this fixed build's
      // first run) is a pre-fix false positive.
      final cutoff = DateTime.now();
      final count = await _flagsDao.bulkDismiss(
        businessId: businessId,
        ruleCodes: _falsePositiveRules,
        before: cutoff,
        resolvedBy: resolvedBy,
        note:
            'Auto-dismissed: 2026-07-03 false-positive incident '
            '(see docs/UPSENSO_FRAUD_FALSE_POSITIVE_FIX_PLAN.md).',
      );

      await _prefs.setBool(_doneKey, true);

      if (count > 0) {
        await _auditLogService.log(
          actionType: AuditLogActionType.fraudFlagResolved,
          entityType: 'fraud_flag',
          description:
              'Bulk-dismissed $count false-positive fraud flag(s) from the '
              '2026-07-03 incident',
          metadata: {
            'maintenance': 'fraud_maintenance_v1',
            'dismissed_count': count,
            'rule_codes': _falsePositiveRules.toList(),
          },
          businessId: businessId,
        );
        debugPrint('[FraudMaintenance] dismissed $count false-positive flag(s)');
      }
    } catch (e, st) {
      debugPrint('[FraudMaintenance] Error in runIfNeeded: $e\n$st');
    }
  }
}
