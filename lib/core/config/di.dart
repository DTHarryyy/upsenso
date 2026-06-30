import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/core/env/app_env.dart';
import 'package:pos/core/security/secure_storage_service.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/database/daos/business_templates_dao.dart';
import 'package:pos/core/database/daos/businesses_dao.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/database/daos/draft_sales_dao.dart';
import 'package:pos/core/theme/theme_controller.dart';
import 'package:pos/core/services/cart_service.dart';
import 'package:pos/core/services/checkout_service.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/features/auth/data/datasources/auth_remote_ds.dart';
import 'package:pos/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:pos/features/auth/domain/usecases/check_email_exists.dart';
import 'package:pos/features/auth/domain/usecases/get_current_user.dart';
import 'package:pos/features/auth/domain/usecases/get_user_business_context.dart';
import 'package:pos/features/auth/domain/usecases/observe_auth_state.dart';
import 'package:pos/features/auth/domain/usecases/send_sign_up_otp.dart';
import 'package:pos/features/auth/domain/usecases/sign_in.dart';
import 'package:pos/features/auth/domain/usecases/sign_in_with_facebook.dart';
import 'package:pos/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:pos/features/auth/domain/usecases/sign_out.dart';
import 'package:pos/features/auth/domain/usecases/sign_up.dart';
import 'package:pos/features/auth/domain/usecases/verify_sign_up_otp.dart';
import 'package:pos/features/auth/domain/usecases/send_password_reset_otp.dart';
import 'package:pos/features/auth/domain/usecases/verify_password_reset_otp.dart';
import 'package:pos/features/auth/domain/usecases/reset_password.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/business/data/datasources/business_remote_ds.dart';
import 'package:pos/features/business/data/repositories/business_repository_impl.dart';
import 'package:pos/features/business/domain/repositories/business_repository.dart';
import 'package:pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:pos/core/services/image_service.dart';
import 'package:pos/features/products/data/datasources/products_remote_ds.dart';
import 'package:pos/features/pos/data/datasources/transactions_remote_ds.dart';
import 'package:pos/features/pos/domain/usecases/resolve_barcode_use_case.dart';
import 'package:pos/features/ai_assistant/services/llm_engine.dart';
import 'package:pos/features/ai_assistant/services/llm_service.dart';
import 'package:pos/features/ai_assistant/services/model_manager.dart';
import 'package:pos/features/ai_assistant/services/model_download_service.dart';
import 'package:pos/features/ai_assistant/services/ai_tool_service.dart';
import 'package:pos/features/ai_assistant/services/ai_pipeline.dart';
import 'package:pos/features/dashboard/data/dashboard_repository.dart';
import 'package:pos/features/expenses/data/expenses_repository.dart';
import 'package:pos/features/inventory/data/inventory_repository.dart';
import 'package:pos/features/reports/data/reports_repository.dart';
import 'package:pos/features/sales/data/sales_repository.dart';
import 'package:pos/features/drafts/data/draft_sales_repository.dart';
import 'package:pos/features/drafts/domain/repositories/i_draft_sales_repository.dart';
import 'package:pos/core/database/daos/expenses_dao.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/receipt_settings_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';
import 'package:pos/core/database/daos/purchase_order_lines_dao.dart';
import 'package:pos/core/database/daos/purchase_orders_dao.dart';
import 'package:pos/core/database/daos/suppliers_dao.dart';
import 'package:pos/core/services/recipe_consumption_service.dart';
import 'package:pos/core/services/stock_movement_service.dart';
import 'package:pos/features/procurement/data/datasources/procurement_remote_ds.dart';
import 'package:pos/features/procurement/data/procurement_repository.dart';
import 'package:pos/features/procurement/domain/repositories/i_procurement_repository.dart';
import 'package:pos/core/database/daos/recipe_lines_dao.dart';
import 'package:pos/core/database/daos/sync_state_dao.dart';
import 'package:pos/features/recipes/data/ingredients_repository.dart';
import 'package:pos/features/recipes/domain/repositories/i_ingredients_repository.dart';
import 'package:pos/core/database/daos/invoice_sequences_dao.dart';
import 'package:pos/core/services/invoice_number_service.dart';
import 'package:pos/core/database/daos/po_number_sequences_dao.dart';
import 'package:pos/core/database/daos/procurement_settings_dao.dart';
import 'package:pos/core/database/daos/goods_receipts_dao.dart';
import 'package:pos/core/database/daos/goods_receipt_items_dao.dart';
import 'package:pos/core/services/po_number_service.dart';
import 'package:pos/core/database/daos/refunds_dao.dart';
import 'package:pos/core/database/daos/refund_settings_dao.dart';
import 'package:pos/core/services/refund_service.dart';
import 'package:pos/features/pos/data/datasources/refunds_remote_ds.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/features/audit_logs/data/datasources/audit_log_remote_ds.dart';
import 'package:pos/features/audit_logs/data/repositories/audit_log_repository_impl.dart';
import 'package:pos/features/audit_logs/domain/repositories/i_audit_log_repository.dart';
import 'package:pos/features/expenses/data/datasources/expenses_remote_ds.dart';
import 'package:pos/core/database/daos/employees_dao.dart';
import 'package:pos/features/employees/data/datasources/employees_remote_ds.dart';
import 'package:pos/features/employees/data/employees_repository_impl.dart';
import 'package:pos/features/employees/domain/repositories/i_employees_repository.dart';
import 'package:pos/features/employees/domain/services/employee_validation_service.dart';
import 'package:pos/features/dashboard/domain/repositories/i_dashboard_repository.dart';
import 'package:pos/features/expenses/domain/repositories/i_expenses_repository.dart';
import 'package:pos/features/inventory/domain/repositories/i_inventory_repository.dart';
import 'package:pos/features/products/data/products_repository.dart';
import 'package:pos/features/products/domain/repositories/i_products_repository.dart';
import 'package:pos/features/reports/domain/repositories/i_reports_repository.dart';
import 'package:pos/features/sales/domain/repositories/i_sales_repository.dart';
import 'package:pos/features/settings/data/datasources/receipt_settings_remote_ds.dart';
import 'package:pos/features/settings/data/receipt_settings_repository.dart';
import 'package:pos/features/settings/data/refund_settings_repository.dart';
import 'package:pos/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:pos/features/settings/services/receipt_printer_service.dart';
import 'package:pos/features/notifications/data/notifications_repository.dart';
import 'package:pos/features/notifications/domain/repositories/i_notifications_repository.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/permissions/data_scoping_layer.dart';
import 'package:pos/core/permissions/data/permission_remote_ds.dart';
import 'package:pos/core/database/daos/employee_permissions_dao.dart';
import 'package:pos/core/database/daos/business_modules_dao.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // SharedPreferences for local caching with timeout
  final prefs = await SharedPreferences.getInstance().timeout(
    const Duration(seconds: 5),
    onTimeout: () {
      debugPrint('SharedPreferences timeout - using fallback');
      throw Exception('SharedPreferences initialization timeout');
    },
  );
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<ThemeController>(
    () => ThemeController(sl<SharedPreferences>()),
  );
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());

  // On web, OAuth must redirect back to an HTTP URL. On mobile, use the custom scheme.
  final oauthRedirectUrl = kIsWeb
      ? AppEnv.webOauthRedirectUrl
      : AppEnv.oauthRedirectUrl;

  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // Authoritative in-memory active-tenant holder. Set on authenticate, cleared
  // on logout/account switch. Tenant-sensitive services resolve businessId from
  // here instead of a tenant-agnostic "first cached row" lookup.
  sl.registerLazySingleton<ActiveBusinessContext>(() => ActiveBusinessContext());

  sl.registerLazySingleton<AuthContextDao>(
    () => AuthContextDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<BusinessTemplatesDao>(
    () => BusinessTemplatesDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<BusinessesDao>(
    () => BusinessesDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<BranchesDao>(() => BranchesDao(sl<AppDatabase>()));
  sl.registerLazySingleton<CategoriesDao>(
    () => CategoriesDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<ProductsDao>(() => ProductsDao(sl<AppDatabase>()));
  sl.registerLazySingleton<ProductVariantsDao>(
    () => ProductVariantsDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<TransactionsDao>(
    () => TransactionsDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<InvoiceSequencesDao>(
    () => InvoiceSequencesDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<InvoiceNumberService>(
    () => InvoiceNumberService(sl<SupabaseClient>(), sl<InvoiceSequencesDao>()),
  );
  sl.registerLazySingleton<PoNumberSequencesDao>(
    () => PoNumberSequencesDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<PoNumberService>(
    () => PoNumberService(sl<SupabaseClient>(), sl<PoNumberSequencesDao>()),
  );
  sl.registerLazySingleton<ProcurementSettingsDao>(
    () => ProcurementSettingsDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<GoodsReceiptsDao>(
    () => GoodsReceiptsDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<GoodsReceiptItemsDao>(
    () => GoodsReceiptItemsDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<RefundsDao>(() => RefundsDao(sl<AppDatabase>()));
  sl.registerLazySingleton<DraftSalesDao>(
    () => DraftSalesDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<InventoryLevelsDao>(
    () => InventoryLevelsDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<StockLedgerDao>(
    () => StockLedgerDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<SyncStateDao>(
    () => SyncStateDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<ExpensesDao>(() => ExpensesDao(sl<AppDatabase>()));
  sl.registerLazySingleton<EmployeesDao>(() => EmployeesDao(sl<AppDatabase>()));
  sl.registerLazySingleton<IExpensesRepository>(
    () => ExpensesRepository(expensesDao: sl<ExpensesDao>()),
  );
  sl.registerLazySingleton<EmployeesRemoteDs>(
    () => EmployeesRemoteDs(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<EmployeeValidationService>(
    () => EmployeeValidationService(sl<EmployeesDao>()),
  );
  sl.registerLazySingleton<IEmployeesRepository>(
    () => EmployeesRepositoryImpl(
      dao: sl<EmployeesDao>(),
      remoteDs: sl<EmployeesRemoteDs>(),
      permissionsDao: sl<EmployeePermissionsDao>(),
      permissionRemoteDs: sl<PermissionRemoteDs>(),
    ),
  );
  sl.registerLazySingleton<ReceiptSettingsDao>(
    () => ReceiptSettingsDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<ReceiptSettingsRemoteDs>(
    () => ReceiptSettingsRemoteDs(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<ReceiptSettingsRepository>(
    () => ReceiptSettingsRepository(
      dao: sl<ReceiptSettingsDao>(),
      remote: sl<ReceiptSettingsRemoteDs>(),
      connectivity: sl<ConnectivityService>(),
      businessRemote: sl<BusinessRemoteDs>(),
    ),
  );

  sl.registerLazySingleton<CartService>(() => CartService());
  sl.registerLazySingleton<ImageService>(
    () => ImageService(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<ResolveBarcodeUseCase>(
    () => ResolveBarcodeUseCase(repository: sl<IProductsRepository>()),
  );
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());

  sl.registerLazySingleton<BranchCubit>(() => BranchCubit());

  sl.registerLazySingleton(() => AuthRemoteDs(sl<SupabaseClient>()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      sl<AuthRemoteDs>(),
      sl<AuthContextDao>(),
      oauthRedirectUrl,
    ),
  );

  sl.registerLazySingleton(() => GetCurrentUser(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetUserBusinessContext(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ObserveAuthState(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignIn(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignInWithGoogle(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignInWithFacebook(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignUp(sl<AuthRepository>()));
  sl.registerLazySingleton(() => CheckEmailExists(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SendSignUpOtp(sl<AuthRepository>()));
  sl.registerLazySingleton(() => VerifySignUpOtp(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SendPasswordResetOtp(sl<AuthRepository>()));
  sl.registerLazySingleton(() => VerifyPasswordResetOtp(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ResetPassword(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignOut(sl<AuthRepository>()));

  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      getCurrentUser: sl(),
      getUserBusinessContext: sl(),
      observeAuthState: sl(),
      signIn: sl(),
      signInWithGoogle: sl(),
      signInWithFacebook: sl(),
      checkEmailExists: sl(),
      sendSignUpOtp: sl(),
      verifySignUpOtp: sl(),
      sendPasswordResetOtp: sl(),
      verifyPasswordResetOtp: sl(),
      resetPassword: sl(),
      signOut: sl(),
      connectivityService: sl(),
      syncService: sl(),
    ),
  );

  sl.registerLazySingleton(() => BusinessRemoteDs(sl<SupabaseClient>()));
  sl.registerLazySingleton(() => ExpensesRemoteDs(sl<SupabaseClient>()));
  sl.registerLazySingleton(() => ProductsRemoteDs(sl<SupabaseClient>()));
  sl.registerLazySingleton(() => TransactionsRemoteDs(sl<SupabaseClient>()));
  sl.registerLazySingleton(() => RefundsRemoteDs(sl<SupabaseClient>()));
  sl.registerLazySingleton<RefundSettingsDao>(
    () => RefundSettingsDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<RefundSettingsRepository>(
    () => RefundSettingsRepository(
      dao: sl<RefundSettingsDao>(),
      remote: sl<RefundsRemoteDs>(),
      connectivity: sl<ConnectivityService>(),
    ),
  );

  sl.registerLazySingleton<BusinessRepository>(
    () => BusinessRepositoryImpl(
      remote: sl<BusinessRemoteDs>(),
      businessesDao: sl<BusinessesDao>(),
      templatesDao: sl<BusinessTemplatesDao>(),
      branchesDao: sl<BranchesDao>(),
      categoriesDao: sl<CategoriesDao>(),
      connectivity: sl<ConnectivityService>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  sl.registerFactory(
    () => BusinessBloc(
      businessRepository: sl<BusinessRepository>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  // SyncService is constructed without calling init() here.
  // init() is called from MainNavigationPage after the first frame renders,
  // so that background sync never blocks the startup critical path.
  sl.registerLazySingleton<SyncService>(
    () => SyncService(
      authContextDao: sl<AuthContextDao>(),
      activeBusinessContext: sl<ActiveBusinessContext>(),
      branchesDao: sl<BranchesDao>(),
      businessesDao: sl<BusinessesDao>(),
      categoriesDao: sl<CategoriesDao>(),
      expensesDao: sl<ExpensesDao>(),
      inventoryLevelsDao: sl<InventoryLevelsDao>(),
      productsDao: sl<ProductsDao>(),
      productVariantsDao: sl<ProductVariantsDao>(),
      stockLedgerDao: sl<StockLedgerDao>(),
      transactionsDao: sl<TransactionsDao>(),
      draftSalesDao: sl<DraftSalesDao>(),
      businessRemoteDs: sl<BusinessRemoteDs>(),
      expensesRemoteDs: sl<ExpensesRemoteDs>(),
      productsRemoteDs: sl<ProductsRemoteDs>(),
      transactionsRemoteDs: sl<TransactionsRemoteDs>(),
      connectivityService: sl<ConnectivityService>(),
      receiptSettingsRepository: sl<ReceiptSettingsRepository>(),
      auditLogsDao: sl<AuditLogsDao>(),
      auditLogRemoteDs: sl<AuditLogRemoteDs>(),
      employeesDao: sl<EmployeesDao>(),
      employeesRemoteDs: sl<EmployeesRemoteDs>(),
      suppliersDao: sl<SuppliersDao>(),
      purchaseOrdersDao: sl<PurchaseOrdersDao>(),
      purchaseOrderLinesDao: sl<PurchaseOrderLinesDao>(),
      goodsReceiptsDao: sl<GoodsReceiptsDao>(),
      goodsReceiptItemsDao: sl<GoodsReceiptItemsDao>(),
      procurementRemoteDs: sl<ProcurementRemoteDs>(),
      recipeLinesDao: sl<RecipeLinesDao>(),
      syncStateDao: sl<SyncStateDao>(),
      imageService: sl<ImageService>(),
      refundsDao: sl<RefundsDao>(),
      refundsRemoteDs: sl<RefundsRemoteDs>(),
      refundSettingsRepository: sl<RefundSettingsRepository>(),
    ),
  );

  // ── AI Assistant services ──────────────────────────────────────────────
  sl.registerLazySingleton<LlmEngine>(() => LlmEngine());
  sl.registerLazySingleton<ModelManager>(() => ModelManager());
  sl.registerLazySingleton<ModelDownloadService>(
    () => ModelDownloadService(modelManager: sl<ModelManager>()),
  );
  sl.registerLazySingleton<LlmService>(
    () => LlmService(engine: sl<LlmEngine>(), modelManager: sl<ModelManager>()),
  );
  sl.registerLazySingleton<AiToolService>(
    () => AiToolService(
      productsDao: sl<ProductsDao>(),
      variantsDao: sl<ProductVariantsDao>(),
      checkoutService: sl<CheckoutService>(),
      db: sl<AppDatabase>(),
    ),
  );
  sl.registerLazySingleton<AiPipeline>(
    () => AiPipeline(
      llmService: sl<LlmService>(),
      toolService: sl<AiToolService>(),
    ),
  );

  sl.registerLazySingleton<ReceiptPrinterService>(
    () => const ReceiptPrinterService(),
  );

  sl.registerLazySingleton<AuditLogsDao>(() => AuditLogsDao(sl<AppDatabase>()));
  sl.registerLazySingleton<AuditLogRemoteDs>(
    () => AuditLogRemoteDs(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<IAuditLogRepository>(
    () => AuditLogRepositoryImpl(
      dao: sl<AuditLogsDao>(),
      remoteDs: sl<AuditLogRemoteDs>(),
      connectivityService: sl<ConnectivityService>(),
    ),
  );
  sl.registerLazySingleton<AuditLogService>(
    () => AuditLogService(
      dao: sl<AuditLogsDao>(),
      authContextDao: sl<AuthContextDao>(),
      activeBusinessContext: sl<ActiveBusinessContext>(),
    ),
  );

  sl.registerLazySingleton<EmployeePermissionsDao>(
    () => EmployeePermissionsDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<BusinessModulesDao>(
    () => BusinessModulesDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<SuppliersDao>(
    () => SuppliersDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<PurchaseOrdersDao>(
    () => PurchaseOrdersDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<PurchaseOrderLinesDao>(
    () => PurchaseOrderLinesDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<RecipeLinesDao>(
    () => RecipeLinesDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<IIngredientsRepository>(
    () => IngredientsRepository(
      productsDao: sl<ProductsDao>(),
      variantsDao: sl<ProductVariantsDao>(),
      levelsDao: sl<InventoryLevelsDao>(),
      stockMovement: sl<StockMovementService>(),
      ledgerDao: sl<StockLedgerDao>(),
    ),
  );
  sl.registerLazySingleton<ProcurementRemoteDs>(
    () => ProcurementRemoteDs(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<IProcurementRepository>(
    () => ProcurementRepository(
      suppliersDao: sl<SuppliersDao>(),
      purchaseOrdersDao: sl<PurchaseOrdersDao>(),
      purchaseOrderLinesDao: sl<PurchaseOrderLinesDao>(),
      variantsDao: sl<ProductVariantsDao>(),
      levelsDao: sl<InventoryLevelsDao>(),
      stockMovement: sl<StockMovementService>(),
      poNumberService: sl<PoNumberService>(),
      settingsDao: sl<ProcurementSettingsDao>(),
      receiptsDao: sl<GoodsReceiptsDao>(),
      receiptItemsDao: sl<GoodsReceiptItemsDao>(),
      remoteDs: sl<ProcurementRemoteDs>(),
    ),
  );
  sl.registerLazySingleton<PermissionRemoteDs>(
    () => PermissionRemoteDs(sl<SupabaseClient>()),
  );

  sl.registerLazySingleton<PermissionService>(
    () => PermissionService(
      authContextDao: sl<AuthContextDao>(),
      activeBusinessContext: sl<ActiveBusinessContext>(),
      auditLogService: sl<AuditLogService>(),
      permissionsDao: sl<EmployeePermissionsDao>(),
      permissionRemoteDs: sl<PermissionRemoteDs>(),
      businessModulesDao: sl<BusinessModulesDao>(),
    ),
  );

  sl.registerLazySingleton<DataScopingLayer>(
    () => DataScopingLayer(permissionService: sl<PermissionService>()),
  );

  // settings_page.dart resolves this via sl()
  sl.registerFactory(() => SettingsCubit(sl<ReceiptSettingsRepository>()));

  sl.registerLazySingleton<StockMovementService>(
    () => StockMovementService(
      ledgerDao: sl<StockLedgerDao>(),
      levelsDao: sl<InventoryLevelsDao>(),
      variantsDao: sl<ProductVariantsDao>(),
    ),
  );

  sl.registerLazySingleton<RecipeConsumptionService>(
    () => RecipeConsumptionService(
      recipeLinesDao: sl<RecipeLinesDao>(),
      ledgerDao: sl<StockLedgerDao>(),
      variantsDao: sl<ProductVariantsDao>(),
      levelsDao: sl<InventoryLevelsDao>(),
    ),
  );

  sl.registerLazySingleton<IInventoryRepository>(
    () => InventoryRepository(
      productsDao: sl<ProductsDao>(),
      variantsDao: sl<ProductVariantsDao>(),
      branchesDao: sl<BranchesDao>(),
      levelsDao: sl<InventoryLevelsDao>(),
      stockMovement: sl<StockMovementService>(),
      recipeConsumption: sl<RecipeConsumptionService>(),
    ),
  );

  sl.registerLazySingleton<CheckoutService>(
    () => CheckoutService(
      db: sl<AppDatabase>(),
      transactionsDao: sl<TransactionsDao>(),
      inventoryRepository: sl<IInventoryRepository>(),
      invoiceNumberService: sl<InvoiceNumberService>(),
    ),
  );

  sl.registerLazySingleton<RefundService>(
    () => RefundService(
      db: sl<AppDatabase>(),
      transactionsDao: sl<TransactionsDao>(),
      refundsDao: sl<RefundsDao>(),
      inventoryRepository: sl<IInventoryRepository>(),
      permissionService: sl<PermissionService>(),
      auditLogService: sl<AuditLogService>(),
    ),
  );

  sl.registerLazySingleton<IProductsRepository>(
    () => ProductsRepository(
      productsDao: sl<ProductsDao>(),
      variantsDao: sl<ProductVariantsDao>(),
      categoriesDao: sl<CategoriesDao>(),
      levelsDao: sl<InventoryLevelsDao>(),
    ),
  );

  sl.registerLazySingleton<ISalesRepository>(
    () => SalesRepository(
      sl<TransactionsDao>(),
      sl<EmployeesDao>(),
      sl<AuthContextDao>(),
      sl<RefundsDao>(),
      sl<ProductVariantsDao>(),
      sl<ProductsDao>(),
    ),
  );

  sl.registerLazySingleton<IDraftSalesRepository>(
    () => DraftSalesRepository(sl<DraftSalesDao>()),
  );

  sl.registerLazySingleton<IDashboardRepository>(
    () => DashboardRepository(
      txnDao: sl<TransactionsDao>(),
      variantsDao: sl<ProductVariantsDao>(),
      productsDao: sl<ProductsDao>(),
      categoriesDao: sl<CategoriesDao>(),
      branchesDao: sl<BranchesDao>(),
      expensesDao: sl<ExpensesDao>(),
      prefs: sl<SharedPreferences>(),
    ),
  );

  sl.registerLazySingleton<IReportsRepository>(
    () => ReportsRepository(
      txnDao: sl<TransactionsDao>(),
      variantsDao: sl<ProductVariantsDao>(),
      productsDao: sl<ProductsDao>(),
      categoriesDao: sl<CategoriesDao>(),
      branchesDao: sl<BranchesDao>(),
      levelsDao: sl<InventoryLevelsDao>(),
      ledgerDao: sl<StockLedgerDao>(),
      refundsDao: sl<RefundsDao>(),
      expensesDao: sl<ExpensesDao>(),
      prefs: sl<SharedPreferences>(),
    ),
  );

  sl.registerLazySingleton<INotificationsRepository>(
    () => NotificationsRepository(sl<SupabaseClient>()),
  );

  // Ensures businessId is available immediately on startup
  final authRepo = sl<AuthRepository>() as AuthRepositoryImpl;
  await authRepo.initializeCachedUser();
}
