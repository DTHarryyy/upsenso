import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/employees_dao.dart';
import 'package:pos/core/database/daos/entitlement_dao.dart';
import 'package:pos/core/permissions/app_feature.dart';
import 'package:pos/core/permissions/data/entitlement_remote_ds.dart';
import 'package:pos/core/session/active_business_context.dart';

/// Structural resources a plan caps (branches / seats / devices).
enum EntitlementResource { branches, seats, devices }

/// Plan-level entitlement — the third, outermost access layer (design §7):
///
///   effective_access = plan_entitlement AND module_enabled AND permission
///
/// Reads are offline-first from the Drift `entitlement_cache`; the server RPC
/// `get_my_entitlement()` refreshes it in the background. Everything here is
/// UX-layer only — the authority is the server (`has_cloud_access()` RLS +
/// in-RPC cap checks). A tampered cache unlocks nothing with cloud value.
///
/// Fail modes when no cache row exists yet (fresh install, mid-rollout):
///   * cloud access  → CLOSED (no sync until a real entitlement is fetched —
///     offline you couldn't sync anyway, online the fetch happens at bootstrap)
///   * plan features → OPEN (never brick premium UI on a paid tenant whose
///     cache hasn't landed; module gate + permissions still apply, and the
///     server still rejects anything cloud-priced)
class EntitlementService {
  final EntitlementDao _dao;
  final EntitlementRemoteDs _remoteDs;
  final ActiveBusinessContext _activeBusinessContext;
  // Local source-of-truth for structural usage. Seats/branches are counted from
  // Drift (not the lagging server RPC) so the meter and the cap pre-check can
  // never diverge from what the device actually holds.
  final EmployeesDao _employeesDao;
  final BranchesDao _branchesDao;

  EntitlementCacheRow? _cached;
  ResourceUsageCacheRow? _usage;
  Map<String, dynamic> _featureFlags = const {};

  /// Bumps on every entitlement change (cache load, background sync, plan
  /// transition). Merged into the router's refreshListenable and watched by
  /// SyncService so a plan change re-runs guards and re-arms/pauses sync.
  final ValueNotifier<int> _entitlementRevision = ValueNotifier<int>(0);

  ValueListenable<int> get entitlementRevision => _entitlementRevision;

  EntitlementService({
    required EntitlementDao entitlementDao,
    required EntitlementRemoteDs entitlementRemoteDs,
    required ActiveBusinessContext activeBusinessContext,
    required EmployeesDao employeesDao,
    required BranchesDao branchesDao,
  })  : _dao = entitlementDao,
        _remoteDs = entitlementRemoteDs,
        _activeBusinessContext = activeBusinessContext,
        _employeesDao = employeesDao,
        _branchesDao = branchesDao;

  bool get hasEntitlementData => _cached != null;

  // ── Loading ────────────────────────────────────────────────────────────────

  /// Populate from the local Drift cache (offline-safe; called at bootstrap
  /// before SyncService arms).
  Future<void> loadFromCache() async {
    final businessId = _activeBusinessContext.businessId;
    if (businessId == null || businessId.isEmpty) return;
    try {
      _cached = await _dao.getEntitlement(businessId);
      _featureFlags = _decodeFlags(_cached?.featureFlagsJson);
      // Recount seats/branches locally so the meter is accurate from first
      // paint, even offline (before any server sync lands).
      await recomputeLocalUsage();
    } catch (e, st) {
      debugPrint('[EntitlementService] Error in loadFromCache: $e\n$st');
    }
  }

  /// Refresh from the server and persist. Non-blocking at call sites
  /// (fire-and-forget from bootstrap); failures keep the cached snapshot.
  Future<void> syncEntitlement() async {
    final businessId = _activeBusinessContext.businessId;
    if (businessId == null || businessId.isEmpty) return;
    try {
      final data = await _remoteDs.fetchMyEntitlement();
      await _persist(businessId, data);
      _cached = await _dao.getEntitlement(businessId);
      _featureFlags = _decodeFlags(_cached?.featureFlagsJson);
      // The server usage counts can lag or under-count local-only data — take
      // seats & branches from the live local tally (device stays server-sourced).
      await recomputeLocalUsage();
      debugPrint(
          '[EntitlementService] synced — plan=${_cached?.planCode} status=$effectiveStatus');
    } catch (e, st) {
      // Offline or pre-migration server: cached snapshot stays authoritative.
      debugPrint('[EntitlementService] Error in syncEntitlement: $e\n$st');
    }
  }

  Future<void> _persist(String businessId, Map<String, dynamic> data) async {
    final usage = (data['usage'] is Map)
        ? Map<String, dynamic>.from(data['usage'] as Map)
        : const <String, dynamic>{};

    await _dao.saveEntitlement(EntitlementCacheTableCompanion(
      businessId: Value(businessId),
      planCode: Value((data['plan_code'] as String?) ?? 'free'),
      planVersion: Value((data['plan_version'] as num?)?.toInt() ?? 1),
      status: Value((data['status'] as String?) ?? 'free'),
      cloudEnabled: Value(data['cloud_enabled'] == true),
      featureFlagsJson: Value(json.encode(data['feature_flags'] ?? {})),
      maxBranches: Value((data['max_branches'] as num?)?.toInt()),
      maxSeats: Value((data['max_seats'] as num?)?.toInt()),
      maxDevices: Value((data['max_devices'] as num?)?.toInt()),
      deviceAddons: Value((data['device_addons'] as num?)?.toInt() ?? 0),
      branchAddons: Value((data['branch_addons'] as num?)?.toInt() ?? 0),
      seatAddons: Value((data['seat_addons'] as num?)?.toInt() ?? 0),
      trialEnd: Value(_parseTs(data['trial_end'])),
      currentPeriodEnd: Value(_parseTs(data['current_period_end'])),
      graceUntil: Value(_parseTs(data['grace_until'])),
      grandfatheredPrice: Value((data['grandfathered_price'] as num?)?.toDouble()),
      lastServerSyncAt: Value(_parseTs(data['server_time']) ?? DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));

    await _dao.saveUsage(ResourceUsageCacheTableCompanion(
      businessId: Value(businessId),
      branchCount: Value((usage['branch_count'] as num?)?.toInt() ?? 0),
      activeSeatCount: Value((usage['active_seat_count'] as num?)?.toInt() ?? 0),
      deviceCount: Value((usage['device_count'] as num?)?.toInt() ?? 0),
      syncedAt: Value(DateTime.now()),
    ));
  }

  /// Logout / account-switch hygiene — entitlement never leaks across tenants.
  Future<void> clear() async {
    try {
      await _dao.clearAll();
    } catch (e, st) {
      debugPrint('[EntitlementService] Error in clear: $e\n$st');
    }
    _cached = null;
    _usage = null;
    _featureFlags = const {};
    _entitlementRevision.value++;
  }

  // ── Status (mirrors SQL effective_sub_status, clock-tamper clamped) ───────

  /// trialing | active | past_due | free | lapsed.
  ///
  /// Derived from cached timestamps so transitions (trial expiry, grace end)
  /// take effect offline. The clock is clamped to the last server contact:
  /// rolling the device clock BACK cannot stretch grace (§7.4); rolling it
  /// forward only expires the user early, which fails safe.
  String get effectiveStatus {
    final row = _cached;
    if (row == null) return 'free';

    var now = DateTime.now();
    final anchor = row.lastServerSyncAt;
    if (anchor != null && anchor.isAfter(now)) now = anchor;

    final periodEnd = row.currentPeriodEnd;
    if (periodEnd != null && !now.isAfter(periodEnd)) return 'active';
    final grace = row.graceUntil;
    if (grace != null &&
        !now.isAfter(grace) &&
        periodEnd != null &&
        row.status != 'canceled') {
      return 'past_due';
    }
    final trialEnd = row.trialEnd;
    if (row.status == 'trialing' && trialEnd != null && now.isBefore(trialEnd)) {
      return 'trialing';
    }
    return periodEnd == null ? 'free' : 'lapsed';
  }

  bool get _statusHasCloud =>
      const {'trialing', 'active', 'past_due'}.contains(effectiveStatus);

  /// The v2 core gate (§7.1): may this tenant sync business data to the cloud?
  /// Fail-closed without entitlement data — there is nothing to sync against
  /// anyway until the server has been reached once.
  bool get cloudEnabled {
    final row = _cached;
    if (row == null) return false;
    return row.cloudEnabled && _statusHasCloud;
  }

  /// Days left in the active window (trial / period / grace) for banners.
  int? get daysRemaining {
    final row = _cached;
    if (row == null) return null;
    final until = switch (effectiveStatus) {
      'trialing' => row.trialEnd,
      'active' => row.currentPeriodEnd,
      'past_due' => row.graceUntil,
      _ => null,
    };
    if (until == null) return null;
    final d = until.difference(DateTime.now()).inDays;
    return d < 0 ? 0 : d;
  }

  String get planCode => _cached?.planCode ?? 'free';
  double? get grandfatheredPrice => _cached?.grandfatheredPrice;

  // ── Plan feature gate (consulted by PermissionService.canAccessFeature) ───

  /// Does the current plan include [feature]? Only premium features are
  /// plan-gated; everything on-device (POS, inventory, expenses, recipes,
  /// AI, local audit) is always true — a POS must never stop selling (§2.1).
  bool featureAllowed(AppFeature feature) {
    if (_cached == null) return true; // fail-open: see class doc
    switch (feature) {
      case AppFeature.customerDirectory:
        // 'basic' | 'full' pass; false/absent denies.
        final crm = _featureFlags['crm'];
        return crm == 'basic' || crm == 'full' || crm == true;
      case AppFeature.procurement:
      case AppFeature.supplierDirectory:
        return _featureFlags['procurement'] == true;
      default:
        return true;
    }
  }

  /// Full CRM depth (Growth+). Basic CRM keeps the directory; full unlocks
  /// the deeper views — checked at action level, not the module gate.
  bool get crmFull => _featureFlags['crm'] == 'full';

  /// Full reports incl. export (Growth+); Free/Starter get basic reports.
  bool get reportsFull => _featureFlags['reports'] == 'full';

  /// Cloud-anchored audit chain + cross-device fraud sync (paid tiers).
  bool get cloudAuditEnabled => _featureFlags['cloud_audit'] == true;

  // ── Structural limits + usage (UX pre-checks and meters only) ─────────────

  /// Effective cap (base + add-ons, folded in server-side). Null = unlimited
  /// or unknown — no client pre-check; the server enforces regardless.
  int? effectiveMax(EntitlementResource resource) {
    final row = _cached;
    if (row == null) return null;
    return switch (resource) {
      EntitlementResource.branches => row.maxBranches,
      EntitlementResource.seats => row.maxSeats,
      EntitlementResource.devices => row.maxDevices,
    };
  }

  /// Cached usage for the meter's instant paint. Kept fresh by
  /// [recomputeLocalUsage]; for a hard create-decision use [liveUsageOf].
  int usageOf(EntitlementResource resource) {
    final u = _usage;
    if (u == null) return 0;
    return switch (resource) {
      EntitlementResource.branches => u.branchCount,
      EntitlementResource.seats => u.activeSeatCount,
      EntitlementResource.devices => u.deviceCount,
    };
  }

  /// Live usage, counted from the local source of truth at call time. Seats and
  /// branches come straight from Drift so a create pre-check can never run on a
  /// stale number; devices stay server-sourced (the only cross-device count).
  Future<int> liveUsageOf(EntitlementResource resource) async {
    final businessId = _activeBusinessContext.businessId;
    if (businessId == null || businessId.isEmpty) return 0;
    switch (resource) {
      case EntitlementResource.seats:
        return _employeesDao.countActiveForBusiness(businessId);
      case EntitlementResource.branches:
        return _branchesDao.countForBusiness(businessId);
      case EntitlementResource.devices:
        return _usage?.deviceCount ?? 0;
    }
  }

  /// UX pre-check before a create, counted live: false only when we positively
  /// know the cap is reached. Unknown cap never blocks — the server is the
  /// referee for cloud tiers; for local-only Free this is the only gate.
  Future<bool> canAddAnother(EntitlementResource resource) async {
    final max = effectiveMax(resource);
    if (max == null) return true;
    return await liveUsageOf(resource) < max;
  }

  /// Refresh the cached seat/branch usage from local Drift (device count kept
  /// from the last server sync). Call after any create/remove/activate and on
  /// load so the meter reflects reality on every tier, online or off.
  Future<void> recomputeLocalUsage() async {
    final businessId = _activeBusinessContext.businessId;
    if (businessId == null || businessId.isEmpty) return;
    try {
      final seats = await _employeesDao.countActiveForBusiness(businessId);
      final branches = await _branchesDao.countForBusiness(businessId);
      final existing = await _dao.getUsage(businessId);
      await _dao.saveUsage(ResourceUsageCacheTableCompanion(
        businessId: Value(businessId),
        branchCount: Value(branches),
        activeSeatCount: Value(seats),
        deviceCount: Value(existing?.deviceCount ?? 0),
        syncedAt: Value(DateTime.now()),
      ));
      _usage = await _dao.getUsage(businessId);
      _entitlementRevision.value++;
    } catch (e, st) {
      debugPrint('[EntitlementService] Error in recomputeLocalUsage: $e\n$st');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _decodeFlags(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = json.decode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (e, st) {
      debugPrint('[EntitlementService] Error in _decodeFlags: $e\n$st');
    }
    return const {};
  }

  static DateTime? _parseTs(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
