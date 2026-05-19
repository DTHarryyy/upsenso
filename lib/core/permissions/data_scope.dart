/// Describes the data visibility scope for the current user.
///
/// Applied by [DataScopingLayer] to filter repository results before they
/// reach the BLoC / UI layer.  All three fields together define the exact
/// slice of data the user is allowed to see:
///
/// | Role            | type          | branchId | userId |
/// |-----------------|---------------|----------|--------|
/// | Owner/SuperAdmin| allBranches   | null     | null   |
/// | Branch Manager  | branchOnly    | set      | null   |
/// | Cashier         | ownOnly       | set      | set    |
/// | Inventory Staff | branchOnly    | set      | null   |
class DataScope {
  /// How broadly this role can see data.
  final DataScopeType type;

  /// Restricts data to this branch when [type] is [DataScopeType.branchOnly]
  /// or [DataScopeType.ownOnly].  Null for [DataScopeType.allBranches].
  final String? branchId;

  /// Restricts data to this user's own records when [type] is
  /// [DataScopeType.ownOnly].  Null for broader scopes.
  final String? userId;

  const DataScope({required this.type, this.branchId, this.userId});

  /// Convenience: no restrictions (owner / super admin).
  const DataScope.unrestricted()
    : type = DataScopeType.allBranches,
      branchId = null,
      userId = null;

  /// Convenience: branch-level restriction.
  const DataScope.branch(String id)
    : type = DataScopeType.branchOnly,
      branchId = id,
      userId = null;

  /// Convenience: own-records-only restriction.
  const DataScope.own({required this.branchId, required this.userId})
    : type = DataScopeType.ownOnly;

  @override
  String toString() =>
      'DataScope(type: $type, branch: $branchId, user: $userId)';
}

/// The breadth of data visibility.
enum DataScopeType {
  /// User can only see their own records (e.g., cashier's own transactions).
  ownOnly,

  /// User can see all records within their assigned branch.
  branchOnly,

  /// User can see records across all branches (owner-level).
  allBranches,
}

/// Per-role configuration of which KPIs and metrics are visible on the
/// dashboard.  Returned by [RolePermissionMatrix.dashboardScopeFor] and
/// consumed by dashboard widgets to show/hide cards dynamically.
class DashboardScope {
  // ── Financial KPIs ────────────────────────────────────────────────────────
  final bool showRevenue;
  final bool showProfit;
  final bool showExpenses;
  final bool showInventoryValue;

  // ── Branch-level analytics ────────────────────────────────────────────────
  final bool showBranchAnalytics;
  final bool showCashierPerformance;
  final bool showExpensesSummary;
  final bool showAnomalyAlerts;

  // ── Inventory metrics ─────────────────────────────────────────────────────
  final bool showLowStockAlerts;
  final bool showStockMovement;
  final bool showOutOfStock;
  final bool showInventoryReceived;

  // ── Personal / shift metrics ──────────────────────────────────────────────
  final bool showPersonalSales;
  final bool showShiftStatus;
  final bool showPersonalTransactionCount;
  final bool showPersonalPaymentSummary;

  const DashboardScope({
    required this.showRevenue,
    required this.showProfit,
    required this.showExpenses,
    required this.showInventoryValue,
    required this.showBranchAnalytics,
    required this.showCashierPerformance,
    required this.showExpensesSummary,
    required this.showAnomalyAlerts,
    required this.showLowStockAlerts,
    required this.showStockMovement,
    required this.showOutOfStock,
    required this.showInventoryReceived,
    required this.showPersonalSales,
    required this.showShiftStatus,
    required this.showPersonalTransactionCount,
    required this.showPersonalPaymentSummary,
  });

  // ── Pre-built scopes ──────────────────────────────────────────────────────

  /// Cashier: personal sales + shift status only. No financials.
  static const cashier = DashboardScope(
    showRevenue: false,
    showProfit: false,
    showExpenses: false,
    showInventoryValue: false,
    showBranchAnalytics: false,
    showCashierPerformance: false,
    showExpensesSummary: false,
    showAnomalyAlerts: false,
    showLowStockAlerts: false,
    showStockMovement: false,
    showOutOfStock: false,
    showInventoryReceived: false,
    showPersonalSales: true,
    showShiftStatus: true,
    showPersonalTransactionCount: true,
    showPersonalPaymentSummary: true,
  );

  /// Inventory staff: stock health only. No revenue, no sales.
  static const inventoryStaff = DashboardScope(
    showRevenue: false,
    showProfit: false,
    showExpenses: false,
    showInventoryValue: false,
    showBranchAnalytics: false,
    showCashierPerformance: false,
    showExpensesSummary: false,
    showAnomalyAlerts: false,
    showLowStockAlerts: true,
    showStockMovement: true,
    showOutOfStock: true,
    showInventoryReceived: true,
    showPersonalSales: false,
    showShiftStatus: false,
    showPersonalTransactionCount: false,
    showPersonalPaymentSummary: false,
  );

  /// Branch Manager: full branch KPIs. No cross-branch data.
  static const branchManager = DashboardScope(
    showRevenue: true,
    showProfit: true,
    showExpenses: true,
    showInventoryValue: true,
    showBranchAnalytics: true,
    showCashierPerformance: true,
    showExpensesSummary: true,
    showAnomalyAlerts: true,
    showLowStockAlerts: true,
    showStockMovement: true,
    showOutOfStock: true,
    showInventoryReceived: true,
    showPersonalSales: false,
    showShiftStatus: false,
    showPersonalTransactionCount: false,
    showPersonalPaymentSummary: false,
  );

  /// Owner / Super Admin: everything.
  static const owner = DashboardScope(
    showRevenue: true,
    showProfit: true,
    showExpenses: true,
    showInventoryValue: true,
    showBranchAnalytics: true,
    showCashierPerformance: true,
    showExpensesSummary: true,
    showAnomalyAlerts: true,
    showLowStockAlerts: true,
    showStockMovement: true,
    showOutOfStock: true,
    showInventoryReceived: true,
    showPersonalSales: true,
    showShiftStatus: true,
    showPersonalTransactionCount: true,
    showPersonalPaymentSummary: true,
  );
}
