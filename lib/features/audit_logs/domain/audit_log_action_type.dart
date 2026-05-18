/// All supported audit log action types, grouped by domain.
enum AuditLogActionType {
  // ── POS ──────────────────────────────────────────────────────────────────
  saleCreated,
  saleVoided,
  refundCreated,
  discountApplied,

  // ── Inventory ────────────────────────────────────────────────────────────
  stockAdded,
  stockUpdated,
  stockTransferred,
  stockAdjusted,

  // ── Expenses ─────────────────────────────────────────────────────────────
  expenseCreated,
  expenseApproved,
  expenseRejected,

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
