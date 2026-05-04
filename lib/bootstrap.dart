import 'package:flutter/foundation.dart';
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

  // Step 1: Supabase must finish first — it recovers the session from
  // localStorage on web. DI must come after so initializeCachedUser()
  // can read the live Supabase session that was just restored.
  await _initSupabase();

  // Step 2: On web, wait for the auth session to be recovered from
  // localStorage before initializing DI. Without this, currentUser()
  // returns null even though a valid session exists in localStorage.
  if (kIsWeb) {
    await _waitForSessionRecovery();
  }

  // Step 3: Initialize DI (includes initializeCachedUser which reads
  // the now-available Supabase session).
  await initDI();

  // Non-critical: AI rule parser. Never block startup on this.
  _initNobodyWho().ignore();

  final authBloc = sl<AuthBloc>();
  authBloc.add(AuthStarted());

  // Wait at most 2s for auth state to settle. The router handles unknown
  // state gracefully so a timeout is safe.
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
      autoRefreshToken: true,
    ),
  ).timeout(
    const Duration(seconds: 10),
    onTimeout: () => throw Exception(
      'Connection timed out during startup. Please check your internet and try again.',
    ),
  );
}

/// On web, Supabase recovers the session from localStorage asynchronously
/// by emitting an [AuthChangeEvent.initialSession] event. We wait for that
/// event so [currentUser()] is populated before DI runs.
Future<void> _waitForSessionRecovery() async {
  try {
    await Supabase.instance.client.auth.onAuthStateChange
        .firstWhere(
          (state) =>
              state.event == AuthChangeEvent.initialSession ||
              state.event == AuthChangeEvent.signedIn ||
              state.event == AuthChangeEvent.signedOut,
        )
        .timeout(const Duration(seconds: 3));
  } catch (_) {
    // Timeout is fine — no session in localStorage, user is logged out.
  }
}

Future<void> _initNobodyWho() async {
  try {
    await nobodywho.NobodyWho.init();
  } catch (e) {
    debugPrint('NobodyWho init failed: $e — rule-based parser will be used');
  }
}
