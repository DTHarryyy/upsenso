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

  /// Hold (suspend) the current sale and resume it later.
  holdSale,

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

  /// Create a brand-new product in the catalogue.
  createProduct,

  /// Edit an existing product's details.
  editProduct,

  /// Delete a product from the catalogue.
  deleteProduct,

  /// Change a product's selling price.
  changeProductPricing,

  /// Manage product categories (create / rename / delete).
  manageProductCategories,

  // ── Inventory ─────────────────────────────────────────────────────────────
  /// Open the inventory module (top-level inventory access).
  viewInventory,

  /// Maintain supplier links from within the inventory module.
  manageInventorySuppliers,

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

  /// Delete an expense entry.
  deleteExpense,

  // ── Reports & Analytics ───────────────────────────────────────────────────
  /// View only the current user's own reports.
  viewOwnReports,

  /// Export reports to file (CSV / PDF).
  exportReports,

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
  /// View the employee directory.
  viewEmployees,

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

  /// Create / edit / archive suppliers (separate from full procurement mgmt so
  /// inventory staff can maintain the directory without controlling POs).
  manageSuppliers,

  // ── CRM / Customers ───────────────────────────────────────────────────────
  /// View the customer directory and open a customer's purchase history.
  viewCustomers,

  /// Create / edit / archive customers (also gates quick-add at the till).
  manageCustomers,

  // ── Fraud / Risk ──────────────────────────────────────────────────────────
  /// View fraud alerts raised by the on-device detection engine.
  viewFraudAlerts,

  /// Resolve or dismiss a fraud alert (server blocks self-resolution).
  resolveFraudAlerts,

  // ── Procurement ───────────────────────────────────────────────────────────
  /// View purchase orders and procurement history.
  viewProcurement,

  /// Create a new purchase order.
  createPurchaseOrder,

  /// Approve a purchase order (separate from creation — separation of duties).
  approvePurchaseOrder,

  /// Receive goods against an approved purchase order.
  receiveGoodsAgainstPo,

  /// Full procurement management (edit/cancel POs, manage suppliers).
  manageProcurement,

  // ── Recipes / Ingredients ─────────────────────────────────────────────────
  /// View the ingredient directory and recipes (read-only).
  viewIngredients,

  /// Create / edit / delete ingredients (stock items consumed by recipes).
  manageIngredients,

  /// Configure recipes (bill of materials) on recipe-based products.
  manageRecipes,

  // ── System / Admin ────────────────────────────────────────────────────────
  /// Manage role definitions and permission matrices.
  manageRoles,

  /// Access the system settings page.
  accessSettings,

  /// Edit receipt-template settings.
  editReceiptSettings,

  /// Edit business-level settings.
  editBusinessSettings,

  /// Edit branch-level settings.
  editBranchSettings,

  /// View audit log entries.
  viewAuditLogs,

  /// Delete or purge audit log entries.
  deleteAuditLogs,

  /// Run the tamper-evidence verification over the audit hash chain.
  verifyAuditChain,

  /// Access data across multiple branches (Business Owner only).
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
      case AppPermission.holdSale:
        return 'Hold Sale';
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
      case AppPermission.createProduct:
        return 'Create Product';
      case AppPermission.editProduct:
        return 'Edit Product';
      case AppPermission.deleteProduct:
        return 'Delete Product';
      case AppPermission.changeProductPricing:
        return 'Change Product Pricing';
      case AppPermission.manageProductCategories:
        return 'Manage Product Categories';
      case AppPermission.viewInventory:
        return 'View Inventory';
      case AppPermission.manageInventorySuppliers:
        return 'Manage Inventory Suppliers';
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
      case AppPermission.deleteExpense:
        return 'Delete Expense';
      case AppPermission.viewOwnReports:
        return 'View Own Reports';
      case AppPermission.exportReports:
        return 'Export Reports';
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
      case AppPermission.viewEmployees:
        return 'View Employees';
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
      case AppPermission.manageSuppliers:
        return 'Manage Suppliers';
      case AppPermission.viewCustomers:
        return 'View Customers';
      case AppPermission.manageCustomers:
        return 'Manage Customers';
      case AppPermission.viewFraudAlerts:
        return 'View Fraud Alerts';
      case AppPermission.resolveFraudAlerts:
        return 'Resolve Fraud Alerts';
      case AppPermission.viewProcurement:
        return 'View Procurement';
      case AppPermission.createPurchaseOrder:
        return 'Create Purchase Order';
      case AppPermission.approvePurchaseOrder:
        return 'Approve Purchase Order';
      case AppPermission.receiveGoodsAgainstPo:
        return 'Receive Goods';
      case AppPermission.manageProcurement:
        return 'Manage Procurement';
      case AppPermission.viewIngredients:
        return 'View Ingredients';
      case AppPermission.manageIngredients:
        return 'Manage Ingredients';
      case AppPermission.manageRecipes:
        return 'Manage Recipes';
      case AppPermission.manageRoles:
        return 'Manage Roles';
      case AppPermission.accessSettings:
        return 'Access Settings';
      case AppPermission.editReceiptSettings:
        return 'Edit Receipt Settings';
      case AppPermission.editBusinessSettings:
        return 'Edit Business Settings';
      case AppPermission.editBranchSettings:
        return 'Edit Branch Settings';
      case AppPermission.viewAuditLogs:
        return 'View Audit Logs';
      case AppPermission.deleteAuditLogs:
        return 'Delete Audit Logs';
      case AppPermission.verifyAuditChain:
        return 'Verify Audit Chain';
      case AppPermission.crossBranchAccess:
        return 'Cross-Branch Access';
    }
  }

  /// Default denial message shown to the user.
  String get deniedMessage =>
      'You do not have permission to: ${displayLabel.toLowerCase()}.';

  /// Maps this legacy [AppPermission] to the canonical [PermissionKeys] string.
  ///
  /// Used by [PermissionService.hasPermission] to delegate to the new
  /// per-employee matrix via [PermissionService.can].
  String get permissionKey {
    switch (this) {
      case AppPermission.createSale:
      case AppPermission.processPayment:
      case AppPermission.printReceipt:
        return 'pos.use';
      case AppPermission.applyDiscount:
        return 'pos.apply_discount';
      case AppPermission.holdSale:
        return 'pos.hold_sale';
      case AppPermission.voidSale:
      case AppPermission.deleteSale:
        return 'pos.void_sale';
      case AppPermission.approveVoidTransaction:
        return 'pos.approve_void';
      case AppPermission.refundSale:
        return 'pos.refund_sale';
      case AppPermission.approveRefund:
        return 'pos.approve_refund';
      case AppPermission.openShift:
        return 'pos.open_shift';
      case AppPermission.closeShift:
      case AppPermission.resolveCashDiscrepancy:
        return 'pos.close_shift';
      case AppPermission.viewOwnShiftSales:
      case AppPermission.viewOwnShiftSummary:
        return 'pos.view_own_sales';
      case AppPermission.viewAllSalesInBranch:
      case AppPermission.viewAllShifts:
      case AppPermission.overrideShiftClosure:
        return 'pos.view_all_sales';
      case AppPermission.viewProducts:
      case AppPermission.viewPriceList:
        return 'products.view';
      case AppPermission.createProduct:
        return 'products.create';
      case AppPermission.editProduct:
        return 'products.edit';
      case AppPermission.deleteProduct:
        return 'products.delete';
      case AppPermission.changeProductPricing:
        return 'products.manage_prices';
      case AppPermission.manageProductCategories:
        return 'products.manage_categories';
      case AppPermission.viewInventory:
        return 'inventory.view';
      case AppPermission.manageInventorySuppliers:
        return 'inventory.manage_suppliers';
      case AppPermission.viewAvailableStock:
      case AppPermission.viewStockHistory:
        return 'inventory.view_levels';
      case AppPermission.updateStockQuantity:
      case AppPermission.receiveStock:
      case AppPermission.recordStockAdjustment:
      case AppPermission.approveStockAdjustment:
        return 'inventory.adjust';
      case AppPermission.transferStockBetweenBranches:
      case AppPermission.approveStockTransfer:
        return 'inventory.adjust';
      case AppPermission.createExpense:
        return 'expenses.create';
      case AppPermission.viewExpenses:
        return 'expenses.view';
      case AppPermission.approveExpense:
      case AppPermission.rejectExpense:
        return 'expenses.approve';
      case AppPermission.deleteExpense:
        return 'expenses.delete';
      case AppPermission.viewOwnReports:
        return 'reports.view_own';
      case AppPermission.exportReports:
        return 'reports.export';
      case AppPermission.viewBranchReports:
      case AppPermission.viewSalesAnalytics:
      case AppPermission.viewInventoryAnalytics:
      case AppPermission.viewInventoryReports:
        return 'reports.view_branch';
      case AppPermission.viewFinancialReports:
      case AppPermission.viewProfitAnalytics:
        return 'reports.view_all';
      case AppPermission.viewEmployees:
        return 'employees.view';
      case AppPermission.createEmployee:
        return 'employees.create';
      case AppPermission.editEmployee:
        return 'employees.edit';
      case AppPermission.assignRole:
      case AppPermission.manageRoles:
        return 'employees.assign_role';
      case AppPermission.suspendEmployee:
        return 'employees.suspend';
      case AppPermission.viewSupplierList:
        return 'suppliers.view';
      case AppPermission.manageSuppliers:
        return 'suppliers.manage';
      case AppPermission.viewCustomers:
        return 'crm.view';
      case AppPermission.manageCustomers:
        return 'crm.manage';
      case AppPermission.viewFraudAlerts:
        return 'fraud.view';
      case AppPermission.resolveFraudAlerts:
        return 'fraud.resolve';
      case AppPermission.viewProcurement:
        return 'procurement.view';
      case AppPermission.createPurchaseOrder:
        return 'procurement.create_po';
      case AppPermission.approvePurchaseOrder:
        return 'procurement.approve_po';
      case AppPermission.receiveGoodsAgainstPo:
        return 'procurement.receive';
      case AppPermission.manageProcurement:
        return 'procurement.manage';
      case AppPermission.viewIngredients:
        return 'ingredients.view';
      case AppPermission.manageIngredients:
        return 'ingredients.manage';
      case AppPermission.manageRecipes:
        return 'recipes.manage';
      case AppPermission.accessSettings:
        return 'settings.view';
      case AppPermission.editReceiptSettings:
        return 'settings.edit_receipt';
      case AppPermission.editBusinessSettings:
        return 'settings.edit_business';
      case AppPermission.editBranchSettings:
        return 'settings.edit_branch';
      case AppPermission.viewAuditLogs:
        return 'audit_logs.view';
      case AppPermission.deleteAuditLogs:
        return 'audit_logs.delete';
      case AppPermission.verifyAuditChain:
        return 'audit_logs.verify';
      case AppPermission.crossBranchAccess:
        return 'data.cross_branch_access';
    }
  }
}
