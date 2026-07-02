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

  /// Business Owner dashboard — all branches, full financials.
  dashboardOwner,

  // ── Sub-modules ───────────────────────────────────────────────────────────
  /// Product catalogue browsing and management.
  productsCatalogue,

  /// Supplier directory (sub-feature of procurement module).
  supplierDirectory,

  /// Customer directory / CRM — customers list, detail, purchase history.
  customerDirectory,

  /// Procurement module — purchase orders, receiving, supplier management.
  procurement,

  /// Ingredient directory — stock items consumed by recipe-based products.
  ingredientsManagement,

  /// Recipe / bill-of-materials configuration on recipe-based products.
  recipeManagement,

  /// Audit log viewer.
  auditLogs,

  /// Own profile settings page.
  profileSettings,

  /// Sales history / transaction log viewer.
  salesHistory,
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
      case AppFeature.customerDirectory:
        return 'Customers';
      case AppFeature.procurement:
        return 'Procurement';
      case AppFeature.ingredientsManagement:
        return 'Ingredients';
      case AppFeature.recipeManagement:
        return 'Recipes';
      case AppFeature.auditLogs:
        return 'Audit Logs';
      case AppFeature.profileSettings:
        return 'Profile Settings';
      case AppFeature.salesHistory:
        return 'Sales History';
    }
  }

  /// Default denial message.
  String get deniedMessage =>
      'You do not have access to: ${displayLabel.toLowerCase()}.';

  /// Maps this feature to the business-module code that gates it.
  ///
  /// Returns `null` for features that are not module-gated (dashboards, profile,
  /// settings) — those are always accessible when the user has the nav permission.
  String? get moduleCode {
    switch (this) {
      case AppFeature.posTerminal:
        return 'pos';
      case AppFeature.inventoryManagement:
      case AppFeature.productsCatalogue:
        return 'inventory';
      case AppFeature.expensesModule:
        return 'expenses';
      case AppFeature.employeeManagement:
        return 'employees';
      case AppFeature.reportsAnalytics:
        return 'reports';
      // Supplier directory is a sub-feature gated by the procurement module.
      case AppFeature.supplierDirectory:
      case AppFeature.procurement:
        return 'procurement';
      // Ingredients has its own module so it can be toggled independently.
      case AppFeature.ingredientsManagement:
        return 'ingredients';
      case AppFeature.recipeManagement:
        return 'recipes';
      case AppFeature.auditLogs:
        return 'audit';
      // CRM has its own module (seeded as `crm` in the modules catalogue).
      case AppFeature.customerDirectory:
        return 'crm';
      // Not module-gated:
      case AppFeature.businessSettings:
      case AppFeature.branchConfiguration:
      case AppFeature.profileSettings:
      case AppFeature.salesHistory:
      case AppFeature.dashboardCashier:
      case AppFeature.dashboardInventory:
      case AppFeature.dashboardManager:
      case AppFeature.dashboardOwner:
        return null;
    }
  }

  /// Maps this legacy [AppFeature] to the canonical [PermissionKeys] nav key.
  ///
  /// Used by [PermissionService.canAccessFeature] to delegate to the new
  /// per-employee matrix via [PermissionService.can].
  String get navKey {
    switch (this) {
      case AppFeature.posTerminal:
        return 'nav.pos';
      case AppFeature.inventoryManagement:
        return 'nav.inventory';
      case AppFeature.expensesModule:
        return 'nav.expenses';
      case AppFeature.employeeManagement:
        return 'nav.employees';
      case AppFeature.reportsAnalytics:
        return 'nav.reports';
      case AppFeature.businessSettings:
      case AppFeature.branchConfiguration:
      case AppFeature.profileSettings:
        return 'nav.settings';
      case AppFeature.auditLogs:
        return 'nav.audit_logs';
      case AppFeature.supplierDirectory:
        return 'nav.suppliers';
      case AppFeature.customerDirectory:
        return 'nav.customers';
      case AppFeature.procurement:
        return 'nav.procurement';
      case AppFeature.ingredientsManagement:
      case AppFeature.recipeManagement:
        return 'nav.recipes';
      case AppFeature.productsCatalogue:
        return 'nav.inventory';
      case AppFeature.salesHistory:
        return 'nav.sales_history';
      // Dashboard variants: everyone with a session may see *some* dashboard.
      case AppFeature.dashboardCashier:
      case AppFeature.dashboardInventory:
      case AppFeature.dashboardManager:
      case AppFeature.dashboardOwner:
        return 'dashboard.view_stats';
    }
  }
}
