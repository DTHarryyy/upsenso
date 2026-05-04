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
/// and emits one of several events depending on token state:
///
///   • [AuthChangeEvent.initialSession] — session found (access token may
///     still be valid or may be in the middle of a background refresh).
///   • [AuthChangeEvent.tokenRefreshed]  — fired *after* a silent token
///     refresh completes. If the stored access token was expired this is the
///     event that actually makes [currentUser] non-null.
///   • [AuthChangeEvent.signedIn]        — fired after a full sign-in.
///   • [AuthChangeEvent.signedOut]       — no valid session exists.
///
/// Without waiting for [tokenRefreshed], the startup can race ahead while
/// the token-refresh network call is still in flight. In that window
/// [currentUser()] returns null → [initializeCachedUser()] stores nothing
/// → [AuthStarted] emits [AuthUnauthenticated] → user sees the sign-in
/// screen and must log in again even though a valid session exists.
Future<void> _waitForSessionRecovery() async {
  final auth = Supabase.instance.client.auth;
  try {
    // ── Phase 1: wait for any terminal session event ─────────────────────
    await auth.onAuthStateChange
        .firstWhere(
          (s) =>
              s.event == AuthChangeEvent.initialSession ||
              s.event == AuthChangeEvent.signedIn ||
              s.event == AuthChangeEvent.signedOut ||
              s.event == AuthChangeEvent.tokenRefreshed,
        )
        .timeout(const Duration(milliseconds: 3000));

    // ── Phase 2: if the access token was expired, the first event may be
    // an initialSession with no user yet (refresh still in flight).
    // Wait for the tokenRefreshed/signedIn confirmation before proceeding.
    if (auth.currentUser == null) {
      await auth.onAuthStateChange
          .firstWhere(
            (s) =>
                s.event == AuthChangeEvent.tokenRefreshed ||
                s.event == AuthChangeEvent.signedIn ||
                s.event == AuthChangeEvent.signedOut,
          )
          .timeout(const Duration(milliseconds: 4000));
    }
  } catch (_) {
    // Timeout is acceptable — either no session in localStorage or the
    // network is too slow to refresh the token. The auth bloc will handle
    // the unauthenticated state correctly.
  }
}

Future<void> _initNobodyWho() async {
  try {
    await nobodywho.NobodyWho.init();
  } catch (e) {
    debugPrint('NobodyWho init failed: $e — rule-based parser will be used');
  }
}
