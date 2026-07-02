import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/features/crm/domain/entities/customer.dart';
import 'package:pos/features/crm/domain/repositories/i_customer_repository.dart';
import 'package:pos/features/crm/presentation/widgets/customer_inline_picker.dart';
import 'package:pos/features/crm/presentation/widgets/customer_selection.dart';

class MockPermissionService extends Mock implements PermissionService {}

class MockCustomerRepository extends Mock implements ICustomerRepository {}

void main() {
  late MockPermissionService perms;
  late MockCustomerRepository repo;

  final customers = [
    Customer(
      id: 'c1',
      businessId: 'biz1',
      name: 'Maria Santos',
      phone: '09171234567',
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    Customer(
      id: 'c2',
      businessId: 'biz1',
      name: 'Mark Cruz',
      phone: '09179876543',
      isActive: true,
      createdAt: DateTime(2026, 1, 2),
    ),
  ];

  setUp(() async {
    // GetIt is a process-wide singleton — start each test from a clean slate
    // regardless of what earlier tests registered.
    await sl.reset();
    perms = MockPermissionService();
    repo = MockCustomerRepository();
    sl.registerSingleton<PermissionService>(perms);
    sl.registerSingleton<ICustomerRepository>(repo);
    when(() => repo.watchCustomers(any())).thenAnswer((_) => Stream.value(customers));
  });

  tearDown(() async {
    await sl.reset();
  });

  void stubPermissions({required bool view, required bool manage}) {
    when(() => perms.can(PermissionKeys.crmView)).thenReturn(view);
    when(() => perms.can(PermissionKeys.crmManage)).thenReturn(manage);
  }

  Future<void> pumpPicker(
    WidgetTester tester, {
    required ValueChanged<CustomerSelection?> onChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomerInlinePicker(businessId: 'biz1', onChanged: onChanged),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'crm.view=false: typing a matching name shows no suggestions and emits a '
    'name-only selection (no directory access at all)',
    (tester) async {
      stubPermissions(view: false, manage: false);
      CustomerSelection? emitted;
      await pumpPicker(tester, onChanged: (sel) => emitted = sel);

      await tester.enterText(find.byType(TextField), 'Maria');
      await tester.pumpAndSettle();

      expect(find.text('Maria Santos'), findsNothing);
      expect(find.textContaining('Save "Maria" as a customer'), findsNothing);
      expect(emitted, isNotNull);
      expect(emitted!.adHocName, 'Maria');
      expect(emitted!.customer, isNull);

      // Never even loads the directory when the role can't view it.
      verifyNever(() => repo.watchCustomers(any()));
    },
  );

  testWidgets(
    'crm.view=true, crm.manage=false (cashier): shows suggestions, no save '
    'row, tapping a match links the saved customer',
    (tester) async {
      stubPermissions(view: true, manage: false);
      CustomerSelection? emitted;
      await pumpPicker(tester, onChanged: (sel) => emitted = sel);

      await tester.enterText(find.byType(TextField), 'Maria');
      await tester.pumpAndSettle();

      expect(find.text('Maria Santos'), findsOneWidget);
      expect(find.textContaining('Save "Maria" as a customer'), findsNothing);

      await tester.tap(find.text('Maria Santos'));
      await tester.pumpAndSettle();

      expect(emitted, isNotNull);
      expect(emitted!.customer?.id, 'c1');
      expect(emitted!.adHocName, isNull);
    },
  );

  testWidgets(
    'crm.manage=true: shows "Save as a customer" row when no exact match',
    (tester) async {
      stubPermissions(view: true, manage: true);
      await pumpPicker(tester, onChanged: (_) {});

      await tester.enterText(find.byType(TextField), 'Zoe');
      await tester.pumpAndSettle();

      expect(find.text('Maria Santos'), findsNothing); // no match for "Zoe"
      expect(find.textContaining('Save "Zoe" as a customer'), findsOneWidget);
    },
  );
}
