import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nobodywho/nobodywho.dart' as nobodywho;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/env/app_env.dart';
import 'package:pos/app_boostrap.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';

Future<Widget> bootstrap() async {
  AppEnv.assertValid();

  // Initialize Supabase and DI in parallel — they're independent of each other.
  // NobodyWho is fire-and-forget; it must not block the critical path.
  await Future.wait([
    _initSupabase(),
    initDI(),
  ]);

  // Non-critical: AI rule parser. Never block startup on this.
  unawaited(_initNobodyWho());

  final authBloc = sl<AuthBloc>();
  authBloc.add(AuthStarted());

  // Wait at most 2 s for the auth state to settle. If it doesn't settle
  // in time (e.g. no network), the router handles the Unknown state gracefully.
  await authBloc.stream
      .firstWhere(
        (state) => state is! AuthUnknown,
        orElse: () => authBloc.state,
      )
      .timeout(const Duration(seconds: 2), onTimeout: () => authBloc.state);

  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: authBloc),
      BlocProvider<BranchCubit>(create: (_) => sl<BranchCubit>()),
    ],
    child: const AppBoostrap(),
  );
}

Future<void> _initSupabase() async {
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  ).timeout(
    const Duration(seconds: 10),
    onTimeout: () => throw Exception(
      'Connection timed out during startup. Please check your internet and try again.',
    ),
  );
}

Future<void> _initNobodyWho() async {
  try {
    await nobodywho.NobodyWho.init();
  } catch (e) {
    debugPrint('NobodyWho init failed: $e — rule-based parser will be used');
  }
}

// Intentionally not awaited — fire-and-forget helper for clarity.
void unawaited(Future<void> future) {
  future.ignore();
}
