/// Every discrete action in UPSENSO is represented as an [AppPermission].
///
/// Groups:
///   • POS / Checkout
///   • Shifts
///   • Products
///   • Inventory
///   • Expenses
///   • Reports
///   • Employees
///   • Suppliers
///   • System
///
/// NEVER scatter permission checks in UI widgets or BLoCs.
/// Always delegate to [PermissionService].
enum AppPermission {
  // ── POS / Checkout ────────────────────────────────────────────────────────
  /// Create a new sale transaction.
  createSale,

  /// Process a payment (cash / card / e-wallet).
  processPayment,

  /// Apply a discount to a cart item or whole order.
  applyDiscount,

  /// Print or re-print a receipt.
  printReceipt,

  /// View only the sales made during the current user's own shift.
  viewOwnShiftSales,

  /// View ALL sales within the branch (manager-level).
  viewAllSalesInBranch,

  /// Permanently delete a sale record.
  deleteSale,

  /// Void (cancel) a completed sale.
  voidSale,

  /// Issue a refund on a completed sale.
  refundSale,

  /// Approve a refund request raised by a cashier.
  approveRefund,

  /// Approve a void-transaction request raised by a cashier.
  approveVoidTransaction,

  // ── Shifts ────────────────────────────────────────────────────────────────
  /// Open a cash register shift.
  openShift,

  /// Close a cash register shift.
  closeShift,

  /// View the summary of the current user's own shift.
  viewOwnShiftSummary,

  /// View the shift summaries of ALL employees in the branch.
  viewAllShifts,

  /// Override or forcibly close another employee's shift.
  overrideShiftClosure,

  /// Record or resolve a cash discrepancy on shift close.
  resolveCashDiscrepancy,

  // ── Products ──────────────────────────────────────────────────────────────
  /// Browse the product catalogue (read-only).
  viewProducts,

  /// View current prices and price lists.
  viewPriceList,

  /// Edit an existing product's details.
  editProduct,

  /// Delete a product from the catalogue.
  deleteProduct,

  /// Change a product's selling price.
  changeProductPricing,

  // ── Inventory ─────────────────────────────────────────────────────────────
  /// View current stock levels (read-only).
  viewAvailableStock,

  /// Directly update a product's stock quantity.
  updateStockQuantity,

  /// Record an incoming stock delivery / purchase order receipt.
  receiveStock,

  /// Log a stock adjustment (shrinkage, damage, count correction).
  recordStockAdjustment,

  /// Approve a stock adjustment submitted by inventory staff.
  approveStockAdjustment,

  /// Initiate a stock transfer to another branch.
  transferStockBetweenBranches,

  /// Approve an outgoing stock transfer.
  approveStockTransfer,

  /// View the full stock movement history / ledger.
  viewStockHistory,

  // ── Expenses ──────────────────────────────────────────────────────────────
  /// Create an expense entry.
  createExpense,

  /// View expense records.
  viewExpenses,

  /// Approve a pending expense.
  approveExpense,

  /// Reject a pending expense.
  rejectExpense,

  // ── Reports & Analytics ───────────────────────────────────────────────────
  /// View standard branch-level reports (daily summary, etc.).
  viewBranchReports,

  /// View the sales analytics dashboard.
  viewSalesAnalytics,

  /// View inventory analytics (stock health, turnover, etc.).
  viewInventoryAnalytics,

  /// View inventory reports (counts, adjustments, transfers).
  viewInventoryReports,

  /// View full financial reports (P&L, revenue, margins).
  viewFinancialReports,

  /// View profit & loss analytics.
  viewProfitAnalytics,

  // ── Employees ─────────────────────────────────────────────────────────────
  /// Create a new employee account.
  createEmployee,

  /// Edit an existing employee's profile.
  editEmployee,

  /// Assign or change a role for an employee within the branch.
  assignRole,

  /// Suspend an employee.
  suspendEmployee,

  // ── Suppliers ─────────────────────────────────────────────────────────────
  /// View the supplier directory.
  viewSupplierList,

  // ── System / Admin ────────────────────────────────────────────────────────
  /// Manage role definitions and permission matrices.
  manageRoles,

  /// Access the system settings page.
  accessSettings,

  /// Delete or purge audit log entries.
  deleteAuditLogs,

  /// Access data across multiple branches (Super Admin only).
  crossBranchAccess,
}

extension AppPermissionX on AppPermission {
  /// Human-readable label shown in error messages and UI tooltips.
  String get displayLabel {
    switch (this) {
      case AppPermission.createSale:
        return 'Create Sale';
      case AppPermission.processPayment:
        return 'Process Payment';
      case AppPermission.applyDiscount:
        return 'Apply Discount';
      case AppPermission.printReceipt:
        return 'Print Receipt';
      case AppPermission.viewOwnShiftSales:
        return 'View Own Shift Sales';
      case AppPermission.viewAllSalesInBranch:
        return 'View All Sales in Branch';
      case AppPermission.deleteSale:
        return 'Delete Sale';
      case AppPermission.voidSale:
        return 'Void Sale';
      case AppPermission.refundSale:
        return 'Refund Sale';
      case AppPermission.approveRefund:
        return 'Approve Refund';
      case AppPermission.approveVoidTransaction:
        return 'Approve Void Transaction';
      case AppPermission.openShift:
        return 'Open Shift';
      case AppPermission.closeShift:
        return 'Close Shift';
      case AppPermission.viewOwnShiftSummary:
        return 'View Own Shift Summary';
      case AppPermission.viewAllShifts:
        return 'View All Shifts';
      case AppPermission.overrideShiftClosure:
        return 'Override Shift Closure';
      case AppPermission.resolveCashDiscrepancy:
        return 'Resolve Cash Discrepancy';
      case AppPermission.viewProducts:
        return 'View Products';
      case AppPermission.viewPriceList:
        return 'View Price List';
      case AppPermission.editProduct:
        return 'Edit Product';
      case AppPermission.deleteProduct:
        return 'Delete Product';
      case AppPermission.changeProductPricing:
        return 'Change Product Pricing';
      case AppPermission.viewAvailableStock:
        return 'View Available Stock';
      case AppPermission.updateStockQuantity:
        return 'Update Stock Quantity';
      case AppPermission.receiveStock:
        return 'Receive Stock';
      case AppPermission.recordStockAdjustment:
        return 'Record Stock Adjustment';
      case AppPermission.approveStockAdjustment:
        return 'Approve Stock Adjustment';
      case AppPermission.transferStockBetweenBranches:
        return 'Transfer Stock Between Branches';
      case AppPermission.approveStockTransfer:
        return 'Approve Stock Transfer';
      case AppPermission.viewStockHistory:
        return 'View Stock History';
      case AppPermission.createExpense:
        return 'Create Expense';
      case AppPermission.viewExpenses:
        return 'View Expenses';
      case AppPermission.approveExpense:
        return 'Approve Expense';
      case AppPermission.rejectExpense:
        return 'Reject Expense';
      case AppPermission.viewBranchReports:
        return 'View Branch Reports';
      case AppPermission.viewSalesAnalytics:
        return 'View Sales Analytics';
      case AppPermission.viewInventoryAnalytics:
        return 'View Inventory Analytics';
      case AppPermission.viewInventoryReports:
        return 'View Inventory Reports';
      case AppPermission.viewFinancialReports:
        return 'View Financial Reports';
      case AppPermission.viewProfitAnalytics:
        return 'View Profit Analytics';
      case AppPermission.createEmployee:
        return 'Create Employee';
      case AppPermission.editEmployee:
        return 'Edit Employee';
      case AppPermission.assignRole:
        return 'Assign Role';
      case AppPermission.suspendEmployee:
        return 'Suspend Employee';
      case AppPermission.viewSupplierList:
        return 'View Supplier List';
      case AppPermission.manageRoles:
        return 'Manage Roles';
      case AppPermission.accessSettings:
        return 'Access Settings';
      case AppPermission.deleteAuditLogs:
        return 'Delete Audit Logs';
      case AppPermission.crossBranchAccess:
        return 'Cross-Branch Access';
    }
  }

  /// Default denial message shown to the user.
  String get deniedMessage =>
      'You do not have permission to: ${displayLabel.toLowerCase()}.';
}
