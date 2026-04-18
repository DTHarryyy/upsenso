import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/database/daos/business_templates_dao.dart';
import 'package:pos/core/database/daos/businesses_dao.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/theme/theme_controller.dart';
import 'package:pos/core/services/cart_service.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_service.dart';
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
import 'package:pos/features/reports/data/reports_repository.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';
import 'package:pos/features/inventory/data/inventory_repository.dart';

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

  // OAuth redirect URL used by Google/Facebook sign-in callbacks.
  final oauthRedirectUrl =
      dotenv.env['SUPABASE_OAUTH_REDIRECT_URL'] ?? 'posauth://login-callback/';

  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

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
  sl.registerLazySingleton<CategoriesDao>(() => CategoriesDao(sl<AppDatabase>()));
  sl.registerLazySingleton<ProductsDao>(() => ProductsDao(sl<AppDatabase>()));
  sl.registerLazySingleton<ProductVariantsDao>(
    () => ProductVariantsDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<TransactionsDao>(() => TransactionsDao(sl<AppDatabase>()));
  sl.registerLazySingleton<InventoryLevelsDao>(
    () => InventoryLevelsDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<StockLedgerDao>(
    () => StockLedgerDao(sl<AppDatabase>()),
  );

  sl.registerLazySingleton<CartService>(() => CartService());
  sl.registerLazySingleton<ImageService>(() => ImageService());
  sl.registerLazySingleton<ResolveBarcodeUseCase>(
    () => ResolveBarcodeUseCase(
      variantsDao: sl<ProductVariantsDao>(),
      productsDao: sl<ProductsDao>(),
    ),
  );
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());

  sl.registerFactory(() => BranchCubit());

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

  sl.registerFactory(
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
  sl.registerLazySingleton(() => ProductsRemoteDs(sl<SupabaseClient>()));
  sl.registerLazySingleton(() => TransactionsRemoteDs(sl<SupabaseClient>()));

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

  sl.registerLazySingleton<SyncService>(
    () => SyncService(
      authContextDao: sl<AuthContextDao>(),
      businessesDao: sl<BusinessesDao>(),
      categoriesDao: sl<CategoriesDao>(),
      productsDao: sl<ProductsDao>(),
      productVariantsDao: sl<ProductVariantsDao>(),
      transactionsDao: sl<TransactionsDao>(),
      businessRemoteDs: sl<BusinessRemoteDs>(),
      productsRemoteDs: sl<ProductsRemoteDs>(),
      transactionsRemoteDs: sl<TransactionsRemoteDs>(),
      connectivityService: sl<ConnectivityService>(),
    )..init(),
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
      transactionsDao: sl<TransactionsDao>(),
      db: sl<AppDatabase>(),
    ),
  );
  sl.registerLazySingleton<AiPipeline>(
    () => AiPipeline(
      llmService: sl<LlmService>(),
      toolService: sl<AiToolService>(),
    ),
  );

  sl.registerLazySingleton<InventoryRepository>(
    () => InventoryRepository(
      productsDao: sl<ProductsDao>(),
      variantsDao: sl<ProductVariantsDao>(),
      branchesDao: sl<BranchesDao>(),
      levelsDao: sl<InventoryLevelsDao>(),
      ledgerDao: sl<StockLedgerDao>(),
    ),
  );

  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepository(
      txnDao: sl<TransactionsDao>(),
      variantsDao: sl<ProductVariantsDao>(),
      productsDao: sl<ProductsDao>(),
      categoriesDao: sl<CategoriesDao>(),
      branchesDao: sl<BranchesDao>(),
    ),
  );

  sl.registerLazySingleton<ReportsRepository>(
    () => ReportsRepository(
      txnDao: sl<TransactionsDao>(),
      variantsDao: sl<ProductVariantsDao>(),
      productsDao: sl<ProductsDao>(),
      categoriesDao: sl<CategoriesDao>(),
      branchesDao: sl<BranchesDao>(),
    ),
  );

  // Ensures businessId is available immediately on startup
  final authRepo = sl<AuthRepository>() as AuthRepositoryImpl;
  await authRepo.initializeCachedUser();
}
