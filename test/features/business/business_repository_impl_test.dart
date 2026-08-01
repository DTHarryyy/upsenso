import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/business_templates_dao.dart';
import 'package:pos/core/database/daos/businesses_dao.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';
import 'package:pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:pos/features/business/data/datasources/business_remote_ds.dart';
import 'package:pos/features/business/data/repositories/business_repository_impl.dart';

class _MockRemote extends Mock implements BusinessRemoteDs {}

class _MockConnectivity extends Mock implements ConnectivityService {}

class _MockAuth extends Mock implements AuthRepository {}

/// Regression cover for the 2026-07-26 duplicate-signup bug: one failing signup
/// left EIGHT businesses on the server because a fresh uuid was minted per
/// attempt. The identity must now be stable across retries.
void main() {
  late AppDatabase db;
  late _MockRemote remote;
  late _MockConnectivity connectivity;
  late _MockAuth auth;
  late BusinessRepositoryImpl repo;

  const ownerId = 'owner-1';
  const templateId = 'tpl-1';

  Map<String, dynamic> onboardingResult(String businessId, String branchId) => {
        'business': {
          'id': businessId,
          'name': 'Cruz Store',
          'owner_id': ownerId,
          'template_id': templateId,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'is_active': true,
        },
        'branch_id': branchId,
        'owner_role_id': 'role-1',
        'reused': false,
      };

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = _MockRemote();
    connectivity = _MockConnectivity();
    auth = _MockAuth();

    repo = BusinessRepositoryImpl(
      remote: remote,
      businessesDao: BusinessesDao(db),
      templatesDao: BusinessTemplatesDao(db),
      branchesDao: BranchesDao(db),
      categoriesDao: CategoriesDao(db),
      connectivity: connectivity,
      authRepository: auth,
    );

    when(() => connectivity.isConnected).thenAnswer((_) async => true);
    when(() => auth.getCurrentUser()).thenReturn(
      const AppUser(id: ownerId, email: 'sarah@example.com', fullName: 'Sarah'),
    );
    when(() => remote.getCategoriesByBusiness(any()))
        .thenAnswer((_) async => <Map<String, dynamic>>[]);
  });

  tearDown(() => db.close());

  test('provisions through a single onboarding call', () async {
    when(() => remote.createBusinessOnboarding(
          businessId: any(named: 'businessId'),
          name: any(named: 'name'),
          templateId: any(named: 'templateId'),
          branchId: any(named: 'branchId'),
          branchName: any(named: 'branchName'),
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
        )).thenAnswer((inv) async => onboardingResult(
          inv.namedArguments[#businessId] as String,
          inv.namedArguments[#branchId] as String,
        ));

    await repo.createBusiness(
      name: 'Cruz Store',
      ownerId: ownerId,
      templateId: templateId,
      branchName: 'Main',
      businessId: 'biz-1',
      branchId: 'br-1',
    );

    verify(() => remote.createBusinessOnboarding(
          businessId: 'biz-1',
          name: 'Cruz Store',
          templateId: templateId,
          branchId: 'br-1',
          branchName: 'Main',
          fullName: 'Sarah',
          email: 'sarah@example.com',
        )).called(1);
  });

  test('a retry reuses the caller ids instead of minting a second business',
      () async {
    var attempts = 0;
    when(() => remote.createBusinessOnboarding(
          businessId: any(named: 'businessId'),
          name: any(named: 'name'),
          templateId: any(named: 'templateId'),
          branchId: any(named: 'branchId'),
          branchName: any(named: 'branchName'),
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
        )).thenAnswer((inv) async {
      attempts++;
      if (attempts == 1) throw Exception('network died mid-signup');
      return onboardingResult(
        inv.namedArguments[#businessId] as String,
        inv.namedArguments[#branchId] as String,
      );
    });

    // First attempt fails — exactly the 2026-07-26 scenario.
    await expectLater(
      repo.createBusiness(
        name: 'Cruz Store',
        ownerId: ownerId,
        templateId: templateId,
        branchName: 'Main',
        businessId: 'biz-1',
        branchId: 'br-1',
      ),
      throwsA(isA<Exception>()),
    );

    // The caller retries with the SAME ids.
    final business = await repo.createBusiness(
      name: 'Cruz Store',
      ownerId: ownerId,
      templateId: templateId,
      branchName: 'Main',
      businessId: 'biz-1',
      branchId: 'br-1',
    );

    expect(business.id, 'biz-1');
    expect(attempts, 2);
    // The critical assertion: one identity, not two.
    final all = await BusinessesDao(db).getAll();
    expect(all.map((b) => b.id).toSet(), {'biz-1'});
  });

  test('a failed sync leaves the local business marked failed, not synced',
      () async {
    when(() => remote.createBusinessOnboarding(
          businessId: any(named: 'businessId'),
          name: any(named: 'name'),
          templateId: any(named: 'templateId'),
          branchId: any(named: 'branchId'),
          branchName: any(named: 'branchName'),
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
        )).thenThrow(Exception('boom'));

    await expectLater(
      repo.createBusiness(
        name: 'Cruz Store',
        ownerId: ownerId,
        templateId: templateId,
        branchName: 'Main',
        businessId: 'biz-1',
        branchId: 'br-1',
      ),
      throwsA(isA<Exception>()),
    );

    final row = await BusinessesDao(db).getById('biz-1');
    expect(row, isNotNull);
    expect(row!.syncStatus, SyncStatus.failed.toInt());
  });

  test('offline creates locally and never calls the server', () async {
    when(() => connectivity.isConnected).thenAnswer((_) async => false);

    final business = await repo.createBusiness(
      name: 'Cruz Store',
      ownerId: ownerId,
      templateId: templateId,
      branchName: 'Main',
      businessId: 'biz-1',
      branchId: 'br-1',
    );

    expect(business.id, 'biz-1');
    verifyNever(() => remote.createBusinessOnboarding(
          businessId: any(named: 'businessId'),
          name: any(named: 'name'),
          templateId: any(named: 'templateId'),
          branchId: any(named: 'branchId'),
          branchName: any(named: 'branchName'),
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
        ));
  });
}
