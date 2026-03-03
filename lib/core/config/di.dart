import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/business_templates_dao.dart';
import 'package:pos/core/database/daos/businesses_dao.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_service.dart';
import 'package:pos/features/auth/data/datasources/auth_remote_ds.dart';
import 'package:pos/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:pos/features/auth/domain/usecases/check_email_exists.dart';
import 'package:pos/features/auth/domain/usecases/get_current_user.dart';
import 'package:pos/features/auth/domain/usecases/observe_auth_state.dart';
import 'package:pos/features/auth/domain/usecases/send_sign_up_otp.dart';
import 'package:pos/features/auth/domain/usecases/sign_in.dart';
import 'package:pos/features/auth/domain/usecases/sign_out.dart';
import 'package:pos/features/auth/domain/usecases/sign_up.dart';
import 'package:pos/features/auth/domain/usecases/verify_sign_up_otp.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/business/data/datasources/business_remote_ds.dart';
import 'package:pos/features/business/data/repositories/business_repository_impl.dart';
import 'package:pos/features/business/domain/repositories/business_repository.dart';
import 'package:pos/features/business/presentation/bloc/business_bloc.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  // ─────────────────────────────────────────────
  // Core / External
  // ─────────────────────────────────────────────
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Database (Drift - local storage)
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // DAOs
  sl.registerLazySingleton<BusinessTemplatesDao>(
    () => BusinessTemplatesDao(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<BusinessesDao>(
    () => BusinessesDao(sl<AppDatabase>()),
  );

  // Connectivity
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());

  // ─────────────────────────────────────────────
  // Auth Feature
  // ─────────────────────────────────────────────

  // Data sources
  sl.registerLazySingleton(() => AuthRemoteDs(sl<SupabaseClient>()));

  // Repos
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDs>()),
  );

  // Usecases
  sl.registerLazySingleton(() => GetCurrentUser(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ObserveAuthState(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignIn(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignUp(sl<AuthRepository>()));
  sl.registerLazySingleton(() => CheckEmailExists(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SendSignUpOtp(sl<AuthRepository>()));
  sl.registerLazySingleton(() => VerifySignUpOtp(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignOut(sl<AuthRepository>()));

  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      getCurrentUser: sl(),
      observeAuthState: sl(),
      signIn: sl(),
      checkEmailExists: sl(),
      sendSignUpOtp: sl(),
      verifySignUpOtp: sl(),
      signOut: sl(),
    ),
  );

  // ─────────────────────────────────────────────
  // Business Feature
  // ─────────────────────────────────────────────

  // Data sources
  sl.registerLazySingleton(() => BusinessRemoteDs(sl<SupabaseClient>()));

  // Repos (offline-first)
  sl.registerLazySingleton<BusinessRepository>(
    () => BusinessRepositoryImpl(
      remote: sl<BusinessRemoteDs>(),
      businessesDao: sl<BusinessesDao>(),
      templatesDao: sl<BusinessTemplatesDao>(),
      connectivity: sl<ConnectivityService>(),
    ),
  );

  // Bloc
  sl.registerFactory(
    () => BusinessBloc(
      businessRepository: sl<BusinessRepository>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  // ─────────────────────────────────────────────
  // Sync Service
  // ─────────────────────────────────────────────
  sl.registerLazySingleton<SyncService>(
    () => SyncService(
      businessesDao: sl<BusinessesDao>(),
      businessRemoteDs: sl<BusinessRemoteDs>(),
      connectivityService: sl<ConnectivityService>(),
    )..init(),
  );
}
