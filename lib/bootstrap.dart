import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/app_boostrap.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';

Future<Widget> bootstrap() async {
  final startTime = DateTime.now();
  debugPrint('🚀 Bootstrap started');

  try {
    debugPrint('📁 Loading .env file...');
    final envStart = DateTime.now();
    await dotenv
        .load(fileName: ".env")
        .timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint('⚠️ .env load timeout - using system environment');
            return;
          },
        );
    debugPrint(
      '✅ .env loaded (${DateTime.now().difference(envStart).inMilliseconds}ms)',
    );
  } catch (e) {
    debugPrint('⚠️ .env load failed: $e - continuing with system environment');
  }

  try {
    debugPrint('🔐 Initializing Supabase...');
    final supabaseStart = DateTime.now();
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    ).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('⚠️ Supabase init timeout - offline mode');
        throw Exception('Supabase initialization timeout');
      },
    );
    debugPrint(
      '✅ Supabase initialized (${DateTime.now().difference(supabaseStart).inMilliseconds}ms)',
    );
  } catch (e) {
    debugPrint('⚠️ Supabase init failed: $e - app will run in offline mode');
  }

  try {
    debugPrint('💉 Initializing DI...');
    final diStart = DateTime.now();
    await initDI().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('⚠️ DI init timeout - critical failure');
        throw Exception('Dependency injection initialization timeout');
      },
    );
    debugPrint(
      '✅ DI initialized (${DateTime.now().difference(diStart).inMilliseconds}ms)',
    );
  } catch (e) {
    debugPrint('❌ DI init failed: $e');
    rethrow;
  }

  final totalTime = DateTime.now().difference(startTime).inMilliseconds;
  debugPrint('🎉 Bootstrap completed in ${totalTime}ms');

  debugPrint('👤 Creating AuthBloc and triggering initialization...');
  final authBloc = sl<AuthBloc>();
  authBloc.add(AuthStarted());

  await authBloc.stream
      .firstWhere(
        (state) => state is! AuthUnknown,
        orElse: () => authBloc.state,
      )
      .timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⚠️ AuthBloc initialization timeout - continuing anyway');
          return authBloc.state;
        },
      );

  debugPrint('✅ AuthBloc ready with state: ${authBloc.state.runtimeType}');

  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: authBloc),
      BlocProvider<BranchCubit>(create: (_) => sl<BranchCubit>()),
    ],
    child: const AppBoostrap(),
  );
}
