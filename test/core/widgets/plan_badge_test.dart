import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/widgets/app_status_badge.dart';
import 'package:pos/core/widgets/plan_badge.dart';

class MockEntitlementService extends Mock implements EntitlementService {}

class MockPermissionService extends Mock implements PermissionService {}

void main() {
  late MockEntitlementService entitlement;
  late MockPermissionService perms;
  late ValueNotifier<int> revision;

  setUp(() async {
    await sl.reset();
    entitlement = MockEntitlementService();
    perms = MockPermissionService();
    revision = ValueNotifier<int>(0);
    when(() => entitlement.entitlementRevision).thenReturn(revision);
    sl.registerSingleton<EntitlementService>(entitlement);
    sl.registerSingleton<PermissionService>(perms);
  });

  tearDown(() async {
    revision.dispose();
    await sl.reset();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => const Scaffold(body: PlanBadge()),
            ),
            GoRoute(
              path: AppRoutes.billing,
              builder: (context, _) =>
                  const Scaffold(body: Text('Billing page')),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('shows the plan name for each status', (tester) async {
    when(() => perms.can(any())).thenReturn(false);

    when(() => entitlement.effectiveStatus).thenReturn('active');
    when(() => entitlement.planCode).thenReturn('growth');
    await pump(tester);
    expect(find.text('Growth'), findsOneWidget);

    when(() => entitlement.effectiveStatus).thenReturn('trialing');
    when(() => entitlement.planCode).thenReturn('starter');
    revision.value++;
    await tester.pump();
    expect(find.text('Starter'), findsOneWidget);
  });

  testWidgets('a lapsed account reads Free, not its old paid tier', (
    tester,
  ) async {
    when(() => perms.can(any())).thenReturn(false);
    when(() => entitlement.effectiveStatus).thenReturn('lapsed');
    when(() => entitlement.planCode).thenReturn('growth');
    await pump(tester);

    expect(find.text('Free'), findsOneWidget);
    expect(find.text('Growth'), findsNothing);
  });

  testWidgets('repaints when entitlementRevision bumps', (tester) async {
    when(() => perms.can(any())).thenReturn(false);
    when(() => entitlement.effectiveStatus).thenReturn('active');
    when(() => entitlement.planCode).thenReturn('free');
    await pump(tester);
    expect(find.text('Free'), findsOneWidget);

    when(() => entitlement.planCode).thenReturn('business');
    revision.value++;
    await tester.pump();

    expect(find.text('Business'), findsOneWidget);
  });

  testWidgets('is not tappable without nav.billing', (tester) async {
    when(() => perms.can(PermissionKeys.navBilling)).thenReturn(false);
    when(() => entitlement.effectiveStatus).thenReturn('active');
    when(() => entitlement.planCode).thenReturn('growth');
    await pump(tester);

    expect(find.byType(InkWell), findsNothing);

    await tester.tap(find.byType(AppStatusBadge));
    await tester.pumpAndSettle();
    expect(find.text('Billing page'), findsNothing);
  });

  testWidgets('opens billing when tapped with nav.billing', (tester) async {
    when(() => perms.can(PermissionKeys.navBilling)).thenReturn(true);
    when(() => entitlement.effectiveStatus).thenReturn('active');
    when(() => entitlement.planCode).thenReturn('growth');
    await pump(tester);

    await tester.tap(find.byType(AppStatusBadge));
    await tester.pumpAndSettle();

    expect(find.text('Billing page'), findsOneWidget);
  });
}
