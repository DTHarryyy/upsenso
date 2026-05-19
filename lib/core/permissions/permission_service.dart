import 'package:flutter/foundation.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/permissions/app_feature.dart';
import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/data_scope.dart';
import 'package:pos/core/permissions/profile_field.dart';
import 'package:pos/core/permissions/role_permission_matrix.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';

/// Result returned by [PermissionService.guard].
class PermissionResult {
  final bool granted;

  /// Non-null and non-empty when [granted] is false.
  final String? deniedReason;

  const PermissionResult.granted() : granted = true, deniedReason = null;
  const PermissionResult.denied(String reason)
    : granted = false,
      deniedReason = reason;

  @override
  String toString() => granted
      ? 'PermissionResult.granted'
      : 'PermissionResult.denied($deniedReason)';
}

/// Central permission service for UPSENSO.
///
/// Responsibilities:
/// 1. Sync [hasPermission] check — used by UI widgets ([PermissionGate]) and
///    BLoCs that need an immediate answer without waiting for I/O.
/// 2. Async [guard] — checks permission AND writes a
///    [AuditLogActionType.permissionDenied] entry when access is blocked.
/// 3. Role update — [setRole] is called by [AuthBloc] whenever the current
///    user's context changes so sync checks always reflect the live session.
///
/// All permission decisions are derived from [RolePermissionMatrix], which is
/// the SINGLE SOURCE OF TRUTH.  Never put permission logic in BLoCs or widgets.
///
/// Offline-first guarantee:
///   The role name is cached in the local Drift [AuthContextTable] and mirrored
///   in memory by [setRole].  Sync checks never touch the network.
class PermissionService {
  final AuthContextDao _authContextDao;
  final AuditLogService _auditLogService;

  /// In-memory role key (snake_case), kept in sync with [AuthContextTable].
  String? _roleKey;

  PermissionService({
    required AuthContextDao authContextDao,
    required AuditLogService auditLogService,
  }) : _authContextDao = authContextDao,
       _auditLogService = auditLogService;

  // ── Role management ───────────────────────────────────────────────────────

  /// Notify the service that the current user's role has changed.
  ///
  /// Call this from [AuthBloc] every time the authenticated state is emitted:
  /// ```dart
  /// sl<PermissionService>().setRole(user.roleName);
  /// ```
  void setRole(String? roleName) {
    _roleKey = RolePermissionMatrix.normalise(roleName);
    debugPrint('[PermissionService] role set → $_roleKey');
  }

  /// Current normalised role key.  `null` means no session / not logged in.
  String? get currentRoleKey => _roleKey;

  // ── Sync permission check (offline-safe, no I/O) ─────────────────────────

  /// Returns `true` if the current user has [permission].
  ///
  /// Uses the in-memory [_roleKey] — always works offline.
  bool hasPermission(AppPermission permission) =>
      RolePermissionMatrix.allows(_roleKey, permission);

  /// Returns `true` if the current user has ALL of [permissions].
  bool hasAllPermissions(Iterable<AppPermission> permissions) =>
      permissions.every(hasPermission);

  /// Returns `true` if the current user has ANY of [permissions].
  bool hasAnyPermission(Iterable<AppPermission> permissions) =>
      permissions.any(hasPermission);

  /// Full set of permissions for the current user.
  Set<AppPermission> get currentPermissions =>
      RolePermissionMatrix.permissionsFor(_roleKey);

  // ── Async guard with audit logging ────────────────────────────────────────

  /// Check [permission] and — when access is denied — write a
  /// [AuditLogActionType.permissionDenied] audit entry.
  ///
  /// Use in BLoCs before executing restricted operations:
  /// ```dart
  /// final result = await sl<PermissionService>().guard(
  ///   AppPermission.refundSale,
  ///   entityType: 'transaction',
  ///   entityId: transactionId,
  /// );
  /// if (!result.granted) {
  ///   emit(PosError(result.deniedReason!));
  ///   return;
  /// }
  /// ```
  Future<PermissionResult> guard(
    AppPermission permission, {
    String? entityType,
    String? entityId,
    String? entityName,
    String? description,
  }) async {
    if (hasPermission(permission)) return const PermissionResult.granted();

    // Resolve role name from auth context (offline — reads local Drift DB).
    final ctx = await _authContextDao.getAny();
    final roleName = ctx?.roleName ?? _roleKey ?? 'unknown';
    final reason = permission.deniedMessage;

    await _auditLogService.log(
      actionType: AuditLogActionType.permissionDenied,
      entityType: entityType ?? 'system',
      entityId: entityId,
      entityName: entityName,
      description:
          description ??
          'Permission denied: ${permission.name} for role "$roleName".',
      metadata: {
        'permission': permission.name,
        'role': roleName,
        'entity_type': entityType,
        'entity_id': entityId,
      },
    );

    debugPrint(
      '[PermissionService] DENIED — ${permission.name} for role "$roleName"',
    );

    return PermissionResult.denied(reason);
  }

  // ── Bulk guards ───────────────────────────────────────────────────────────

  /// Guard multiple permissions at once.  Logs the FIRST denial found.
  Future<PermissionResult> guardAll(
    List<AppPermission> permissions, {
    String? entityType,
    String? entityId,
  }) async {
    for (final p in permissions) {
      final result = await guard(p, entityType: entityType, entityId: entityId);
      if (!result.granted) return result;
    }
    return const PermissionResult.granted();
  }

  // ── Lazy load from Drift ──────────────────────────────────────────────────

  /// Populate [_roleKey] from the local Drift auth context if not already set.
  /// Useful as a fallback during cold-start before [AuthBloc] fires.
  Future<void> loadFromCache() async {
    if (_roleKey != null && _roleKey!.isNotEmpty) return;
    final ctx = await _authContextDao.getAny();
    if (ctx?.roleName != null) {
      setRole(ctx!.roleName);
    }
  }

  // ── Feature access ────────────────────────────────────────────────────────

  /// Returns `true` if the current user is allowed to open [feature].
  /// Use this to guard navigation and module entry points.
  bool canAccessFeature(AppFeature feature) =>
      RolePermissionMatrix.canAccessFeature(_roleKey, feature);

  /// Set of all features accessible to the current user.
  Set<AppFeature> get currentFeatures =>
      RolePermissionMatrix.featuresFor(_roleKey);

  /// Async feature guard — checks access and logs denial.
  Future<PermissionResult> guardFeature(
    AppFeature feature, {
    String? description,
  }) async {
    if (canAccessFeature(feature)) return const PermissionResult.granted();

    final ctx = await _authContextDao.getAny();
    final roleName = ctx?.roleName ?? _roleKey ?? 'unknown';

    await _auditLogService.log(
      actionType: AuditLogActionType.permissionDenied,
      entityType: 'feature',
      entityId: feature.name,
      description:
          description ??
          'Feature access denied: ${feature.displayLabel} for role "$roleName".',
      metadata: {'feature': feature.name, 'role': roleName},
    );

    debugPrint(
      '[PermissionService] FEATURE DENIED — ${feature.name} for role "$roleName"',
    );

    return PermissionResult.denied(feature.deniedMessage);
  }

  // ── Data scope ────────────────────────────────────────────────────────────

  /// Returns the [DataScope] for the current user based on their role and
  /// cached auth context.  This is synchronous — reads from in-memory cache.
  ///
  /// Used by [DataScopingLayer] and repositories to scope queries.
  DataScope getDataScope() {
    final scopeType = RolePermissionMatrix.dataScopeTypeFor(_roleKey);
    switch (scopeType) {
      case DataScopeType.allBranches:
        return const DataScope.unrestricted();
      case DataScopeType.branchOnly:
        return DataScope.branch(_branchId ?? '');
      case DataScopeType.ownOnly:
        return DataScope.own(branchId: _branchId ?? '', userId: _userId ?? '');
    }
  }

  // ── Profile field access ──────────────────────────────────────────────────

  /// Returns `true` if the current user may edit [field] on their own profile.
  bool canEditProfileField(ProfileField field) =>
      RolePermissionMatrix.canEditProfileField(_roleKey, field);

  /// Full set of profile fields the current user may edit.
  Set<ProfileField> get editableProfileFields =>
      RolePermissionMatrix.editableProfileFieldsFor(_roleKey);

  // ── Dashboard scope ───────────────────────────────────────────────────────

  /// Returns the [DashboardScope] for the current user.
  /// Controls which KPI cards and metrics are rendered on the dashboard.
  DashboardScope getDashboardScope() =>
      RolePermissionMatrix.dashboardScopeFor(_roleKey);

  // ── User context (needed for DataScope) ───────────────────────────────────

  String? _branchId;
  String? _userId;

  /// Update the full user context.  Call from [AuthBloc] alongside [setRole].
  /// ```dart
  /// sl<PermissionService>().setContext(
  ///   roleName: user.roleName,
  ///   branchId: user.branchId,
  ///   userId: user.id,
  /// );
  /// ```
  void setContext({
    required String? roleName,
    required String? branchId,
    required String? userId,
  }) {
    setRole(roleName);
    _branchId = branchId;
    _userId = userId;
  }
}
