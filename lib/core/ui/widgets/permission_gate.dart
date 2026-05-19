import 'package:flutter/material.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/permissions/app_feature.dart';
import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/data_scope.dart' show DashboardScope;
export 'package:pos/core/permissions/data_scope.dart' show DashboardScope;
import 'package:pos/core/permissions/permission_service.dart';

/// Conditionally renders [child] based on whether the current user has [permission].
///
/// Two enforcement modes (controlled by [mode]):
///
/// • [PermissionGateMode.hide] (default) — renders [fallback] (or nothing)
///   when access is denied.  Use for navigation items, action buttons, and
///   whole sections that should not be visible to restricted roles.
///
/// • [PermissionGateMode.disable] — keeps [child] in the tree but wraps it in
///   [AbsorbPointer] + [Opacity] so it is visible but non-interactive.  A
///   [Tooltip] shows [deniedMessage] on long-press.  Use for buttons that the
///   user can see but not tap (e.g. "Refund" on a cashier's screen).
///
/// Usage:
/// ```dart
/// // Hide entirely
/// PermissionGate(
///   permission: AppPermission.refundSale,
///   child: RefundButton(onTap: _refund),
/// )
///
/// // Disable with tooltip
/// PermissionGate(
///   permission: AppPermission.editProduct,
///   mode: PermissionGateMode.disable,
///   deniedMessage: 'Approval required from Branch Manager.',
///   child: EditProductButton(),
/// )
/// ```
class PermissionGate extends StatelessWidget {
  final AppPermission permission;
  final Widget child;

  /// Widget rendered when access is denied and [mode] is [PermissionGateMode.hide].
  /// Defaults to [SizedBox.shrink] (invisible, zero-size).
  final Widget? fallback;

  final PermissionGateMode mode;

  /// Tooltip message shown when [mode] is [PermissionGateMode.disable].
  /// Defaults to [AppPermission.deniedMessage].
  final String? deniedMessage;

  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
    this.mode = PermissionGateMode.hide,
    this.deniedMessage,
  });

  @override
  Widget build(BuildContext context) {
    final allowed = sl<PermissionService>().hasPermission(permission);

    if (allowed) return child;

    if (mode == PermissionGateMode.hide) {
      return fallback ?? const SizedBox.shrink();
    }

    // ── Disable mode ────────────────────────────────────────────────────────
    return Tooltip(
      message: deniedMessage ?? permission.deniedMessage,
      child: AbsorbPointer(child: Opacity(opacity: 0.38, child: child)),
    );
  }
}

/// How [PermissionGate] enforces a denied permission.
enum PermissionGateMode {
  /// Remove the widget from the tree when permission is denied.
  hide,

  /// Keep the widget visible but non-interactive when permission is denied.
  disable,
}

/// A function-based alternative to [PermissionGate].
///
/// Provides [granted] (bool) and [permissions] (full set) to the [builder],
/// so callers can apply custom logic while still delegating the check.
///
/// ```dart
/// PermissionBuilder(
///   permission: AppPermission.approveExpense,
///   builder: (context, granted, _) => granted
///       ? ApproveButton(onTap: _approve)
///       : Text('Manager approval required.', style: TextStyle(color: Colors.grey)),
/// )
/// ```
class PermissionBuilder extends StatelessWidget {
  final AppPermission permission;
  final Widget Function(
    BuildContext context,
    bool granted,
    Set<AppPermission> allPermissions,
  )
  builder;

  const PermissionBuilder({
    super.key,
    required this.permission,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final service = sl<PermissionService>();
    return builder(
      context,
      service.hasPermission(permission),
      service.currentPermissions,
    );
  }
}

// ── Feature Gate ──────────────────────────────────────────────────────────────

/// Guards a widget behind a feature access check.
///
/// Use at navigation entry points and module roots to prevent restricted roles
/// from entering entire screens.
///
/// ```dart
/// FeatureGate(
///   feature: AppFeature.expensesModule,
///   child: ExpensesPage(),
/// )
///
/// // Redirect variant — shows the fallback page when access is denied:
/// FeatureGate(
///   feature: AppFeature.reportsAnalytics,
///   fallback: AccessDeniedPage(feature: AppFeature.reportsAnalytics),
///   child: ReportsPage(),
/// )
/// ```
class FeatureGate extends StatelessWidget {
  final AppFeature feature;
  final Widget child;
  final Widget? fallback;
  final PermissionGateMode mode;
  final String? deniedMessage;

  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.fallback,
    this.mode = PermissionGateMode.hide,
    this.deniedMessage,
  });

  @override
  Widget build(BuildContext context) {
    final allowed = sl<PermissionService>().canAccessFeature(feature);

    if (allowed) return child;

    if (mode == PermissionGateMode.hide) {
      return fallback ?? const SizedBox.shrink();
    }

    return Tooltip(
      message: deniedMessage ?? feature.deniedMessage,
      child: AbsorbPointer(child: Opacity(opacity: 0.38, child: child)),
    );
  }
}

// ── Dashboard scope builder ───────────────────────────────────────────────────

/// Provides the [DashboardScope] for the current user to a builder function.
///
/// Use in dashboard widgets to show/hide KPI cards dynamically per role
/// without embedding any role logic in the widget itself.
///
/// ```dart
/// DashboardScopeBuilder(
///   builder: (context, scope) => Column(children: [
///     if (scope.showRevenue) RevenueCard(),
///     if (scope.showPersonalSales) PersonalSalesCard(),
///     if (scope.showLowStockAlerts) LowStockCard(),
///   ]),
/// )
/// ```
class DashboardScopeBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DashboardScope scope) builder;

  const DashboardScopeBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final scope = sl<PermissionService>().getDashboardScope();
    return builder(context, scope);
  }
}
