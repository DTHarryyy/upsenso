class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String signIn = '/login';
  static const String signUp = '/register';
  static const String verification = '/verification';
  static const String businessProfile = '/business-profile';
  static const String businessProfileSetup = '/business-profile-setup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPasswordVerification =
      '/reset-password-verification';
  static const String resetPassword = '/reset-password';

  // Product routes
  static const String addProduct = '/home/add-product';
  static const String editProduct = '/home/edit-product';

  // Shell tab routes (each gets its own URL)
  static const String dashboard = '/dashboard';
  static const String products = '/products';
  static const String posTerminal = '/pos-terminal';
  static const String reports = '/reports';
  static const String inventory = '/inventory';
  static const String more = '/more';
  static const String stockLevel = '/more/stock-level';

  // AI Assistant
  static const String aiChat = '/ai-chat';
  static const String saleshistory = '/more/sales-history';
  static const String heldSales = '/more/held-sales';

  // Expenses
  static const String expenses = '/more/expenses';

  // Settings
  static const String settings = '/settings';
  static const String systemSettings = '/settings/system';
  static const String receiptSettings = '/settings/receipt';
  static const String moduleSettings = '/settings/modules';
  static const String refundApprovalSettings = '/settings/refund-approval';
  static const String managerPin = '/settings/manager-pin';
  static const String billing = '/settings/billing';
  static const String dataExport = '/settings/export';

  // Receipt preview (post-checkout)
  static const String receiptPreview = '/pos/receipt-preview';

  // Notifications
  static const String notifications = '/notifications';

  // Audit Logs
  static const String auditLogs = '/more/audit-logs';

  // Employees
  static const String employees = '/more/employees';
  static const String employeePermissions = '/more/employees/permissions';

  // Procurement
  static const String suppliers = '/more/suppliers';
  static const String supplierDetail = '/more/suppliers/detail';
  static const String purchaseOrders = '/more/purchase-orders';
  static const String poForm = '/more/purchase-orders/form';
  static const String poDetail = '/more/purchase-orders/detail';

  // Recipes / Ingredients
  static const String ingredients = '/more/ingredients';

  // CRM / Customers
  static const String customers = '/more/customers';
  static const String customerDetail = '/more/customers/detail';

  // Fraud & Risk
  static const String fraud = '/more/fraud';
}
