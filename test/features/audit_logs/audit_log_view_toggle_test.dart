import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/widgets/app_data_table.dart';
import 'package:pos/core/widgets/app_view_toggle.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/audit_logs/domain/entities/audit_log.dart';
import 'package:pos/features/audit_logs/domain/repositories/i_audit_log_repository.dart';
import 'package:pos/features/audit_logs/presentation/pages/audit_log_page.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';

class MockPermissionService extends Mock implements PermissionService {}

class MockAuditLogRepository extends Mock implements IAuditLogRepository {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockPermissionService perms;
  late MockAuditLogRepository repo;
  late MockAuthBloc authBloc;

  const user = AppUser(id: 'u1', businessId: 'biz1', fullName: 'Harry');

  final sampleLog = AuditLog(
    id: 'log1',
    businessId: 'biz1',
    branchId: 'branch1',
    userId: 'u1',
    actionType: AuditLogActionType.saleCreated,
    entityType: 'sale',
    description: 'Sale created',
    metadata: const {'_user_name': 'Harry', '_branch_name': 'Main Branch'},
    deviceId: 'Pixel 7',
    createdAt: DateTime(2026, 7, 1, 10, 30),
    syncStatus: 1,
  );

  setUp(() async {
    await sl.reset();
    // setMockInitialValues is process-global — clear it so a saved pref from
    // one test can't leak into the next.
    SharedPreferences.setMockInitialValues({});
    perms = MockPermissionService();
    repo = MockAuditLogRepository();
    authBloc = MockAuthBloc();

    sl.registerSingleton<PermissionService>(perms);
    sl.registerSingleton<IAuditLogRepository>(repo);

    // Hide the owner-only verify button so it isn't in the way.
    when(() => perms.can(any())).thenReturn(false);

    when(() => authBloc.state).thenReturn(const AuthAuthenticated(user));

    when(
      () => repo.watchLogs(
        businessId: any(named: 'businessId'),
        branchId: any(named: 'branchId'),
        userId: any(named: 'userId'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) => Stream.value([sampleLog]));
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> pumpPage(WidgetTester tester, {Size size = const Size(400, 900)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<BranchCubit>(create: (_) => BranchCubit()),
          ],
          child: const AuditLogPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('starts in cards view on a phone, no table present', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.byType(AppDataTable), findsNothing);
    expect(find.byType(AppViewToggle), findsOneWidget);
  });

  testWidgets('tapping the view toggle switches cards → table', (tester) async {
    await pumpPage(tester);

    expect(find.byType(AppDataTable), findsNothing);

    await tester.tap(find.byType(AppViewToggle));
    await tester.pumpAndSettle();

    expect(find.byType(AppDataTable), findsOneWidget);
  });

  testWidgets(
    'returning user with saved "cards" pref (wide window) can still toggle to '
    'table',
    (tester) async {
      SharedPreferences.setMockInitialValues({'audit_log_view_mode': 'cards'});

      await pumpPage(tester, size: const Size(800, 900));

      // Saved pref forces cards even though the wide-window default is table.
      expect(find.byType(AppDataTable), findsNothing);

      await tester.tap(find.byType(AppViewToggle));
      await tester.pumpAndSettle();

      expect(find.byType(AppDataTable), findsOneWidget);
    },
  );

  testWidgets('wide window (>=600): defaults to table, round-trips both ways', (
    tester,
  ) async {
    await pumpPage(tester, size: const Size(800, 900));

    // Non-phone default is the table view.
    expect(find.byType(AppDataTable), findsOneWidget);

    await tester.tap(find.byType(AppViewToggle)); // → cards
    await tester.pumpAndSettle();
    expect(find.byType(AppDataTable), findsNothing);

    await tester.tap(find.byType(AppViewToggle)); // → table
    await tester.pumpAndSettle();
    expect(find.byType(AppDataTable), findsOneWidget);
  });

  // ── Root cause: MainNavigationPage places the page shell in structurally
  // different trees for phone vs tablet, so resizing across 600px reparents
  // the page and destroys its local state (view-mode, scroll, form input).
  // The fix is a GlobalKey on the shell so the element migrates instead of
  // being rebuilt. This test reproduces the reparent with the real page —
  // window fixed at 800px so the width-based default stays `table`, isolating
  // state preservation from the default — and asserts the keyed shell keeps
  // the user's toggle choice across the layout swap. ─────────────────────────

  BranchCubit makeBranchCubit(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final branchCubit = BranchCubit();
    addTearDown(branchCubit.close);
    return branchCubit;
  }

  Widget buildReparentApp({
    required bool tablet,
    required BranchCubit branchCubit,
    Key? shellKey,
  }) {
    Widget content = const AuditLogPage();
    if (shellKey != null) content = KeyedSubtree(key: shellKey, child: content);

    final body = tablet
        ? Row(
            children: [
              const SizedBox(width: 200), // stand-in sidebar
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 40), // stand-in app bar
                    Expanded(child: content),
                  ],
                ),
              ),
            ],
          )
        : content;

    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<BranchCubit>.value(value: branchCubit),
        ],
        child: Scaffold(body: body),
      ),
    );
  }

  testWidgets('reparent WITH a shell key preserves the toggle (the fix)', (
    tester,
  ) async {
    final branchCubit = makeBranchCubit(tester);
    final shellKey = GlobalKey();

    await tester.pumpWidget(
      buildReparentApp(tablet: true, branchCubit: branchCubit, shellKey: shellKey),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppDataTable), findsOneWidget); // default table @800px

    await tester.tap(find.byType(AppViewToggle)); // → cards
    await tester.pumpAndSettle();
    expect(find.byType(AppDataTable), findsNothing);

    // Flip to the phone-style tree — the GlobalKey migrates the element.
    await tester.pumpWidget(
      buildReparentApp(
        tablet: false,
        branchCubit: branchCubit,
        shellKey: shellKey,
      ),
    );
    await tester.pumpAndSettle();

    // Preserved: the cards choice survived the reparent.
    expect(find.byType(AppDataTable), findsNothing);
  });
}
