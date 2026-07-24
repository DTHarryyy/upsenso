import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/features/settings/presentation/system_settings_page.dart';

class MockPermissionService extends Mock implements PermissionService {}

void main() {
  late MockPermissionService perms;

  setUp(() async {
    await sl.reset();
    perms = MockPermissionService();
    sl.registerSingleton<PermissionService>(perms);
    // Default deny; individual tests grant specific keys.
    when(() => perms.can(any())).thenReturn(false);
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: SystemSettingsPage()));
    await tester.pumpAndSettle();
  }

  testWidgets('owner/admin sees all three rows', (tester) async {
    when(() => perms.can(PermissionKeys.settingsEditBusiness)).thenReturn(true);
    when(() => perms.can(PermissionKeys.posApproveRefund)).thenReturn(true);
    await pump(tester);

    expect(find.text('Module Management'), findsOneWidget);
    expect(find.text('Refund Approval'), findsOneWidget);
    expect(find.text('Manager PIN'), findsOneWidget);
    expect(find.text('Nothing to configure'), findsNothing);
  });

  testWidgets('refund-approver (no business edit) sees only Manager PIN', (
    tester,
  ) async {
    when(() => perms.can(PermissionKeys.posApproveRefund)).thenReturn(true);
    await pump(tester);

    expect(find.text('Manager PIN'), findsOneWidget);
    expect(find.text('Module Management'), findsNothing);
    expect(find.text('Refund Approval'), findsNothing);
  });

  testWidgets('no relevant permissions shows the empty state', (tester) async {
    await pump(tester);

    expect(find.text('Nothing to configure'), findsOneWidget);
    expect(find.text('Module Management'), findsNothing);
    expect(find.text('Manager PIN'), findsNothing);
  });
}
