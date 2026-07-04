/// All supported audit log action types, grouped by domain.
enum AuditLogActionType {
  // ── POS ──────────────────────────────────────────────────────────────────
  saleCreated,
  saleVoided,
  refundCreated,
  discountApplied,
  draftCreated,
  draftResumed,
  draftDiscarded,
  draftConverted,

  // ── Inventory ────────────────────────────────────────────────────────────
  stockAdded,
  stockUpdated,
  stockTransferred,
  stockAdjusted,

  // ── Expenses ─────────────────────────────────────────────────────────────
  expenseCreated,
  expenseApproved,
  expenseRejected,

  // ── Employees ──────────────────────────────────────────────────────────
  employeeCreated,
  employeeUpdated,
  employeeArchived,
  employeeRoleChanged,
  employeeStatusChanged,
  employeeRestored,
  employeeDuplicateDetected,

  // ── Catalog ────────────────────────────────────────────────────────────────
  productCreated,
  productUpdated,
  categoryCreated,
  branchCreated,

  // ── Ingredients ──────────────────────────────────────────────────────────
  ingredientCreated,
  ingredientUpdated,
  ingredientDeleted,

  // ── Procurement ────────────────────────────────────────────────────────────
  supplierCreated,
  supplierUpdated,
  supplierDeleted,
  purchaseOrderCreated,
  purchaseOrderUpdated,
  purchaseOrderSubmitted,
  purchaseOrderApproved,
  purchaseOrderReceived,
  purchaseOrderCancelled,

  // ── CRM / Customers ────────────────────────────────────────────────────────
  customerCreated,
  customerUpdated,
  customerArchived,

  // ── Settings ─────────────────────────────────────────────────────────────
  businessModuleChanged,

  /// Refund approval controls changed (require-approval toggle / threshold) —
  /// watched by the CONTROL_CHANGE fraud rule, since the threshold is the
  /// number refund structuring hides under.
  refundSettingsChanged,

  // ── Fraud engine ─────────────────────────────────────────────────────────
  /// The engine raised a new fraud flag — chained, so deleting the flag
  /// locally still leaves a tamper-evident trace that it existed.
  fraudFlagRaised,

  /// A fraud flag was resolved/dismissed (who + status in metadata).
  fraudFlagResolved,

  /// A conflicted device chain tail was re-chained past the server head
  /// (benign same-device restart) — seq range in metadata.
  auditChainReconciled,

  // ── Permissions ──────────────────────────────────────────────────────────
  /// A user attempted an action they are not authorised to perform.
  permissionDenied,

  /// An admin explicitly granted or changed a permission override for an employee.
  permissionOverrideSet,

  /// An admin removed a permission override, reverting the employee to their role default.
  permissionOverrideRemoved,

  /// A raw INSERT/UPDATE/DELETE on user_permissions, branch_permissions, or
  /// business_modules, captured directly by a DB trigger (log_permission_change)
  /// rather than the app's own logging — independent of, and may appear
  /// alongside, the matching permissionOverrideSet/Removed/businessModuleChanged
  /// entry for the same change.
  permissionTableChanged,

  // ── Approval flows ───────────────────────────────────────────────────────
  /// A Branch Manager approved a cashier's refund request.
  refundApprovedByManager,

  /// A Branch Manager approved a void-transaction request.
  voidApprovedByManager,

  /// A Branch Manager approved a stock adjustment.
  stockAdjustmentApproved,

  /// A Branch Manager approved a stock transfer.
  stockTransferApproved,

  // ── System ───────────────────────────────────────────────────────────────
  userLogin,
  userLogout,
  syncStarted,
  syncCompleted,
  syncFailed,
}

extension AuditLogActionTypeX on AuditLogActionType {
  String get value {
    switch (this) {
      case AuditLogActionType.saleCreated:
        return 'SALE_CREATED';
      case AuditLogActionType.saleVoided:
        return 'SALE_VOIDED';
      case AuditLogActionType.refundCreated:
        return 'REFUND_CREATED';
      case AuditLogActionType.discountApplied:
        return 'DISCOUNT_APPLIED';
      case AuditLogActionType.draftCreated:
        return 'DRAFT_CREATED';
      case AuditLogActionType.draftResumed:
        return 'DRAFT_RESUMED';
      case AuditLogActionType.draftDiscarded:
        return 'DRAFT_DISCARDED';
      case AuditLogActionType.draftConverted:
        return 'DRAFT_CONVERTED';
      case AuditLogActionType.stockAdded:
        return 'STOCK_ADDED';
      case AuditLogActionType.stockUpdated:
        return 'STOCK_UPDATED';
      case AuditLogActionType.stockTransferred:
        return 'STOCK_TRANSFERRED';
      case AuditLogActionType.stockAdjusted:
        return 'STOCK_ADJUSTED';
      case AuditLogActionType.expenseCreated:
        return 'EXPENSE_CREATED';
      case AuditLogActionType.expenseApproved:
        return 'EXPENSE_APPROVED';
      case AuditLogActionType.expenseRejected:
        return 'EXPENSE_REJECTED';
      case AuditLogActionType.employeeCreated:
        return 'EMPLOYEE_CREATED';
      case AuditLogActionType.employeeUpdated:
        return 'EMPLOYEE_UPDATED';
      case AuditLogActionType.employeeArchived:
        return 'EMPLOYEE_ARCHIVED';
      case AuditLogActionType.employeeRoleChanged:
        return 'EMPLOYEE_ROLE_CHANGED';
      case AuditLogActionType.employeeStatusChanged:
        return 'EMPLOYEE_STATUS_CHANGED';
      case AuditLogActionType.employeeRestored:
        return 'EMPLOYEE_RESTORED';
      case AuditLogActionType.employeeDuplicateDetected:
        return 'EMPLOYEE_DUPLICATE_DETECTED';
      case AuditLogActionType.productCreated:
        return 'PRODUCT_CREATED';
      case AuditLogActionType.productUpdated:
        return 'PRODUCT_UPDATED';
      case AuditLogActionType.categoryCreated:
        return 'CATEGORY_CREATED';
      case AuditLogActionType.branchCreated:
        return 'BRANCH_CREATED';
      case AuditLogActionType.ingredientCreated:
        return 'INGREDIENT_CREATED';
      case AuditLogActionType.ingredientUpdated:
        return 'INGREDIENT_UPDATED';
      case AuditLogActionType.ingredientDeleted:
        return 'INGREDIENT_DELETED';
      case AuditLogActionType.supplierCreated:
        return 'SUPPLIER_CREATED';
      case AuditLogActionType.supplierUpdated:
        return 'SUPPLIER_UPDATED';
      case AuditLogActionType.supplierDeleted:
        return 'SUPPLIER_DELETED';
      case AuditLogActionType.purchaseOrderCreated:
        return 'PURCHASE_ORDER_CREATED';
      case AuditLogActionType.purchaseOrderUpdated:
        return 'PURCHASE_ORDER_UPDATED';
      case AuditLogActionType.purchaseOrderSubmitted:
        return 'PURCHASE_ORDER_SUBMITTED';
      case AuditLogActionType.purchaseOrderApproved:
        return 'PURCHASE_ORDER_APPROVED';
      case AuditLogActionType.purchaseOrderReceived:
        return 'PURCHASE_ORDER_RECEIVED';
      case AuditLogActionType.purchaseOrderCancelled:
        return 'PURCHASE_ORDER_CANCELLED';
      case AuditLogActionType.customerCreated:
        return 'CUSTOMER_CREATED';
      case AuditLogActionType.customerUpdated:
        return 'CUSTOMER_UPDATED';
      case AuditLogActionType.customerArchived:
        return 'CUSTOMER_ARCHIVED';
      case AuditLogActionType.businessModuleChanged:
        return 'BUSINESS_MODULE_CHANGED';
      case AuditLogActionType.refundSettingsChanged:
        return 'REFUND_SETTINGS_CHANGED';
      case AuditLogActionType.fraudFlagRaised:
        return 'FRAUD_FLAG_RAISED';
      case AuditLogActionType.fraudFlagResolved:
        return 'FRAUD_FLAG_RESOLVED';
      case AuditLogActionType.auditChainReconciled:
        return 'AUDIT_CHAIN_RECONCILED';
      case AuditLogActionType.permissionDenied:
        return 'PERMISSION_DENIED';
      case AuditLogActionType.permissionOverrideSet:
        return 'PERMISSION_OVERRIDE_SET';
      case AuditLogActionType.permissionOverrideRemoved:
        return 'PERMISSION_OVERRIDE_REMOVED';
      case AuditLogActionType.permissionTableChanged:
        return 'PERMISSION_TABLE_CHANGED';
      case AuditLogActionType.refundApprovedByManager:
        return 'REFUND_APPROVED_BY_MANAGER';
      case AuditLogActionType.voidApprovedByManager:
        return 'VOID_APPROVED_BY_MANAGER';
      case AuditLogActionType.stockAdjustmentApproved:
        return 'STOCK_ADJUSTMENT_APPROVED';
      case AuditLogActionType.stockTransferApproved:
        return 'STOCK_TRANSFER_APPROVED';
      case AuditLogActionType.userLogin:
        return 'USER_LOGIN';
      case AuditLogActionType.userLogout:
        return 'USER_LOGOUT';
      case AuditLogActionType.syncStarted:
        return 'SYNC_STARTED';
      case AuditLogActionType.syncCompleted:
        return 'SYNC_COMPLETED';
      case AuditLogActionType.syncFailed:
        return 'SYNC_FAILED';
    }
  }

  static AuditLogActionType? fromValue(String value) {
    for (final type in AuditLogActionType.values) {
      if (type.value == value) return type;
    }
    return null;
  }

  String get displayLabel {
    switch (this) {
      case AuditLogActionType.saleCreated:
        return 'Sale Created';
      case AuditLogActionType.saleVoided:
        return 'Sale Voided';
      case AuditLogActionType.refundCreated:
        return 'Refund Created';
      case AuditLogActionType.discountApplied:
        return 'Discount Applied';
      case AuditLogActionType.draftCreated:
        return 'Held Sale Created';
      case AuditLogActionType.draftResumed:
        return 'Held Sale Resumed';
      case AuditLogActionType.draftDiscarded:
        return 'Held Sale Discarded';
      case AuditLogActionType.draftConverted:
        return 'Held Sale Completed';
      case AuditLogActionType.stockAdded:
        return 'Stock Added';
      case AuditLogActionType.stockUpdated:
        return 'Stock Updated';
      case AuditLogActionType.stockTransferred:
        return 'Stock Transferred';
      case AuditLogActionType.stockAdjusted:
        return 'Stock Adjusted';
      case AuditLogActionType.expenseCreated:
        return 'Expense Created';
      case AuditLogActionType.expenseApproved:
        return 'Expense Approved';
      case AuditLogActionType.expenseRejected:
        return 'Expense Rejected';
      case AuditLogActionType.employeeCreated:
        return 'Employee Created';
      case AuditLogActionType.employeeUpdated:
        return 'Employee Updated';
      case AuditLogActionType.employeeArchived:
        return 'Employee Archived';
      case AuditLogActionType.employeeRoleChanged:
        return 'Employee Role Changed';
      case AuditLogActionType.employeeStatusChanged:
        return 'Employee Status Changed';
      case AuditLogActionType.employeeRestored:
        return 'Employee Restored';
      case AuditLogActionType.employeeDuplicateDetected:
        return 'Employee Duplicate Detected';
      case AuditLogActionType.productCreated:
        return 'Product Created';
      case AuditLogActionType.productUpdated:
        return 'Product Updated';
      case AuditLogActionType.categoryCreated:
        return 'Category Created';
      case AuditLogActionType.branchCreated:
        return 'Branch Created';
      case AuditLogActionType.ingredientCreated:
        return 'Ingredient Created';
      case AuditLogActionType.ingredientUpdated:
        return 'Ingredient Updated';
      case AuditLogActionType.ingredientDeleted:
        return 'Ingredient Deleted';
      case AuditLogActionType.supplierCreated:
        return 'Supplier Created';
      case AuditLogActionType.supplierUpdated:
        return 'Supplier Updated';
      case AuditLogActionType.supplierDeleted:
        return 'Supplier Deleted';
      case AuditLogActionType.purchaseOrderCreated:
        return 'Purchase Order Created';
      case AuditLogActionType.purchaseOrderUpdated:
        return 'Purchase Order Updated';
      case AuditLogActionType.purchaseOrderSubmitted:
        return 'Purchase Order Submitted';
      case AuditLogActionType.purchaseOrderApproved:
        return 'Purchase Order Approved';
      case AuditLogActionType.purchaseOrderReceived:
        return 'Purchase Order Received';
      case AuditLogActionType.purchaseOrderCancelled:
        return 'Purchase Order Cancelled';
      case AuditLogActionType.customerCreated:
        return 'Customer Created';
      case AuditLogActionType.customerUpdated:
        return 'Customer Updated';
      case AuditLogActionType.customerArchived:
        return 'Customer Archived';
      case AuditLogActionType.businessModuleChanged:
        return 'Module Setting Changed';
      case AuditLogActionType.refundSettingsChanged:
        return 'Refund Approval Settings Changed';
      case AuditLogActionType.fraudFlagRaised:
        return 'Fraud Alert Raised';
      case AuditLogActionType.fraudFlagResolved:
        return 'Fraud Alert Resolved';
      case AuditLogActionType.auditChainReconciled:
        return 'Audit Chain Reconciled';
      case AuditLogActionType.permissionDenied:
        return 'Permission Denied';
      case AuditLogActionType.permissionOverrideSet:
        return 'Permission Override Set';
      case AuditLogActionType.permissionOverrideRemoved:
        return 'Permission Override Removed';
      case AuditLogActionType.permissionTableChanged:
        return 'Permission Table Changed';
      case AuditLogActionType.refundApprovedByManager:
        return 'Refund Approved by Manager';
      case AuditLogActionType.voidApprovedByManager:
        return 'Void Approved by Manager';
      case AuditLogActionType.stockAdjustmentApproved:
        return 'Stock Adjustment Approved';
      case AuditLogActionType.stockTransferApproved:
        return 'Stock Transfer Approved';
      case AuditLogActionType.userLogin:
        return 'User Login';
      case AuditLogActionType.userLogout:
        return 'User Logout';
      case AuditLogActionType.syncStarted:
        return 'Sync Started';
      case AuditLogActionType.syncCompleted:
        return 'Sync Completed';
      case AuditLogActionType.syncFailed:
        return 'Sync Failed';
    }
  }
}
