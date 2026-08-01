import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nobodywho/nobodywho.dart' as nobodywho;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/env/app_env.dart';
import 'package:pos/app_bootstrap.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/device/device_registration_service.dart';
import 'package:pos/core/permissions/entitlement_enforcement_service.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/billing/data/play_purchase_sync_service.dart';

Future<Widget> bootstrap() async {
  AppEnv.assertValid();

  // Step 1: Supabase must finish first — it recovers the session from
  // localStorage on web. DI must come after so initializeCachedUser()
  // can read the live Supabase session that was just restored.
  await _initSupabase();

  // Step 2: Wait for the auth session to be recovered / validated on all
  // platforms. On web this avoids the missed-broadcast-event race; on
  // mobile/desktop it catches a stale refresh token at startup so the app
  // never briefly shows the home screen before being kicked to sign-in.
  await _waitForSessionRecovery();

  // Step 3: Initialize DI (includes initializeCachedUser which reads
  // the now-available Supabase session).
  await initDI();

  // Step 3b: On web, wait for the WASM database to be ready before auth queries it.
  // This prevents a freeze when the auth bloc tries to query an uninitialized database.
  if (kIsWeb) {
    try {
      await sl<AppDatabase>().ensureReady().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Database initialization timeout'),
      );
    } catch (e, st) {
      debugPrint('Warning: Database ready check failed: $e\n$st');
      // On web, if database fails to initialize but we have a valid Supabase session,
      // continue anyway — the database will be retried on each operation.
      // Don't fail the entire startup sequence.
    }
  }

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

  // ── Permission service context sync ──────────────────────────────────────
  // Seed from the resolved auth state so permission checks, data scoping,
  // and dashboard scoping work immediately after startup (including offline
  // cold-start from Drift cache).
  final initialAuthState = authBloc.state;
  if (initialAuthState is AuthAuthenticated) {
    final u = initialAuthState.user;
    sl<PermissionService>().setContext(
      roleName: u.roleName,
      branchId: u.branchId,
      userId: u.id,
    );
    // Load cached permissions AND module state immediately (offline-safe, no
    // network). setContext nulls _moduleStates, and a null module map fails
    // CLOSED for every non-core feature — so skipping the module load left the
    // sidebar/More drawer empty offline until a relaunch.
    await sl<PermissionService>().loadPermissions(u.id);
    final bid = u.businessId;
    if (bid != null && bid.isNotEmpty) {
      await sl<PermissionService>().loadEnabledModules(bid);
    }
    // Plan entitlement must be cached before SyncService arms (it decides
    // whether the tenant may sync at all — M7.1 §7.1). Offline-safe.
    await sl<EntitlementService>().loadFromCache();
    // Over-cap locks must be in memory before the first frame, or a downgraded
    // tenant briefly sees every branch unlocked and then watches them snap shut.
    await sl<EntitlementEnforcementService>().load();
    // Sync from Supabase in the background — does not block startup.

    sl<PermissionService>().syncPermissions(u.id).ignore();
    if (bid != null && bid.isNotEmpty) {
      sl<PermissionService>().syncModules(bid).ignore();
    }
    // Refresh entitlement, then register this device against the plan cap
    // (§6.3) — a successful registration bumps registrationRevision and arms
    // SyncService. Chained so registration sees the freshest cloudEnabled.
    sl<EntitlementService>().syncEntitlement().then((_) {
      sl<DeviceRegistrationService>().ensureRegistered();
    }).ignore();
    _startPlayPurchaseSync();
  } else {
    // Fallback: try to load role from local Drift cache (offline start where
    // Supabase did not respond in time).
    await sl<PermissionService>().loadFromCache();
  }

  // Keep full context in sync for the entire app lifetime.
  authBloc.stream.listen((state) {
    if (state is AuthAuthenticated) {
      final u = state.user;
      sl<PermissionService>().setContext(
        roleName: u.roleName,
        branchId: u.branchId,
        userId: u.id,
      );
      // Reload permissions AND modules on every auth change (role/branch
      // switch, context refresh). setContext clears both maps; reloading
      // modules too keeps non-core features visible offline.
      sl<PermissionService>().loadPermissions(u.id).then((_) {
        sl<PermissionService>().syncPermissions(u.id).ignore();
      });
      final bid = u.businessId;
      if (bid != null && bid.isNotEmpty) {
        sl<PermissionService>().loadEnabledModules(bid).then((_) {
          sl<PermissionService>().syncModules(bid).ignore();
        });
      }
      sl<EntitlementService>().loadFromCache().then((_) {
        sl<EntitlementEnforcementService>().load();
        sl<EntitlementService>().syncEntitlement().then((_) {
          sl<DeviceRegistrationService>().ensureRegistered();
        });
      });
      _startPlayPurchaseSync();
    } else if (state is AuthUnauthenticated) {
      sl<PermissionService>().setContext(
        roleName: null,
        branchId: null,
        userId: null,
      );
      // Entitlement is tenant state — never carry it across accounts.
      sl<EntitlementService>().clear().ignore();
      sl<EntitlementEnforcementService>().clear().ignore();
    }
  });

  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: authBloc),
      BlocProvider<BranchCubit>(create: (_) => sl<BranchCubit>()),
    ],
    child: const AppBootstrap(),
  );
}

/// Attach the app-scoped Play purchase listener and sweep for anything Play
/// still considers owned.
///
/// The listener has to be live before the user reaches Billing: Play re-emits
/// interrupted deliveries on attach, and resolves pending payments whenever
/// they clear. The restore sweep is what makes a reinstall or a second device
/// recover its plan with no user action. Both are no-ops off Android.
void _startPlayPurchaseSync() {
  final sync = sl<PlayPurchaseSyncService>();
  if (!sync.isSupportedPlatform) return;
  sync.start();
  sync.restore().catchError((Object e, StackTrace st) {
    // A failed sweep is not fatal — the manual Restore button still works.
    debugPrint('[Bootstrap] Error in Play restore sweep: $e\n$st');
  });
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

/// Validates the locally-stored Supabase session on every platform before
/// the rest of the app boots.
///
/// **Web** — `initialSession` fires synchronously inside `initialize()` and
/// is gone by the time we subscribe (broadcast stream, no replay). We
/// therefore use a two-phase approach: fast path if `currentUser` is already
/// set, slow path waiting for the next decisive event.
///
/// **Mobile / Desktop** — same broadcast-stream caveat applies during a
/// background token refresh. Additionally, if the stored refresh token has
/// been revoked on the server ("refresh_token_not_found"), `autoRefreshToken`
/// will eventually log a WARNING and fire `signedOut`. By proactively calling
/// `refreshSession()` here we surface that failure *before* the UI renders,
/// preventing a brief authenticated flash followed by a forced sign-out.
///
/// Strategy:
///   1. Fast path — `currentUser != null` means a non-expired access token is
///      in memory. Only refresh if the token expires within 60 s; otherwise
///      trust it and skip the network call to avoid burning the refresh token
///      on web hot-restarts (`refresh_token_already_used`).
///   2. Slow path — access token is expired / missing. Wait for the in-flight
///      background refresh event. On timeout, force a refresh; sign out
///      locally if the refresh token is invalid.
Future<void> _waitForSessionRecovery() async {
  final auth = Supabase.instance.client.auth;

  // Fast path: a non-expired access token is already in memory.
  // Only proactively refresh when the token is about to expire (< 60 s left).
  // Refreshing unconditionally on every cold-start burns the refresh token and
  // triggers "refresh_token_already_used" on the very next load (web).
  if (auth.currentUser != null) {
    final session = auth.currentSession;
    final expiresAt = session?.expiresAt; // Unix seconds, nullable
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final secondsLeft = (expiresAt ?? 0) - nowSeconds;

    if (secondsLeft < 60) {
      // Token is expired or about to expire — refresh now so the UI never
      // opens with a stale token that auto-refresh hasn't caught yet.
      try {
        await auth.refreshSession();
      } catch (e, st) {
        debugPrint(
          'Session recovery: refresh token invalid at startup — signing out locally. ($e)\n$st',
        );
        await auth.signOut(scope: SignOutScope.local);
      }
    }
    return;
  }

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
    // Timed out — the broadcast event was already emitted before we subscribed
    // (e.g. hot-restart, web page re-init) or the network is very slow.
    // Force a refresh so we get the definitive server answer.
    if (auth.currentUser == null) {
      try {
        await auth.refreshSession();
      } catch (_) {
        // Refresh token is invalid — clear the stale local session so it is
        // not retried on the next cold start.
        await auth.signOut(scope: SignOutScope.local);
      }
    }
  }
}

Future<void> _initNobodyWho() async {
  if (kIsWeb) return; // nobodywho has no web support
  try {
    await nobodywho.NobodyWho.init();
  } catch (e, st) {
    debugPrint(
      'NobodyWho init failed: $e\n$st — rule-based parser will be used',
    );
  }
}
