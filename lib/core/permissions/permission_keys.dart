/// All permission keys used in UPSENSO.
///
/// Keys use dot-notation: `<module>.<action>`.
///
/// These string constants are the SINGLE SOURCE OF TRUTH for permission
/// identifiers shared between:
///  - Supabase `employee_permissions.permissions` JSONB
///  - Local Drift `employee_permissions_cache.permissions_json`
///  - [PermissionService.can]
///  - [PermissionGate] widgets
///  - GoRouter redirect guards
///
/// NEVER use raw strings in permission checks — always reference this class.
abstract final class PermissionKeys {
  // ── POS / Checkout ────────────────────────────────────────────────────────
  static const String posUse = 'pos.use';
  static const String posApplyDiscount = 'pos.apply_discount';
  static const String posHoldSale = 'pos.hold_sale';
  static const String posVoidSale = 'pos.void_sale';
  static const String posApproveVoid = 'pos.approve_void';
  static const String posRefundSale = 'pos.refund_sale';
  static const String posApproveRefund = 'pos.approve_refund';
  static const String posOpenShift = 'pos.open_shift';
  static const String posCloseShift = 'pos.close_shift';
  static const String posViewOwnSales = 'pos.view_own_sales';
  static const String posViewAllSales = 'pos.view_all_sales';

  // ── Products ──────────────────────────────────────────────────────────────
  static const String productsView = 'products.view';
  static const String productsCreate = 'products.create';
  static const String productsEdit = 'products.edit';
  static const String productsDelete = 'products.delete';
  static const String productsManagePrices = 'products.manage_prices';
  static const String productsManageCategories = 'products.manage_categories';

  // ── Inventory ─────────────────────────────────────────────────────────────
  static const String inventoryView = 'inventory.view';
  static const String inventoryAdjust = 'inventory.adjust';
  static const String inventoryViewLevels = 'inventory.view_levels';
  static const String inventoryManageSuppliers = 'inventory.manage_suppliers';

  // ── Expenses ──────────────────────────────────────────────────────────────
  static const String expensesView = 'expenses.view';
  static const String expensesCreate = 'expenses.create';
  static const String expensesApprove = 'expenses.approve';
  static const String expensesDelete = 'expenses.delete';

  // ── Reports ───────────────────────────────────────────────────────────────
  static const String reportsViewOwn = 'reports.view_own';
  static const String reportsViewBranch = 'reports.view_branch';
  static const String reportsViewAll = 'reports.view_all';
  static const String reportsExport = 'reports.export';

  // ── Employees ─────────────────────────────────────────────────────────────
  static const String employeesView = 'employees.view';
  static const String employeesCreate = 'employees.create';
  static const String employeesEdit = 'employees.edit';
  static const String employeesSuspend = 'employees.suspend';
  static const String employeesAssignRole = 'employees.assign_role';

  // ── Settings ──────────────────────────────────────────────────────────────
  static const String settingsView = 'settings.view';
  static const String settingsEditReceipt = 'settings.edit_receipt';
  static const String settingsEditBusiness = 'settings.edit_business';
  static const String settingsEditBranch = 'settings.edit_branch';

  // ── Audit Logs ────────────────────────────────────────────────────────────
  static const String auditLogsView = 'audit_logs.view';
  static const String auditLogsDelete = 'audit_logs.delete';
  static const String auditLogsVerify = 'audit_logs.verify';

  // ── Suppliers ─────────────────────────────────────────────────────────────
  static const String suppliersView = 'suppliers.view';
  static const String suppliersManage = 'suppliers.manage';

  // ── CRM / Customers ───────────────────────────────────────────────────────
  static const String crmView = 'crm.view';
  static const String crmManage = 'crm.manage';

  // ── Fraud / Risk ──────────────────────────────────────────────────────────
  static const String fraudView = 'fraud.view';
  static const String fraudResolve = 'fraud.resolve';

  // ── Ingredients / Recipes ─────────────────────────────────────────────────
  static const String ingredientsView = 'ingredients.view';
  static const String ingredientsManage = 'ingredients.manage';
  static const String recipesManage = 'recipes.manage';

  // ── Procurement ───────────────────────────────────────────────────────────
  static const String procurementView = 'procurement.view';
  static const String procurementCreatePo = 'procurement.create_po';
  static const String procurementApprovePo = 'procurement.approve_po';
  static const String procurementReceive = 'procurement.receive';
  static const String procurementManage = 'procurement.manage';

  // ── Dashboard widgets ─────────────────────────────────────────────────────
  static const String dashboardViewStats = 'dashboard.view_stats';
  static const String dashboardViewBranchComparison =
      'dashboard.view_branch_comparison';
  static const String dashboardViewExpenses = 'dashboard.view_expenses';
  static const String dashboardViewLowStock = 'dashboard.view_low_stock';

  // ── Navigation / module entry points ─────────────────────────────────────
  // Used by route guards and sidebar visibility helpers.
  static const String navPos = 'nav.pos';
  static const String navInventory = 'nav.inventory';
  static const String navReports = 'nav.reports';
  static const String navExpenses = 'nav.expenses';
  static const String navEmployees = 'nav.employees';
  static const String navSettings = 'nav.settings';
  static const String navAuditLogs = 'nav.audit_logs';
  static const String navSalesHistory = 'nav.sales_history';
  static const String navHeldSales = 'nav.held_sales';
  static const String navSuppliers = 'nav.suppliers';
  static const String navProcurement = 'nav.procurement';
  static const String navRecipes = 'nav.recipes';
  static const String navCustomers = 'nav.customers';
  static const String navFraud = 'nav.fraud';
  static const String navBilling = 'nav.billing';

  // ── Billing / subscription (M7.1) ─────────────────────────────────────────
  static const String billingView = 'billing.view';
  static const String billingManage = 'billing.manage';

  // ── Data scoping ──────────────────────────────────────────────────────────
  static const String dataCrossBranchAccess = 'data.cross_branch_access';

  // ── Full key set (for validation / seeding) ───────────────────────────────
  static const List<String> all = [
    posUse,
    posApplyDiscount,
    posHoldSale,
    posVoidSale,
    posApproveVoid,
    posRefundSale,
    posApproveRefund,
    posOpenShift,
    posCloseShift,
    posViewOwnSales,
    posViewAllSales,
    productsView,
    productsCreate,
    productsEdit,
    productsDelete,
    productsManagePrices,
    productsManageCategories,
    inventoryView,
    inventoryAdjust,
    inventoryViewLevels,
    inventoryManageSuppliers,
    expensesView,
    expensesCreate,
    expensesApprove,
    expensesDelete,
    reportsViewOwn,
    reportsViewBranch,
    reportsViewAll,
    reportsExport,
    employeesView,
    employeesCreate,
    employeesEdit,
    employeesSuspend,
    employeesAssignRole,
    settingsView,
    settingsEditReceipt,
    settingsEditBusiness,
    settingsEditBranch,
    auditLogsView,
    auditLogsDelete,
    auditLogsVerify,
    suppliersView,
    suppliersManage,
    crmView,
    crmManage,
    fraudView,
    fraudResolve,
    dashboardViewStats,
    dashboardViewBranchComparison,
    dashboardViewExpenses,
    dashboardViewLowStock,
    navPos,
    navInventory,
    navReports,
    navExpenses,
    navEmployees,
    navSettings,
    navAuditLogs,
    navSalesHistory,
    navHeldSales,
    navSuppliers,
    navProcurement,
    navRecipes,
    navCustomers,
    navFraud,
    navBilling,
    billingView,
    billingManage,
    ingredientsView,
    ingredientsManage,
    recipesManage,
    procurementView,
    procurementCreatePo,
    procurementApprovePo,
    procurementReceive,
    procurementManage,
    dataCrossBranchAccess,
  ];
}
