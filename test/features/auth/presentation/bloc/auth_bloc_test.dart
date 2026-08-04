import 'package:bloc_test/bloc_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_service.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';
import 'package:pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:pos/features/auth/domain/usecases/check_email_exists.dart';
import 'package:pos/features/auth/domain/usecases/get_current_user.dart';
import 'package:pos/features/auth/domain/usecases/get_user_business_context.dart';
import 'package:pos/features/auth/domain/usecases/observe_auth_state.dart';
import 'package:pos/features/auth/domain/usecases/reset_password.dart';
import 'package:pos/features/auth/domain/usecases/send_password_reset_otp.dart';
import 'package:pos/features/auth/domain/usecases/send_sign_up_otp.dart';
import 'package:pos/features/auth/domain/usecases/sign_in.dart';
import 'package:pos/features/auth/domain/usecases/sign_in_with_facebook.dart';
import 'package:pos/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:pos/features/auth/domain/usecases/sign_out.dart';
import 'package:pos/features/auth/domain/usecases/verify_password_reset_otp.dart';
import 'package:pos/features/auth/domain/usecases/verify_sign_up_otp.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/billing/data/play_purchase_sync_service.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSyncService extends Mock implements SyncService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockPermissionService extends Mock implements PermissionService {}

class MockActiveBusinessContext extends Mock implements ActiveBusinessContext {}

class MockPlayPurchaseSyncService extends Mock
    implements PlayPurchaseSyncService {}

class MockAuditLogService extends Mock implements AuditLogService {}

/// Regression cover for the 2026-08-04 "purchase history missing after
/// re-login" bug. Root cause: logout wiped the entire local Drift DB
/// (SyncService.clearLocalData) and relied on a full re-pull to restore it,
/// but the customer<->sale link never survived that round trip. The fix
/// removes the logout wipe (the same user re-logging in keeps their local
/// data) and leans on _resetIfAccountSwitch to still isolate a genuinely
/// different account on the same device. These tests cover that behavioral
/// split, not the pull-fidelity fix — see transactions_dao_test.dart for that.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AuthContextDao authContextDao;
  late MockAuthRepository authRepo;
  late MockSyncService syncService;
  late MockConnectivityService connectivity;
  late MockPermissionService permissionService;
  late MockActiveBusinessContext activeBusinessContext;
  late MockPlayPurchaseSyncService playPurchaseSyncService;
  late MockAuditLogService auditLogService;

  const testUser = AppUser(
    id: 'user-new',
    email: 'new@upsenso.com',
    fullName: 'New User',
    businessId: 'biz-1',
    roleId: 'role-1',
    roleName: 'Owner',
  );

  AuthBloc buildBloc() {
    return AuthBloc(
      getCurrentUser: GetCurrentUser(authRepo),
      getUserBusinessContext: GetUserBusinessContext(authRepo),
      observeAuthState: ObserveAuthState(authRepo),
      signIn: SignIn(authRepo),
      signInWithGoogle: SignInWithGoogle(authRepo),
      signInWithFacebook: SignInWithFacebook(authRepo),
      checkEmailExists: CheckEmailExists(authRepo),
      sendSignUpOtp: SendSignUpOtp(authRepo),
      verifySignUpOtp: VerifySignUpOtp(authRepo),
      signOut: SignOut(authRepo),
      sendPasswordResetOtp: SendPasswordResetOtp(authRepo),
      verifyPasswordResetOtp: VerifyPasswordResetOtp(authRepo),
      resetPassword: ResetPassword(authRepo),
      connectivityService: connectivity,
      syncService: syncService,
    );
  }

  setUpAll(() {
    registerFallbackValue(AuditLogActionType.userLogout);
  });

  setUp(() async {
    await sl.reset();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    authContextDao = AuthContextDao(db);
    sl.registerSingleton<AuthContextDao>(authContextDao);

    authRepo = MockAuthRepository();
    syncService = MockSyncService();
    connectivity = MockConnectivityService();
    permissionService = MockPermissionService();
    activeBusinessContext = MockActiveBusinessContext();
    playPurchaseSyncService = MockPlayPurchaseSyncService();
    auditLogService = MockAuditLogService();

    sl.registerSingleton<PermissionService>(permissionService);
    sl.registerSingleton<ActiveBusinessContext>(activeBusinessContext);
    sl.registerSingleton<PlayPurchaseSyncService>(playPurchaseSyncService);
    sl.registerSingleton<AuditLogService>(auditLogService);

    // Constructor-time subscription; never emits in these tests.
    when(() => authRepo.authStateChanges()).thenAnswer(
      (_) => const Stream<AppUser?>.empty(),
    );
    when(() => authRepo.signOut()).thenAnswer((_) async {});
    when(() => permissionService.clearPermissions()).thenReturn(null);
    when(() => activeBusinessContext.clear()).thenReturn(null);
    when(() => playPurchaseSyncService.reset()).thenReturn(null);
    when(() => auditLogService.log(
          actionType: any(named: 'actionType'),
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          entityName: any(named: 'entityName'),
          userName: any(named: 'userName'),
          description: any(named: 'description'),
          metadata: any(named: 'metadata'),
          businessId: any(named: 'businessId'),
          branchId: any(named: 'branchId'),
          userId: any(named: 'userId'),
        )).thenAnswer((_) async {});
    when(() => syncService.isOnline).thenAnswer((_) async => false);
    when(() => syncService.pause()).thenReturn(null);
  });

  tearDown(() => db.close());

  group('logout', () {
    blocTest<AuthBloc, AuthState>(
      'no longer wipes local data — same user re-login keeps their cache',
      build: buildBloc,
      seed: () => const AuthAuthenticated(testUser),
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      expect: () => [AuthUnauthenticated()],
      verify: (_) {
        verifyNever(() => syncService.clearLocalData());
        verifyNever(
          () => syncService.clearLocalData(force: any(named: 'force')),
        );
      },
    );

    blocTest<AuthBloc, AuthState>(
      'still pushes pending changes before pausing sync',
      build: buildBloc,
      seed: () => const AuthAuthenticated(testUser),
      setUp: () {
        when(() => syncService.isOnline).thenAnswer((_) async => true);
        when(
          () => syncService.syncAll(businessId: any(named: 'businessId')),
        ).thenAnswer((_) async => SyncResult(success: true, message: 'ok'));
      },
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      verify: (_) {
        verify(
          () => syncService.syncAll(businessId: testUser.businessId),
        ).called(1);
        verify(() => syncService.pause()).called(1);
      },
    );
  });

  group('login — account switch isolation', () {
    blocTest<AuthBloc, AuthState>(
      'a DIFFERENT account logging in on this device still wipes first',
      build: buildBloc,
      setUp: () async {
        // Simulate a previous account's context still cached on this device
        // (the case logout no longer clears).
        await authContextDao.saveContext(userId: 'user-old');
        when(() => authRepo.signIn(any(), any())).thenAnswer(
          (_) async => testUser,
        );
        when(() => authRepo.getUserBusinessContext(testUser.id)).thenAnswer(
          (_) async => testUser,
        );
        when(() => syncService.clearLocalData()).thenAnswer((_) async {});
        when(() => syncService.syncAll(businessId: any(named: 'businessId')))
            .thenAnswer((_) async => SyncResult(success: true, message: 'ok'));
        when(() => permissionService.loadPermissions(any()))
            .thenAnswer((_) async {});
        when(() => permissionService.loadEnabledModules(any()))
            .thenAnswer((_) async {});
        when(() => permissionService.syncPermissions(any()))
            .thenAnswer((_) async {});
        when(() => permissionService.syncModules(any()))
            .thenAnswer((_) async {});
        when(() => permissionService.setContext(
              roleName: any(named: 'roleName'),
              branchId: any(named: 'branchId'),
              userId: any(named: 'userId'),
            )).thenReturn(null);
        when(() => activeBusinessContext.set(
              userId: any(named: 'userId'),
              businessId: any(named: 'businessId'),
              branchId: any(named: 'branchId'),
              branchName: any(named: 'branchName'),
              roleName: any(named: 'roleName'),
              fullName: any(named: 'fullName'),
            )).thenReturn(null);
      },
      act: (bloc) => bloc.add(const AuthLoginRequested('new@upsenso.com', 'pw')),
      verify: (_) {
        verify(() => syncService.clearLocalData()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'unsynced data from the prior account surfaces as a specific error, '
      'not a raw StateError',
      build: buildBloc,
      setUp: () async {
        await authContextDao.saveContext(userId: 'user-old');
        when(() => authRepo.signIn(any(), any())).thenAnswer(
          (_) async => testUser,
        );
        when(() => syncService.clearLocalData()).thenThrow(
          StateError('Refusing to clear local data: 3 unsynced record(s) pending'),
        );
        when(() => syncService.pendingSyncCount()).thenAnswer((_) async => 3);
      },
      act: (bloc) => bloc.add(const AuthLoginRequested('new@upsenso.com', 'pw')),
      expect: () => [
        const AuthLoading(type: AuthLoadingType.email),
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          contains('3 unsynced record'),
        ),
        AuthUnauthenticated(),
      ],
    );
  });
}
