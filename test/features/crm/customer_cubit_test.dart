import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/features/crm/domain/entities/customer.dart';
import 'package:pos/features/crm/domain/repositories/i_customer_repository.dart';
import 'package:pos/features/crm/presentation/cubit/customer_cubit.dart';
import 'package:pos/features/crm/presentation/cubit/customer_state.dart';

class MockCustomerRepository extends Mock implements ICustomerRepository {}

class MockPermissionService extends Mock implements PermissionService {}

Customer _customer(String id, String name) => Customer(
      id: id,
      businessId: 'biz-1',
      name: name,
      isActive: true,
      createdAt: DateTime(2026, 6, 1),
    );

void main() {
  late MockCustomerRepository repo;
  late MockPermissionService perms;
  late StreamController<List<Customer>> stream;

  setUp(() {
    repo = MockCustomerRepository();
    perms = MockPermissionService();
    stream = StreamController<List<Customer>>.broadcast();
    when(() => repo.watchCustomers(any())).thenAnswer((_) => stream.stream);
  });

  tearDown(() => stream.close());

  void allowManage(bool granted) {
    when(() => perms.guard(
          AppPermission.manageCustomers,
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
        )).thenAnswer((_) async => granted
        ? const PermissionResult.granted()
        : const PermissionResult.denied('nope'));
  }

  Future<CustomerCubit> loadedCubit(List<Customer> seed) async {
    final cubit = CustomerCubit(
      repository: repo,
      permissions: perms,
      businessId: 'biz-1',
    )..watch();
    stream.add(seed);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<CustomerLoaded>());
    return cubit;
  }

  test('createCustomer denied when the user lacks crm.manage', () async {
    allowManage(false);
    final cubit = await loadedCubit([]);

    final ok = await cubit.createCustomer(name: 'Maria');

    expect(ok, isFalse);
    verifyNever(() => repo.createCustomer(
          businessId: any(named: 'businessId'),
          name: any(named: 'name'),
        ));
    await cubit.close();
  });

  test('createCustomer rejects a duplicate name (case-insensitive)', () async {
    allowManage(true);
    final cubit = await loadedCubit([_customer('c1', 'Maria')]);

    // The cubit surfaces a transient CustomerError then re-emits the list, so
    // the durable signals are the false return and that no write was attempted.
    final ok = await cubit.createCustomer(name: '  maria ');

    expect(ok, isFalse);
    verifyNever(() => repo.createCustomer(
          businessId: any(named: 'businessId'),
          name: any(named: 'name'),
        ));
    await cubit.close();
  });

  test('createCustomer writes through when allowed and unique', () async {
    allowManage(true);
    when(() => repo.createCustomer(
          businessId: any(named: 'businessId'),
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          email: any(named: 'email'),
          address: any(named: 'address'),
          notes: any(named: 'notes'),
        )).thenAnswer((_) async => _customer('new', 'Ana'));

    final cubit = await loadedCubit([]);
    final ok = await cubit.createCustomer(name: 'Ana');

    expect(ok, isTrue);
    verify(() => repo.createCustomer(
          businessId: 'biz-1',
          name: 'Ana',
          phone: null,
          email: null,
          address: null,
          notes: null,
        )).called(1);
    await cubit.close();
  });

  test('archiveCustomer denied does not touch the repository', () async {
    allowManage(false);
    final cubit = await loadedCubit([_customer('c1', 'Maria')]);

    await cubit.archiveCustomer('c1');

    verifyNever(() => repo.archiveCustomer(any()));
    await cubit.close();
  });
}
