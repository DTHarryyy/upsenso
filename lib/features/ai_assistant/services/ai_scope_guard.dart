import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/data_scope.dart';
import 'package:pos/core/permissions/data_scoping_layer.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/features/ai_assistant/models/ai_models.dart';

/// The single authorization + scope chokepoint for the AI assistant.
///
/// Everyone can open the chat, but every data read/write the pipeline performs
/// routes through here so the AI only ever exposes or acts on data the user
/// could access in the UI. It reuses the exact same primitives the rest of the
/// app uses — [PermissionService] (module gate + RBAC), [DataScopingLayer]
/// (own/branch/all row scope), [ActiveBusinessContext] (authoritative tenant) —
/// and mirrors the permission codes the server-side RLS enforces, so the client
/// and server can never disagree. Deny-by-default: any action not mapped here is
/// refused.
class AiScopeGuard {
  final PermissionService _perms;
  final DataScopingLayer _scoping;
  final ActiveBusinessContext _business;
  final BranchCubit _branches;

  AiScopeGuard({
    required PermissionService permissions,
    required DataScopingLayer scoping,
    required ActiveBusinessContext business,
    required BranchCubit branches,
  }) : _perms = permissions,
       _scoping = scoping,
       _business = business,
       _branches = branches;

  /// Read actions → the permission that gates them. Anything absent (the write
  /// action, `unknown`, or a future action) is denied by default.
  static const Map<AiAction, String> _readGates = {
    // Sales analytics — mirrors the server's transactions own/branch/all RLS.
    AiAction.getSales: PermissionKeys.navReports,
    AiAction.getSalesByCategory: PermissionKeys.navReports,
    AiAction.getSalesByProduct: PermissionKeys.navReports,
    AiAction.getProductsWithoutSales: PermissionKeys.navReports,
    AiAction.getTransactionCount: PermissionKeys.navReports,
    // Product catalog.
    AiAction.getProductCount: PermissionKeys.productsView,
    AiAction.getActiveProducts: PermissionKeys.productsView,
    // Expenses (feature not wired yet, but gated so it's safe if it ever is).
    AiAction.getExpenses: PermissionKeys.expensesView,
  };

  static const String _noBusinessMsg =
      'Sign in to a business first — I can only work with your business data.';

  static String _denyMessageFor(String permKey) {
    switch (permKey) {
      case PermissionKeys.navReports:
        return "You don't have access to sales reports.";
      case PermissionKeys.productsView:
        return "You don't have access to product information.";
      case PermissionKeys.expensesView:
        return "You don't have access to expenses.";
      default:
        return "You don't have access to that.";
    }
  }

  /// Gate a read action. Deny-by-default for any unmapped action.
  AiScopeResult authorizeRead(AiAction action) {
    if (!_business.hasBusiness) return const AiScopeResult.deny(_noBusinessMsg);
    final permKey = _readGates[action];
    if (permKey == null) {
      return const AiScopeResult.deny("I can't help with that one.");
    }
    if (!_perms.can(permKey)) {
      return AiScopeResult.deny(_denyMessageFor(permKey));
    }
    return const AiScopeResult.allow();
  }

  /// Gate the sale-creation write. Async because it audit-logs the denial via
  /// [PermissionService.guard], and it uses the same `pos.use` permission the
  /// server RLS enforces on `transactions` INSERT — so a client that allows the
  /// write can always sync it, and one that blocks it never writes a local sale
  /// that would be rejected on the server.
  Future<AiScopeResult> authorizeWrite(AiAction action) async {
    if (!_business.hasBusiness) return const AiScopeResult.deny(_noBusinessMsg);
    if (action != AiAction.createTransaction) {
      return const AiScopeResult.deny("I can't do that.");
    }
    final result = await _perms.guard(
      AppPermission.createSale,
      entityType: 'transaction',
      description: 'AI assistant sale creation',
    );
    if (result.granted) return const AiScopeResult.allow();
    return AiScopeResult.deny(
      result.deniedReason ?? "You don't have permission to create sales.",
    );
  }

  /// Resolve the effective data scope to inject into every AI tool query.
  /// Honours the branch picker only for all-branches users; branch/own-scoped
  /// users are locked to their own branch/own rows — matching the server RLS.
  AiScope resolveScope() {
    final scope = _scoping.scope;
    final branchId = scope.type == DataScopeType.allBranches
        ? _branches.getSelectedBranchIdForFiltering()
        : _scoping.effectiveBranchFilter;
    return AiScope(
      businessId: _business.businessId ?? '',
      userId: _business.userId ?? '',
      branchId: branchId,
      ownUserId: _scoping.effectiveUserFilter,
      includeStock: _perms.can(PermissionKeys.inventoryViewLevels),
    );
  }
}

/// Outcome of an [AiScopeGuard] check.
class AiScopeResult {
  final bool allowed;

  /// Friendly refusal text shown to the user when [allowed] is false.
  final String message;

  const AiScopeResult.allow() : allowed = true, message = '';
  const AiScopeResult.deny(this.message) : allowed = false;
}

/// The resolved data slice the AI is allowed to read/write, injected into every
/// tool query so scoping can't be skipped.
class AiScope {
  /// Authoritative tenant id (guaranteed non-empty once past `authorize*`).
  final String businessId;

  /// The acting user id (sale author).
  final String userId;

  /// Read/write branch; `null` = all branches (owner + branch picker).
  final String? branchId;

  /// Non-null only for own-only scope → restricts reads to this user's rows.
  final String? ownUserId;

  /// Whether stock figures may be shown (needs `inventory.view_levels`).
  final bool includeStock;

  const AiScope({
    required this.businessId,
    required this.userId,
    required this.branchId,
    required this.ownUserId,
    required this.includeStock,
  });
}
