/// Every top-level feature / module in UPSENSO.
///
/// [RolePermissionMatrix] maps each role to the subset of features it may open.
/// [PermissionService.canAccessFeature] uses this to guard navigation and module entry.
///
/// This is separate from [AppPermission] (which controls fine-grained ACTIONS).
/// Feature access = "can this role open this screen/module at all?"
/// Action permission = "can this role press this button inside the module?"
enum AppFeature {
  // ── Core modules ──────────────────────────────────────────────────────────
  /// POS terminal / checkout screen.
  posTerminal,

  /// Full inventory management (stock, adjustments, transfers, receiving).
  inventoryManagement,

  /// Expenses recording, review and approval.
  expensesModule,

  /// Employee management (create, edit, roles, suspension).
  employeeManagement,

  /// Reports & analytics screens.
  reportsAnalytics,

  /// Business-wide settings (name, logo, tax, payment methods, etc.).
  businessSettings,

  /// Branch-level configuration (hours, address, receipt template).
  branchConfiguration,

  // ── Dashboard views (one per role; mutually exclusive by role) ─────────────
  /// Cashier dashboard — personal sales + shift status only.
  dashboardCashier,

  /// Inventory staff dashboard — stock alerts + movements only.
  dashboardInventory,

  /// Branch Manager dashboard — branch KPIs, cashier performance, alerts.
  dashboardManager,

  /// Owner / Super Admin dashboard — all branches, full financials.
  dashboardOwner,

  // ── Sub-modules ───────────────────────────────────────────────────────────
  /// Product catalogue browsing and management.
  productsCatalogue,

  /// Supplier directory.
  supplierDirectory,

  /// Audit log viewer.
  auditLogs,

  /// Own profile settings page.
  profileSettings,
}

extension AppFeatureX on AppFeature {
  /// Human-readable label for use in error messages and UI.
  String get displayLabel {
    switch (this) {
      case AppFeature.posTerminal:
        return 'POS Terminal';
      case AppFeature.inventoryManagement:
        return 'Inventory Management';
      case AppFeature.expensesModule:
        return 'Expenses';
      case AppFeature.employeeManagement:
        return 'Employee Management';
      case AppFeature.reportsAnalytics:
        return 'Reports & Analytics';
      case AppFeature.businessSettings:
        return 'Business Settings';
      case AppFeature.branchConfiguration:
        return 'Branch Configuration';
      case AppFeature.dashboardCashier:
        return 'Cashier Dashboard';
      case AppFeature.dashboardInventory:
        return 'Inventory Dashboard';
      case AppFeature.dashboardManager:
        return 'Manager Dashboard';
      case AppFeature.dashboardOwner:
        return 'Owner Dashboard';
      case AppFeature.productsCatalogue:
        return 'Products Catalogue';
      case AppFeature.supplierDirectory:
        return 'Supplier Directory';
      case AppFeature.auditLogs:
        return 'Audit Logs';
      case AppFeature.profileSettings:
        return 'Profile Settings';
    }
  }

  /// Default denial message.
  String get deniedMessage =>
      'You do not have access to: ${displayLabel.toLowerCase()}.';
}
