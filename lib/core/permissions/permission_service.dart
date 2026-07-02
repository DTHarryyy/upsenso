import 'package:flutter/foundation.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/database/daos/business_modules_dao.dart';
import 'package:pos/core/database/daos/employee_permissions_dao.dart';
import 'package:pos/core/permissions/app_feature.dart';
import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/data_scope.dart';
import 'package:pos/core/permissions/default_permission_matrix.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/profile_field.dart';
import 'package:pos/core/permissions/role_permission_matrix.dart';
import 'package:pos/core/permissions/data/permission_remote_ds.dart';
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
/// 1. Sync [can] / [hasPermission] check — used by UI widgets ([PermissionGate])
///    and BLoCs that need an immediate answer without waiting for I/O.
/// 2. Async [guard] — checks permission AND writes a
///    [AuditLogActionType.permissionDenied] entry when access is blocked.
/// 3. Role update — [setContext] is called by [AuthBloc] whenever the current
///    user's context changes.
/// 4. Permissions loading — [loadPermissions] populates an in-memory
///    [Map<String, bool>] from the Drift cache (or derives it from the role
///    matrix on first run).  [syncPermissions] refreshes it from Supabase.
///
/// Permission check precedence:
///   1. [_permissionsMap] (loaded from Supabase / Drift cache)
///   2. [DefaultPermissionMatrix] (derived from role — offline cold-start)
///   3. `false` (deny by default)
///
/// Offline-first guarantee:
///   [_permissionsMap] is populated from the local Drift cache at startup.
///   Supabase is only consulted during [syncPermissions], which is non-blocking.
class PermissionService {
  final AuthContextDao _authContextDao;
  final ActiveBusinessContext _activeBusinessContext;
  final AuditLogService _auditLogService;
  final EmployeePermissionsDao _permissionsDao;
  final PermissionRemoteDs _permissionRemoteDs;
  final BusinessModulesDao _businessModulesDao;

  /// In-memory role key (snake_case), kept in sync with [AuthContextTable].
  String? _roleKey;

  String? _branchId;
  String? _userId;

  /// Per-employee permission matrix loaded from Supabase / Drift.
  /// Empty map = not yet loaded; fall back to [DefaultPermissionMatrix].
  Map<String, bool> _permissionsMap = {};

  /// Per-module enabled state for the current business.
  ///
  /// `null` = not loaded yet (treat all modules as enabled until first sync).
  /// Missing key = module never configured → defaults to enabled.
  Map<String, bool>? _moduleStates;

  /// Bumps whenever [_moduleStates] changes. The router and nav surfaces gate on
  /// modules; they listen to this so a toggle — made offline or arriving via
  /// background sync — re-runs route guards and repaints without a manual
  /// navigation.
  final ValueNotifier<int> _moduleGateRevision = ValueNotifier<int>(0);

  /// Reactive signal for module-gate changes. Merge into the router's
  /// `refreshListenable` and wrap module-gated UI to keep it in sync.
  ValueListenable<int> get moduleGateRevision => _moduleGateRevision;

  bool get _hasLoadedPermissions => _permissionsMap.isNotEmpty;

  /// The auth user ID currently bound to this service.
  String? get currentUserId => _userId;

  PermissionService({
    required AuthContextDao authContextDao,
    required ActiveBusinessContext activeBusinessContext,
    required AuditLogService auditLogService,
    required EmployeePermissionsDao permissionsDao,
    required PermissionRemoteDs permissionRemoteDs,
    required BusinessModulesDao businessModulesDao,
  }) : _authContextDao = authContextDao,
       _activeBusinessContext = activeBusinessContext,
       _auditLogService = auditLogService,
       _permissionsDao = permissionsDao,
       _permissionRemoteDs = permissionRemoteDs,
       _businessModulesDao = businessModulesDao;

  // ── Role management ───────────────────────────────────────────────────────

  /// Notify the service that the current user's role has changed.
  void setRole(String? roleName) {
    _roleKey = RolePermissionMatrix.normalise(roleName);
    debugPrint('[PermissionService] role set → $_roleKey');
  }

  /// Current normalised role key.  `null` means no session / not logged in.
  String? get currentRoleKey => _roleKey;

  /// True for the unrestricted owner-level roles. Procurement approval
  /// governance exempts owners from separation-of-duties — they hold ultimate
  /// authority and must never be dead-ended on their own POs.
  bool get isOwnerRole => RolePermissionMatrix.isOwnerRoleName(_roleKey);

  // ── NEW: per-employee permission map ──────────────────────────────────────

  /// Check a permission by its dot-notation key.
  ///
  /// Resolution order:
  ///  1. [_permissionsMap] (loaded from Supabase / Drift) — explicit grant/deny
  ///  2. [DefaultPermissionMatrix] (role-derived) — for keys ABSENT from the
  ///     loaded map. This makes newly-added permission keys forward-compatible:
  ///     a user whose stored matrix predates a key still resolves it from their
  ///     role default instead of being silently denied. An explicit `false`
  ///     stored in the map is preserved (it's present, not absent).
  ///  3. `false`
  ///
  /// A granted permission whose owning module is disabled for the business
  /// still resolves to `false` — the module gate must hold even for callers
  /// that check a raw permission key instead of going through
  /// [canAccessFeature] (e.g. [PermissionGate], route guards, bottom nav).
  bool can(String key) {
    final module = _moduleCodeForKey(key);
    if (module != null && !isModuleEnabled(module)) return false;

    if (_resolve(key)) return true;

    // A `nav.*` menu entry is also visible when the user can access the area it
    // opens. The permission editor grants the *access* keys (e.g.
    // `audit_logs.view`, `expenses.view`) but never the redundant `nav.*` keys —
    // so without this, granting access via an override would never surface the
    // More/bottom-nav item or pass the route guard. Resolving the access key
    // through `can` keeps its own module gate applied.
    if (key.startsWith('nav.')) {
      for (final access in _navAccessKeys(key)) {
        if (can(access)) return true;
      }
    }
    return false;
  }

  /// Raw resolution for one key: loaded map → role default → deny.
  bool _resolve(String key) {
    if (_hasLoadedPermissions) {
      return _permissionsMap[key] ??
          DefaultPermissionMatrix.forRole(_roleKey)[key] ??
          false;
    }
    return DefaultPermissionMatrix.forRole(_roleKey)[key] ?? false;
  }

  /// Access permission(s) that should also reveal a `nav.*` entry — holding any
  /// of them is treated as nav access for that area.
  static List<String> _navAccessKeys(String navKey) {
    switch (navKey) {
      case 'nav.pos':
        return const ['pos.use'];
      case 'nav.inventory':
        return const ['inventory.view', 'inventory.view_levels'];
      case 'nav.reports':
        return const [
          'reports.view_own',
          'reports.view_branch',
          'reports.view_all',
        ];
      case 'nav.expenses':
        return const ['expenses.view'];
      case 'nav.employees':
        return const ['employees.view'];
      case 'nav.settings':
        return const ['settings.view'];
      case 'nav.audit_logs':
        return const ['audit_logs.view'];
      case 'nav.sales_history':
        return const ['pos.view_own_sales', 'pos.view_all_sales'];
      case 'nav.held_sales':
        return const ['pos.hold_sale'];
      case 'nav.suppliers':
        return const ['suppliers.view', 'suppliers.manage'];
      case 'nav.procurement':
        return const ['procurement.view'];
      case 'nav.recipes':
        return const ['recipes.manage', 'ingredients.view', 'ingredients.manage'];
      default:
        return const [];
    }
  }

  /// Resolves the business-module code that gates [key], or `null` if the
  /// key's area isn't module-gated (settings, dashboard widgets, nav entries,
  /// data-scope flags). Mirrors [AppFeature.moduleCode] — same module list,
  /// keyed by permission prefix instead of by feature.
  static String? _moduleCodeForKey(String key) {
    switch (key.split('.').first) {
      case 'pos':
        return 'pos';
      case 'products':
      case 'inventory':
        return 'inventory';
      case 'expenses':
        return 'expenses';
      case 'employees':
        return 'employees';
      case 'reports':
      case 'insights':
        return 'reports';
      case 'suppliers':
      case 'procurement':
        return 'procurement';
      case 'crm':
        return 'crm';
      case 'ingredients':
        return 'ingredients';
      case 'recipes':
        return 'recipes';
      case 'audit_logs':
        return 'audit';
      default:
        return null;
    }
  }

  /// Load permissions for [authUserId] from the local Drift cache.
  ///
  /// If no cache row exists, derives a seed from the current role and saves it
  /// to Drift.  After this call, [can] and [hasPermission] use the loaded map.
  ///
  /// Call immediately after [setContext] during app startup / login.
  Future<void> loadPermissions(String authUserId) async {
    final cached = await _permissionsDao.getPermissions(authUserId);
    if (cached != null && cached.isNotEmpty) {
      _permissionsMap = Map.unmodifiable(cached);
      debugPrint(
        '[PermissionService] permissions loaded from cache (${cached.length} keys)',
      );
      return;
    }

    // No cache — seed from role matrix and persist so the next load is instant.
    final seeded = DefaultPermissionMatrix.forRole(_roleKey);
    _permissionsMap = Map.unmodifiable(seeded);
    if (seeded.isNotEmpty) {
      await _permissionsDao.savePermissions(authUserId, seeded);
      debugPrint(
        '[PermissionService] permissions seeded from role matrix '
        '(${seeded.length} keys)',
      );
    }
  }

  /// Fetch the live permission matrix from Supabase and refresh the Drift cache.
  ///
  /// Silently ignored when offline.  Does NOT block the UI — call it in the
  /// background after [loadPermissions] has already populated the in-memory map.
  Future<void> syncPermissions(String authUserId) async {
    try {
      final result = await _permissionRemoteDs.fetchMyPermissions();
      if (result.permissions.isNotEmpty) {
        _permissionsMap = Map.unmodifiable(result.permissions);
        await _permissionsDao.savePermissions(
          authUserId,
          result.permissions,
          employeeId: result.employeeId,
          fromRemote: true,
        );
        debugPrint(
          '[PermissionService] permissions synced from Supabase '
          '(${result.permissions.length} keys)',
        );
      }
    } catch (e, st) {
      debugPrint('[PermissionService] sync skipped (offline?) — $e\n$st');
    }
  }

  /// Clear the in-memory permission map.  Call on sign-out.
  void clearPermissions() {
    _permissionsMap = {};
    _moduleStates = null;
  }

  // ── Module gate ───────────────────────────────────────────────────────────

  /// Returns `true` if [moduleCode] is enabled for the current business.
  ///
  /// When [_moduleStates] is null (not yet loaded) this returns `true` so
  /// that a slow first sync doesn't block the UI.
  /// When loaded, a module code absent from the map is treated as enabled —
  /// new modules added to the app before Supabase is configured stay visible.
  /// Core operational modules stay available even before module state has
  /// loaded, so a cold/offline start doesn't leave the POS unusable.
  static const _coreModulesAlwaysOn = {'pos', 'inventory'};

  bool isModuleEnabled(String moduleCode) {
    final states = _moduleStates;
    if (states == null) {
      // Not loaded yet. Fail OPEN for core modules (keep the till working) but
      // fail CLOSED for sensitive ones (audit, employees, expenses, reports,
      // suppliers) so a business that disabled them can't be bypassed in the
      // window before the real state syncs in.
      return _coreModulesAlwaysOn.contains(moduleCode);
    }
    // Loaded: an explicitly-disabled module is false; a module never configured
    // (absent key) stays enabled so newly-shipped features aren't hidden.
    return states[moduleCode] ?? true;
  }

  /// Load module states from the local Drift cache for [businessId].
  ///
  /// An empty cache (no rows) keeps [_moduleStates] null so all modules
  /// appear enabled until the first remote sync populates the table.
  Future<void> loadEnabledModules(String businessId) async {
    final rows = await _businessModulesDao.getAll(businessId);
    // Always mark module state as "loaded" (even with no rows) so that
    // isModuleEnabled uses the "absent key = enabled" path rather than the
    // null-guard fail-closed path, which blocks non-core modules (reports,
    // expenses, etc.) for businesses that have no business_modules rows yet.
    _moduleStates = {for (final r in rows) r.moduleCode: r.enabled};
    _moduleGateRevision.value++;
    debugPrint(
      '[PermissionService] modules loaded from cache '
      '(${rows.where((r) => r.enabled).length}/${rows.length} enabled)',
    );
  }

  /// Fetch the live module state from Supabase and refresh the Drift cache.
  ///
  /// Silently ignored when offline.  Call after [loadEnabledModules].
  Future<void> syncModules(String businessId) async {
    try {
      final modules = await _permissionRemoteDs.fetchEnabledModules(businessId);
      if (modules.isNotEmpty) {
        await _businessModulesDao.saveModules(businessId, modules);
        _moduleStates = Map.unmodifiable(modules);
        _moduleGateRevision.value++;
        final enabledCount = modules.values.where((v) => v).length;
        debugPrint(
          '[PermissionService] modules synced from Supabase '
          '($enabledCount/${modules.length} enabled)',
        );
      }
    } catch (e, st) {
      debugPrint('[PermissionService] module sync skipped (offline?) — $e\n$st');
    }
  }

  // ── Sync permission check (offline-safe, no I/O) ─────────────────────────

  /// Returns `true` if the current user has [permission].
  ///
  /// Delegates to [can] using the [AppPermission.permissionKey] mapping so the
  /// per-employee matrix is consulted rather than the static role matrix.
  bool hasPermission(AppPermission permission) => can(permission.permissionKey);

  /// Returns `true` if the current user has ALL of [permissions].
  bool hasAllPermissions(Iterable<AppPermission> permissions) =>
      permissions.every(hasPermission);

  /// Returns `true` if the current user has ANY of [permissions].
  bool hasAnyPermission(Iterable<AppPermission> permissions) =>
      permissions.any(hasPermission);

  /// Full set of permissions for the current user.
  ///
  /// Returns a set derived from the loaded map when available; falls back to
  /// the static role matrix.
  Set<AppPermission> get currentPermissions {
    if (_hasLoadedPermissions) {
      return AppPermission.values
          .where((p) => _permissionsMap[p.permissionKey] == true)
          .toSet();
    }
    return RolePermissionMatrix.permissionsFor(_roleKey);
  }

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

    // Role name for the denial log — from the authoritative active session.
    final roleName =
        _activeBusinessContext.roleName ?? _roleKey ?? 'unknown';
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

  /// Populate [_roleKey] and [_permissionsMap] from the local Drift auth
  /// context if not already set.  Useful during cold-start before [AuthBloc].
  Future<void> loadFromCache() async {
    final ctx = await _authContextDao.getAny();
    if (ctx?.roleName != null && (_roleKey == null || _roleKey!.isEmpty)) {
      setRole(ctx!.roleName);
    }
    if (ctx?.userId != null && !_hasLoadedPermissions) {
      await loadPermissions(ctx!.userId);
    }
  }

  // ── Feature access ────────────────────────────────────────────────────────

  /// Returns `true` if the current user is allowed to open [feature].
  ///
  /// Evaluation order (mirrors the server-side 6-layer hierarchy):
  ///   1. Module gate — if the business has disabled the module, deny.
  ///   2. Per-employee permission check via [can] / [AppFeature.navKey].
  bool canAccessFeature(AppFeature feature) {
    final code = feature.moduleCode;
    if (code != null && !isModuleEnabled(code)) return false;
    return can(feature.navKey);
  }

  /// Set of all features accessible to the current user.
  Set<AppFeature> get currentFeatures =>
      AppFeature.values.where((f) => canAccessFeature(f)).toSet();

  /// Async feature guard — checks access and logs denial.
  Future<PermissionResult> guardFeature(
    AppFeature feature, {
    String? description,
  }) async {
    if (canAccessFeature(feature)) return const PermissionResult.granted();

    final roleName =
        _activeBusinessContext.roleName ?? _roleKey ?? 'unknown';

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

  /// Returns the [DataScope] for the current user.
  ///
  /// When the permission map is loaded, uses [PermissionKeys.dataCrossBranchAccess]
  /// to determine scope.  Falls back to the static [RolePermissionMatrix].
  DataScope getDataScope() {
    if (_hasLoadedPermissions) {
      // Broadest granted reports scope wins. Resolve through the override-aware
      // matrix (not a raw map read) so a denied cross-branch / view-all override
      // actually narrows the scope, and so view_all counts as unrestricted.
      if (_resolve(PermissionKeys.reportsViewAll) ||
          _resolve(PermissionKeys.dataCrossBranchAccess)) {
        return const DataScope.unrestricted();
      }
      if (_resolve(PermissionKeys.reportsViewBranch)) {
        return DataScope.branch(_branchId ?? '');
      }
      return DataScope.own(branchId: _branchId ?? '', userId: _userId ?? '');
    }

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

  /// Update the full user context.  Call from [AuthBloc] alongside [setRole].
  ///
  /// Clears the in-memory permission map so that [loadPermissions] will
  /// re-fetch on the next call.
  /// ```dart
  /// sl<PermissionService>().setContext(
  ///   roleName: user.roleName,
  ///   branchId: user.branchId,
  ///   userId: user.id,
  /// );
  /// await sl<PermissionService>().loadPermissions(user.id);
  /// ```
  void setContext({
    required String? roleName,
    required String? branchId,
    required String? userId,
  }) {
    setRole(roleName);
    _branchId = branchId;
    _userId = userId;
    // Clear maps so load* methods re-read for the new user/business.
    _permissionsMap = {};
    _moduleStates = null;
  }
}
