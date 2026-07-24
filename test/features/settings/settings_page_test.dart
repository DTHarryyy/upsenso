import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/settings/presentation/settings_page.dart';

class MockPermissionService extends Mock implements PermissionService {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockPermissionService perms;
  late MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(AuthLogoutRequested());
  });

  setUp(() async {
    await sl.reset();
    perms = MockPermissionService();
    authBloc = MockAuthBloc();
    sl.registerSingleton<PermissionService>(perms);
    when(() => authBloc.state).thenReturn(AuthUnauthenticated());
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the grouped sections and always-on rows', (
    tester,
  ) async {
    when(() => perms.can(any())).thenReturn(false);
    await pump(tester);

    // Section labels are upper-cased in the UI.
    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('BUSINESS'), findsOneWidget);
    expect(find.text('GENERAL'), findsOneWidget);
    expect(find.text('LEGAL'), findsOneWidget);

    // Account + Business + General + Legal + sign out show regardless of perms.
    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Export My Data'), findsOneWidget);
    expect(find.text('Business Profile'), findsOneWidget);
    expect(find.text('Receipt Settings'), findsOneWidget);
    expect(find.text('Switch themes'), findsOneWidget);
    expect(find.text('Clear cache'), findsOneWidget);
    expect(find.text('Leave feedback'), findsOneWidget);
    expect(find.text('FAQ'), findsOneWidget);
    expect(find.text('Data Privacy Terms'), findsOneWidget);
    expect(find.text('Terms and Conditions'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('hides the System Settings entry + Billing without permission', (
    tester,
  ) async {
    when(() => perms.can(any())).thenReturn(false);
    await pump(tester);

    // Admin config now lives on a sub-page reached via "System Settings"; the
    // entry (and Billing) hide when the user lacks the permissions.
    expect(find.text('System Settings'), findsNothing);
    expect(find.text('Billing & Subscription'), findsNothing);
    // The admin rows themselves are no longer on this page at all.
    expect(find.text('Module Management'), findsNothing);
    expect(find.text('Manager PIN'), findsNothing);
  });

  testWidgets('shows the System Settings entry + Billing with permission', (
    tester,
  ) async {
    when(() => perms.can(any())).thenReturn(true);
    await pump(tester);

    expect(find.text('System Settings'), findsOneWidget);
    expect(find.text('Billing & Subscription'), findsOneWidget);
  });

  testWidgets('confirming Sign out dispatches AuthLogoutRequested', (
    tester,
  ) async {
    when(() => perms.can(any())).thenReturn(false);
    await pump(tester);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    // Confirm in the dialog (the FilledButton, not the row).
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    verify(() => authBloc.add(any(that: isA<AuthLogoutRequested>()))).called(1);
  });
}
