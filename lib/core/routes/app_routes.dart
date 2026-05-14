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

  // Expenses
  static const String expenses = '/more/expenses';

  // Settings
  static const String settings = '/settings';
  static const String receiptSettings = '/settings/receipt';

  // Notifications
  static const String notifications = '/notifications';
}
