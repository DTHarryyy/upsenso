import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/data_scope.dart';
import 'package:pos/core/permissions/data_scoping_layer.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/features/ai_assistant/models/ai_models.dart';
import 'package:pos/features/ai_assistant/services/ai_scope_guard.dart';

class MockPermissionService extends Mock implements PermissionService {}

class MockDataScopingLayer extends Mock implements DataScopingLayer {}

class MockActiveBusinessContext extends Mock implements ActiveBusinessContext {}

class MockBranchCubit extends Mock implements BranchCubit {}

void main() {
  late MockPermissionService perms;
  late MockDataScopingLayer scoping;
  late MockActiveBusinessContext business;
  late MockBranchCubit branches;
  late AiScopeGuard guard;

  setUpAll(() => registerFallbackValue(AppPermission.createSale));

  setUp(() {
    perms = MockPermissionService();
    scoping = MockDataScopingLayer();
    business = MockActiveBusinessContext();
    branches = MockBranchCubit();
    guard = AiScopeGuard(
      permissions: perms,
      scoping: scoping,
      business: business,
      branches: branches,
    );

    // Default: a signed-in business, everything denied unless a test grants it.
    when(() => business.hasBusiness).thenReturn(true);
    when(() => business.businessId).thenReturn('biz1');
    when(() => business.userId).thenReturn('user1');
    when(() => perms.can(any())).thenReturn(false);
  });

  group('authorizeRead', () {
    test('denies every action when there is no active business', () {
      when(() => business.hasBusiness).thenReturn(false);
      when(() => perms.can(any())).thenReturn(true); // even with perms
      final r = guard.authorizeRead(AiAction.getSales);
      expect(r.allowed, isFalse);
    });

    test('sales analytics require nav.reports', () {
      when(() => perms.can(PermissionKeys.navReports)).thenReturn(true);
      for (final a in [
        AiAction.getSales,
        AiAction.getSalesByCategory,
        AiAction.getSalesByProduct,
        AiAction.getProductsWithoutSales,
        AiAction.getTransactionCount,
      ]) {
        expect(guard.authorizeRead(a).allowed, isTrue, reason: '$a allowed');
      }
    });

    test('sales analytics denied without nav.reports', () {
      final r = guard.authorizeRead(AiAction.getSales);
      expect(r.allowed, isFalse);
      expect(r.message, contains('sales reports'));
    });

    test('product catalog requires products.view', () {
      when(() => perms.can(PermissionKeys.productsView)).thenReturn(true);
      expect(guard.authorizeRead(AiAction.getProductCount).allowed, isTrue);
      expect(guard.authorizeRead(AiAction.getActiveProducts).allowed, isTrue);
    });

    test('expenses require expenses.view', () {
      expect(guard.authorizeRead(AiAction.getExpenses).allowed, isFalse);
      when(() => perms.can(PermissionKeys.expensesView)).thenReturn(true);
      expect(guard.authorizeRead(AiAction.getExpenses).allowed, isTrue);
    });

    test(
      'deny-by-default: the write action and unknown are not read-gated',
      () {
        when(() => perms.can(any())).thenReturn(true);
        expect(
          guard.authorizeRead(AiAction.createTransaction).allowed,
          isFalse,
        );
        expect(guard.authorizeRead(AiAction.unknown).allowed, isFalse);
      },
    );
  });

  group('authorizeWrite', () {
    test('grants sale creation when guard(pos.use) passes', () async {
      when(
        () => perms.guard(
          any(),
          entityType: any(named: 'entityType'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => const PermissionResult.granted());

      final r = await guard.authorizeWrite(AiAction.createTransaction);
      expect(r.allowed, isTrue);
      verify(
        () => perms.guard(
          AppPermission.createSale,
          entityType: any(named: 'entityType'),
          description: any(named: 'description'),
        ),
      ).called(1);
    });

    test('denies sale creation when guard(pos.use) fails', () async {
      when(
        () => perms.guard(
          any(),
          entityType: any(named: 'entityType'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => const PermissionResult.denied('no pos.use'));

      final r = await guard.authorizeWrite(AiAction.createTransaction);
      expect(r.allowed, isFalse);
      expect(r.message, 'no pos.use');
    });

    test('fails closed with no active business (no guard call)', () async {
      when(() => business.hasBusiness).thenReturn(false);
      final r = await guard.authorizeWrite(AiAction.createTransaction);
      expect(r.allowed, isFalse);
      verifyNever(
        () => perms.guard(
          any(),
          entityType: any(named: 'entityType'),
          description: any(named: 'description'),
        ),
      );
    });

    test('refuses a non-create action', () async {
      final r = await guard.authorizeWrite(AiAction.getSales);
      expect(r.allowed, isFalse);
    });
  });

  group('resolveScope', () {
    test('owner (allBranches) honours the branch picker, no own filter', () {
      when(
        () => scoping.scope,
      ).thenReturn(const DataScope(type: DataScopeType.allBranches));
      when(() => scoping.effectiveUserFilter).thenReturn(null);
      when(() => branches.getSelectedBranchIdForFiltering()).thenReturn('b2');

      final s = guard.resolveScope();
      expect(s.businessId, 'biz1');
      expect(s.userId, 'user1');
      expect(s.branchId, 'b2'); // from the picker
      expect(s.ownUserId, isNull);
    });

    test('branch manager is locked to their branch, no own filter', () {
      when(() => scoping.scope).thenReturn(const DataScope.branch('b1'));
      when(() => scoping.effectiveBranchFilter).thenReturn('b1');
      when(() => scoping.effectiveUserFilter).thenReturn(null);

      final s = guard.resolveScope();
      expect(s.branchId, 'b1');
      expect(s.ownUserId, isNull);
      // Picker must NOT be consulted for a locked scope.
      verifyNever(() => branches.getSelectedBranchIdForFiltering());
    });

    test('cashier (ownOnly) is locked to own branch + own rows', () {
      when(
        () => scoping.scope,
      ).thenReturn(const DataScope.own(branchId: 'b1', userId: 'user1'));
      when(() => scoping.effectiveBranchFilter).thenReturn('b1');
      when(() => scoping.effectiveUserFilter).thenReturn('user1');

      final s = guard.resolveScope();
      expect(s.branchId, 'b1');
      expect(s.ownUserId, 'user1');
    });

    test('includeStock follows inventory.view_levels', () {
      when(
        () => scoping.scope,
      ).thenReturn(const DataScope(type: DataScopeType.allBranches));
      when(() => scoping.effectiveUserFilter).thenReturn(null);
      when(() => branches.getSelectedBranchIdForFiltering()).thenReturn(null);

      expect(guard.resolveScope().includeStock, isFalse);
      when(
        () => perms.can(PermissionKeys.inventoryViewLevels),
      ).thenReturn(true);
      expect(guard.resolveScope().includeStock, isTrue);
    });
  });
}
