import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nobodywho/nobodywho.dart' as nobodywho;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/env/app_env.dart';
import 'package:pos/app_bootstrap.dart';
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

  // Wait at most 4s for auth state to settle. The router handles unknown
  // state gracefully so a timeout is safe. 4 s (up from 2 s) gives the
  // slow-path context fetch in _onStarted enough room to complete before
  // the app widget tree renders, avoiding a brief flash of the sign-in page.
  await authBloc.stream
      .firstWhere(
        (state) => state is! AuthUnknown,
        orElse: () => authBloc.state,
      )
      .timeout(const Duration(seconds: 4), onTimeout: () => authBloc.state);

  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: authBloc),
      BlocProvider<BranchCubit>(create: (_) => sl<BranchCubit>()),
    ],
    child: const AppBootstrap(),
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

/// On web, Supabase recovers the session from localStorage.
///
/// The tricky part: [AuthChangeEvent.initialSession] fires **synchronously
/// inside** [Supabase.initialize], so by the time we subscribe to
/// [onAuthStateChange] it has already been emitted and is gone (broadcast
/// streams don't replay). A two-phase listen therefore routinely misses it
/// and wastes 3 s waiting for an event that never comes.
///
/// Strategy:
///   1. Fast path — if [currentUser] is already set after [initialize]
///      returns (valid non-expired token), return immediately.
///   2. Slow path — token is expired and a network refresh is in flight.
///      Listen for the decisive event with a single generous timeout so
///      slow networks don't cause a false sign-out.
Future<void> _waitForSessionRecovery() async {
  final auth = Supabase.instance.client.auth;

  // Fast path: session was fully recovered synchronously during initialize().
  if (auth.currentUser != null) return;

  // Slow path: the stored access token is expired and Supabase is refreshing
  // it via a background network call. Wait for the result.
  try {
    await auth.onAuthStateChange
        .firstWhere(
          (s) =>
              s.event == AuthChangeEvent.tokenRefreshed ||
              s.event == AuthChangeEvent.signedIn ||
              s.event == AuthChangeEvent.signedOut ||
              s.event == AuthChangeEvent.initialSession,
        )
        .timeout(const Duration(seconds: 8));
  } catch (_) {
    // Timed out — network too slow or truly no session. The auth bloc will
    // handle the unauthenticated state correctly.
  }
}

Future<void> _initNobodyWho() async {
  try {
    await nobodywho.NobodyWho.init();
  } catch (e) {
    debugPrint('NobodyWho init failed: $e — rule-based parser will be used');
  }
}
