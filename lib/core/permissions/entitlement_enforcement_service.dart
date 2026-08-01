import 'package:flutter/foundation.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/employees_dao.dart';
import 'package:pos/core/database/daos/entitlement_dao.dart';
import 'package:pos/core/database/tables/entitlement_locks_table.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/permissions/role_permission_matrix.dart';
import 'package:pos/core/session/active_business_context.dart';

/// A write was aimed at a branch held above the plan's cap.
///
/// Carries the branch so the UI can name it. Callers show the upgrade moment;
/// this is never a crash path, because the branch was already marked read-only
/// in every surface that could have started the write.
class BranchLockedException implements Exception {
  final String branchId;
  final String message;

  const BranchLockedException(
    this.branchId, [
    this.message =
        'This branch is above your plan\'s limit and is read-only. '
        'Upgrade to reopen it, or switch to an active branch.',
  ]);

  @override
  String toString() => 'BranchLockedException($branchId): $message';
}

/// Enforces the structural caps a tenant has already exceeded — the downgrade
/// and lapse case that `EntitlementService.canAddAnother` doesn't cover.
///
/// `canAddAnother` only stops the *next* create. Without this, buying one month
/// of Growth, creating five branches and twelve staff logins, then cancelling
/// keeps all of it forever: the caps are checked on insert and never again.
///
/// The model (design §10, revised 2026-08-01):
///   * Exactly N branches / seats stay ACTIVE, where N is the plan's cap.
///   * The excess is LOCKED, never deleted. Locked branches stay readable,
///     reportable and exportable; they just can't be sold on or written to.
///   * The default active set is chosen so nothing ever stops mid-shift: the
///     branch currently open in POS is always kept, then oldest-first. The owner
///     always keeps their own seat.
///   * The owner can re-pick the active set at any time; an upgrade releases
///     every lock automatically.
///
/// Like the rest of the entitlement layer this is a UX gate, not a security
/// boundary — the server's RESTRICTIVE cap policies are the referee. What it
/// does guarantee is that the loophole isn't *free*, and that the merchant is
/// told exactly what happened and how to fix it.
class EntitlementEnforcementService {
  final EntitlementDao _dao;
  final EntitlementService _entitlement;
  final BranchesDao _branchesDao;
  final EmployeesDao _employeesDao;
  final ActiveBusinessContext _activeBusinessContext;

  Set<String> _lockedBranchIds = const {};
  Set<String> _suspendedEmployeeIds = const {};

  /// Bumps whenever the lock set changes, so nav, the branch switcher and the
  /// billing meters repaint without a cubit — mirrors `entitlementRevision`.
  final ValueNotifier<int> _lockRevision = ValueNotifier<int>(0);

  EntitlementEnforcementService({
    required EntitlementDao entitlementDao,
    required EntitlementService entitlementService,
    required BranchesDao branchesDao,
    required EmployeesDao employeesDao,
    required ActiveBusinessContext activeBusinessContext,
  }) : _dao = entitlementDao,
       _entitlement = entitlementService,
       _branchesDao = branchesDao,
       _employeesDao = employeesDao,
       _activeBusinessContext = activeBusinessContext {
    // Every plan change re-runs the policy, so an upgrade releases locks and a
    // lapse applies them without any caller remembering to ask. reconcile()
    // never bumps entitlementRevision, so this can't feed back on itself.
    _entitlement.entitlementRevision.addListener(_onEntitlementChanged);
  }

  void _onEntitlementChanged() => reconcile().ignore();

  ValueListenable<int> get lockRevision => _lockRevision;

  /// Branch ids held above the plan's cap — read-only until upgrade.
  Set<String> get lockedBranchIds => _lockedBranchIds;

  /// Employee ids suspended for want of a seat.
  Set<String> get suspendedEmployeeIds => _suspendedEmployeeIds;

  bool isBranchLocked(String? branchId) =>
      branchId != null && _lockedBranchIds.contains(branchId);

  bool isEmployeeSuspended(String? employeeId) =>
      employeeId != null && _suspendedEmployeeIds.contains(employeeId);

  bool get hasOverCapResources =>
      _lockedBranchIds.isNotEmpty || _suspendedEmployeeIds.isNotEmpty;

  /// Throw if [branchId] can't be written to. The single guard every write path
  /// calls — keeping the rule in one place is what stops "read-only" meaning
  /// something subtly different in sales, stock and expenses.
  ///
  /// A null branch passes: it's the owner's "All Branches" view, and the write
  /// resolves to a concrete branch before it lands, which does get checked.
  void assertBranchWritable(String? branchId) {
    if (isBranchLocked(branchId)) throw BranchLockedException(branchId!);
  }

  /// The branch the POS is currently pointed at. Set by BranchCubit so the
  /// default active set can guarantee the till in use is never the one locked.
  String? _activeBranchId;
  // ignore: use_setters_to_change_properties
  void noteActiveBranch(String? branchId) => _activeBranchId = branchId;

  // ── Loading ────────────────────────────────────────────────────────────────

  /// Read the persisted lock set into memory. Cheap; call at bootstrap before
  /// the first frame so nothing renders unlocked and then snaps shut.
  Future<void> load() async {
    final businessId = _activeBusinessContext.businessId;
    if (businessId == null || businessId.isEmpty) return;
    try {
      _lockedBranchIds = await _readLocks(
        businessId,
        EntitlementLockKinds.branch,
      );
      _suspendedEmployeeIds = await _readLocks(
        businessId,
        EntitlementLockKinds.seat,
      );
      _lockRevision.value++;
    } catch (e, st) {
      debugPrint('[EntitlementEnforcement] Error in load: $e\n$st');
    }
  }

  Future<Set<String>> _readLocks(String businessId, String kind) async {
    final rows = await _dao.getLocks(businessId, kind);
    return rows.map((r) => r.resourceId).toSet();
  }

  // ── Reconcile ──────────────────────────────────────────────────────────────

  /// Recompute the lock set against the current plan. Idempotent — safe to call
  /// on every entitlement change, after any create, and at bootstrap.
  ///
  /// Under cap (or on an unknown/unlimited cap) this releases everything, which
  /// is what makes an upgrade restore the tenant with no manual cleanup.
  Future<void> reconcile() async {
    final businessId = _activeBusinessContext.businessId;
    if (businessId == null || businessId.isEmpty) return;
    try {
      await _reconcileBranches(businessId);
      await _reconcileSeats(businessId);
      _lockRevision.value++;
    } catch (e, st) {
      debugPrint('[EntitlementEnforcement] Error in reconcile: $e\n$st');
    }
  }

  Future<void> _reconcileBranches(String businessId) async {
    final max = _entitlement.effectiveMax(EntitlementResource.branches);
    final branches = await _branchesDao.getByBusinessId(businessId);
    final keep = _defaultActiveBranches(branches, max);
    final locked = branches
        .map((b) => b.id)
        .where((id) => !keep.contains(id))
        .toSet();
    await _persistLocks(
      businessId: businessId,
      kind: EntitlementLockKinds.branch,
      ids: locked,
    );
    _lockedBranchIds = locked;
  }

  /// Which branches stay active. Null cap = unlimited/unknown → keep them all.
  ///
  /// Order matters and is the whole safety story: the branch currently open in
  /// POS goes first so a downgrade can never stop the till someone is standing
  /// at, then oldest-first because that's the one they had before they upgraded.
  Set<String> _defaultActiveBranches(
    List<BranchesTableData> branches,
    int? max,
  ) {
    if (max == null || branches.length <= max) {
      return branches.map((b) => b.id).toSet();
    }
    final ordered = [...branches]
      ..sort((a, b) => a.localUpdatedAt.compareTo(b.localUpdatedAt));
    final active = _activeBranchId;
    if (active != null) {
      final i = ordered.indexWhere((b) => b.id == active);
      if (i > 0) ordered.insert(0, ordered.removeAt(i));
    }
    return ordered.take(max).map((b) => b.id).toSet();
  }

  Future<void> _reconcileSeats(String businessId) async {
    final max = _entitlement.effectiveMax(EntitlementResource.seats);
    final employees = await _employeesDao.getByBusinessId(businessId);
    // Only active employees consume a seat, which is also what the server
    // counts — someone the owner already deactivated needs no suspension.
    final active = employees.where((e) => e.isActive).toList();

    if (max == null || active.length <= max) {
      await _persistLocks(
        businessId: businessId,
        kind: EntitlementLockKinds.seat,
        ids: const {},
      );
      _suspendedEmployeeIds = const {};
      return;
    }

    // Owner first — locking the account that pays the bill would be absurd —
    // then oldest-first, matching the branch rule.
    final ordered = [...active]
      ..sort((a, b) {
        final aOwner = RolePermissionMatrix.isOwnerRoleName(a.roleName);
        final bOwner = RolePermissionMatrix.isOwnerRoleName(b.roleName);
        if (aOwner != bOwner) return aOwner ? -1 : 1;
        final aAt = a.createdAt;
        final bAt = b.createdAt;
        if (aAt == null && bAt == null) return a.id.compareTo(b.id);
        if (aAt == null) return 1;
        if (bAt == null) return -1;
        return aAt.compareTo(bAt);
      });
    final suspended = ordered.skip(max).map((e) => e.id).toSet();

    await _persistLocks(
      businessId: businessId,
      kind: EntitlementLockKinds.seat,
      ids: suspended,
    );
    _suspendedEmployeeIds = suspended;
  }

  Future<void> _persistLocks({
    required String businessId,
    required String kind,
    required Set<String> ids,
  }) {
    return _dao.replaceLocks(
      businessId: businessId,
      resourceKind: kind,
      resourceIds: ids,
      lockedUnderPlan: _entitlement.planCode,
    );
  }

  // ── Owner overrides ───────────────────────────────────────────────────────

  /// Apply the owner's chosen active branches. [activeBranchIds] must already
  /// be within the cap; anything else for this business is locked.
  ///
  /// Rejected (returns false) when the choice exceeds the cap — the caller is
  /// a picker that should have limited the selection, so this is a bug guard
  /// rather than a user-facing error.
  Future<bool> chooseActiveBranches(Set<String> activeBranchIds) async {
    final businessId = _activeBusinessContext.businessId;
    if (businessId == null || businessId.isEmpty) return false;
    final max = _entitlement.effectiveMax(EntitlementResource.branches);
    if (max != null && activeBranchIds.length > max) return false;
    try {
      final branches = await _branchesDao.getByBusinessId(businessId);
      final locked = branches
          .map((b) => b.id)
          .where((id) => !activeBranchIds.contains(id))
          .toSet();
      await _persistLocks(
        businessId: businessId,
        kind: EntitlementLockKinds.branch,
        ids: locked,
      );
      _lockedBranchIds = locked;
      _lockRevision.value++;
      return true;
    } catch (e, st) {
      debugPrint(
        '[EntitlementEnforcement] Error in chooseActiveBranches: $e\n$st',
      );
      return false;
    }
  }

  /// Apply the owner's chosen seat holders, same contract as
  /// [chooseActiveBranches]. The owner's own row is always kept.
  Future<bool> chooseActiveSeats(Set<String> activeEmployeeIds) async {
    final businessId = _activeBusinessContext.businessId;
    if (businessId == null || businessId.isEmpty) return false;
    final max = _entitlement.effectiveMax(EntitlementResource.seats);
    try {
      final employees = await _employeesDao.getByBusinessId(businessId);
      final keep = {
        ...activeEmployeeIds,
        ...employees
            .where((e) => RolePermissionMatrix.isOwnerRoleName(e.roleName))
            .map((e) => e.id),
      };
      if (max != null && keep.length > max) return false;
      final suspended = employees
          .where((e) => e.isActive && !keep.contains(e.id))
          .map((e) => e.id)
          .toSet();
      await _persistLocks(
        businessId: businessId,
        kind: EntitlementLockKinds.seat,
        ids: suspended,
      );
      _suspendedEmployeeIds = suspended;
      _lockRevision.value++;
      return true;
    } catch (e, st) {
      debugPrint(
        '[EntitlementEnforcement] Error in chooseActiveSeats: $e\n$st',
      );
      return false;
    }
  }

  /// Logout / account-switch hygiene, matching EntitlementService.clear().
  /// The rows themselves go with EntitlementDao.clearAll().
  Future<void> clear() async {
    _lockedBranchIds = const {};
    _suspendedEmployeeIds = const {};
    _activeBranchId = null;
    _lockRevision.value++;
  }

  /// Process-lifetime singleton — nothing but DI teardown should call this.
  void dispose() {
    _entitlement.entitlementRevision.removeListener(_onEntitlementChanged);
    _lockRevision.dispose();
  }
}
