import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/features/auth/data/datasources/auth_remote_ds.dart';
import 'package:pos/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:pos/features/auth/domain/usecases/get_current_user.dart';
import 'package:pos/features/auth/domain/usecases/observe_auth_state.dart';
import 'package:pos/features/auth/domain/usecases/send_sign_up_otp.dart';
import 'package:pos/features/auth/domain/usecases/sign_in.dart';
import 'package:pos/features/auth/domain/usecases/sign_out.dart';
import 'package:pos/features/auth/domain/usecases/sign_up.dart';
import 'package:pos/features/auth/domain/usecases/verify_sign_up_otp.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  // External
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

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
  sl.registerLazySingleton(() => SendSignUpOtp(sl<AuthRepository>()));
  sl.registerLazySingleton(() => VerifySignUpOtp(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignOut(sl<AuthRepository>()));

  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      getCurrentUser: sl(),
      observeAuthState: sl(),
      signIn: sl(),
      sendSignUpOtp: sl(),
      verifySignUpOtp: sl(),
      signOut: sl(),
    ),
  );
}
