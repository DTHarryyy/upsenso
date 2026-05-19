import 'package:pos/core/permissions/data_scope.dart';
import 'package:pos/core/permissions/permission_service.dart';

/// Data scoping layer — filters repository results to match the current
/// user's [DataScope] before data reaches the BLoC or UI.
///
/// Usage in a repository or use-case:
/// ```dart
/// final all = await _dao.getAllTransactions(branchId: branchId);
/// return sl<DataScopingLayer>().apply(
///   items: all,
///   getBranchId: (t) => t.branchId,
///   getUserId: (t) => t.createdBy,
/// );
/// ```
///
/// IMPORTANT: This is a defence-in-depth layer.  Primary enforcement happens
/// in Supabase RLS policies.  This layer protects against data leaking through
/// the local Drift cache when the sync brings down more rows than expected.
class DataScopingLayer {
  final PermissionService _permissionService;

  DataScopingLayer({required PermissionService permissionService})
    : _permissionService = permissionService;

  /// Current data scope derived from the signed-in user's role + context.
  DataScope get scope => _permissionService.getDataScope();

  // ── Generic scope filter ──────────────────────────────────────────────────

  /// Filter any list so only items visible to the current user are returned.
  ///
  /// [getBranchId]: extracts the branch identifier from item [T].
  /// [getUserId]:   extracts the owner/creator user-id from item [T]; only
  ///                consulted for [DataScopeType.ownOnly] scopes.
  List<T> apply<T>({
    required List<T> items,
    required String? Function(T) getBranchId,
    String? Function(T)? getUserId,
  }) {
    final s = scope;
    switch (s.type) {
      case DataScopeType.allBranches:
        return items;

      case DataScopeType.branchOnly:
        if (s.branchId == null) return items;
        return items.where((i) => getBranchId(i) == s.branchId).toList();

      case DataScopeType.ownOnly:
        return items.where((i) {
          final branchMatch =
              s.branchId == null || getBranchId(i) == s.branchId;
          final userMatch =
              getUserId == null || s.userId == null || getUserId(i) == s.userId;
          return branchMatch && userMatch;
        }).toList();
    }
  }

  // ── Point-in-time access checks ───────────────────────────────────────────

  /// Returns `true` if the current user may see data from [targetBranchId].
  bool canAccessBranch(String targetBranchId) {
    final s = scope;
    if (s.type == DataScopeType.allBranches) return true;
    return s.branchId == targetBranchId;
  }

  /// Returns `true` if the current user may see data owned by [targetUserId].
  bool canAccessUserData(String targetUserId) {
    final s = scope;
    if (s.type == DataScopeType.allBranches) return true;
    if (s.type == DataScopeType.branchOnly) return true;
    return s.userId == targetUserId;
  }

  // ── Query parameter helpers ───────────────────────────────────────────────

  /// Branch ID to pass as a filter to DAO / repository queries.
  /// Returns `null` when the user should see all branches (owner-level).
  ///
  /// ```dart
  /// final rows = await _dao.getSales(
  ///   branchId: sl<DataScopingLayer>().effectiveBranchFilter,
  /// );
  /// ```
  String? get effectiveBranchFilter {
    final s = scope;
    if (s.type == DataScopeType.allBranches) return null;
    return s.branchId;
  }

  /// User ID to pass as a filter to DAO / repository queries.
  /// Returns `null` when the user should see all records within their branch.
  String? get effectiveUserFilter {
    final s = scope;
    if (s.type == DataScopeType.ownOnly) return s.userId;
    return null;
  }
}
