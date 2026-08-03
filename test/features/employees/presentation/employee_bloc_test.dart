import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos/features/employees/domain/entities/employee_creation_result.dart';
import 'package:pos/features/employees/domain/repositories/i_employees_repository.dart';
import 'package:pos/features/employees/presentation/bloc/employee_bloc.dart';
import 'package:pos/features/employees/presentation/bloc/employee_event.dart';
import 'package:pos/features/employees/presentation/bloc/employee_state.dart';

class MockEmployeesRepository extends Mock implements IEmployeesRepository {}

void main() {
  late MockEmployeesRepository repository;

  const addEvent = AddEmployee(
    branchId: 'branch-1',
    fullName: 'Maria Santos',
    email: 'maria@business.com',
    roleName: 'Cashier',
  );

  setUp(() {
    repository = MockEmployeesRepository();
  });

  group('AddEmployee', () {
    blocTest<EmployeeBloc, EmployeeState>(
      'carries a null temporaryPassword when the credentials email sent',
      build: () {
        when(() => repository.addEmployee(
              businessId: any(named: 'businessId'),
              branchId: any(named: 'branchId'),
              fullName: any(named: 'fullName'),
              email: any(named: 'email'),
              roleId: any(named: 'roleId'),
              roleName: any(named: 'roleName'),
            )).thenAnswer(
          (_) async => const EmployeeCreationResult(
            employeeId: 'emp-1',
            email: 'maria@business.com',
            credentialsEmailed: true,
          ),
        );
        return EmployeeBloc(repository);
      },
      act: (bloc) => bloc.add(addEvent),
      expect: () => [
        isA<EmployeeOperationSuccess>()
            .having((s) => s.creation?.credentialsEmailed, 'credentialsEmailed', true)
            .having((s) => s.creation?.temporaryPassword, 'temporaryPassword', isNull),
      ],
    );

    blocTest<EmployeeBloc, EmployeeState>(
      'surfaces the generated password when the credentials email failed',
      build: () {
        when(() => repository.addEmployee(
              businessId: any(named: 'businessId'),
              branchId: any(named: 'branchId'),
              fullName: any(named: 'fullName'),
              email: any(named: 'email'),
              roleId: any(named: 'roleId'),
              roleName: any(named: 'roleName'),
            )).thenAnswer(
          (_) async => const EmployeeCreationResult(
            employeeId: 'emp-1',
            email: 'maria@business.com',
            credentialsEmailed: false,
            temporaryPassword: 'K7mp-Qx4z-Rt9w',
          ),
        );
        return EmployeeBloc(repository);
      },
      act: (bloc) => bloc.add(addEvent),
      expect: () => [
        isA<EmployeeOperationSuccess>()
            .having((s) => s.creation?.credentialsEmailed, 'credentialsEmailed', false)
            .having(
              (s) => s.creation?.temporaryPassword,
              'temporaryPassword',
              'K7mp-Qx4z-Rt9w',
            ),
      ],
    );
  });
}
