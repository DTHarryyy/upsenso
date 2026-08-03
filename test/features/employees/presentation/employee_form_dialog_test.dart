import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/features/business/domain/entities/branch.dart';
import 'package:pos/features/employees/domain/entities/employee_creation_result.dart';
import 'package:pos/features/employees/domain/repositories/i_employees_repository.dart';
import 'package:pos/features/employees/presentation/bloc/employee_bloc.dart';
import 'package:pos/features/employees/presentation/bloc/employee_state.dart';
import 'package:pos/features/employees/presentation/dialogs/employee_form_dialog.dart';
import 'package:pos/features/employees/presentation/dialogs/temp_password_dialog.dart';

class MockEmployeesRepository extends Mock implements IEmployeesRepository {}

/// Regression cover for the 2026-08-03 "employee creation hangs forever" bug:
/// the page's success listener pushes the temp-password sheet, and the form's
/// own listener used to call a bare `Navigator.pop()`, which dismissed
/// whichever route was on top — the sheet, not the form — leaving the form
/// stuck open with its spinner still running. See
/// employees_repository_impl_test.dart for the matching server-side coverage.
void main() {
  late MockEmployeesRepository repository;
  const branches = [
    Branch(id: 'branch-1', businessId: 'biz-1', name: 'Main Branch'),
  ];

  setUp(() {
    repository = MockEmployeesRepository();
  });

  /// Mimics employees_page.dart's success listener closely enough to
  /// reproduce the real collision: on the same [EmployeeOperationSuccess]
  /// state the form's own listener is reacting to, this pushes the
  /// temp-password sheet on the very same navigator the form's route lives
  /// on — exactly what happens when Employees is reached from the More
  /// drawer, where both land on the root navigator.
  Widget buildHost(EmployeeBloc bloc) {
    return MaterialApp(
      home: BlocProvider.value(
        value: bloc,
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: Column(
                children: [
                  BlocListener<EmployeeBloc, EmployeeState>(
                    listenWhen: (_, curr) => curr is EmployeeOperationSuccess,
                    listener: (ctx, state) {
                      final creation =
                          (state as EmployeeOperationSuccess).creation;
                      if (creation == null || creation.credentialsEmailed) {
                        return;
                      }
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!ctx.mounted) return;
                        showTempPasswordDialog(
                          context: ctx,
                          email: creation.email,
                          temporaryPassword: creation.temporaryPassword!,
                        );
                      });
                    },
                    child: const SizedBox.shrink(),
                  ),
                  ElevatedButton(
                    onPressed: () => showEmployeeFormDialog(
                      context: context,
                      branches: branches,
                      lockedBranchId: 'branch-1',
                    ),
                    child: const Text('Open Form'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> fillAndSubmit(WidgetTester tester) async {
    await tester.tap(find.text('Open Form'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. Maria Santos'),
      'Maria Santos',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. maria@business.com'),
      'maria@business.com',
    );
    final submitButton = find.widgetWithText(AppFilledButton, 'Add Employee');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
  }

  testWidgets(
    'closes the form (not the temp-password sheet) when the credentials '
    'email failed to send',
    (tester) async {
      when(
        () => repository.addEmployee(
          businessId: any(named: 'businessId'),
          branchId: any(named: 'branchId'),
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          roleId: any(named: 'roleId'),
          roleName: any(named: 'roleName'),
        ),
      ).thenAnswer(
        (_) async => const EmployeeCreationResult(
          employeeId: 'emp-1',
          email: 'maria@business.com',
          credentialsEmailed: false,
          temporaryPassword: 'K7mp-Qx4z-Rt9w',
        ),
      );

      final bloc = EmployeeBloc(repository);
      addTearDown(bloc.close);
      await tester.pumpWidget(buildHost(bloc));

      await fillAndSubmit(tester);
      await tester.pumpAndSettle();

      // The temp-password sheet is the only thing left on screen...
      expect(find.text('Employee Added'), findsOneWidget);
      expect(find.text('K7mp-Qx4z-Rt9w'), findsOneWidget);
      // ...and the form is actually gone, not stuck open behind it.
      expect(find.text('Add Employee'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'e.g. Maria Santos'),
          findsNothing);
    },
  );

  testWidgets(
    'closes the form directly when the credentials email sent successfully',
    (tester) async {
      when(
        () => repository.addEmployee(
          businessId: any(named: 'businessId'),
          branchId: any(named: 'branchId'),
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          roleId: any(named: 'roleId'),
          roleName: any(named: 'roleName'),
        ),
      ).thenAnswer(
        (_) async => const EmployeeCreationResult(
          employeeId: 'emp-1',
          email: 'maria@business.com',
          credentialsEmailed: true,
        ),
      );

      final bloc = EmployeeBloc(repository);
      addTearDown(bloc.close);
      await tester.pumpWidget(buildHost(bloc));

      await fillAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.text('Employee Added'), findsNothing);
      expect(find.text('Add Employee'), findsNothing);
      expect(find.text('Open Form'), findsOneWidget);
    },
  );
}
