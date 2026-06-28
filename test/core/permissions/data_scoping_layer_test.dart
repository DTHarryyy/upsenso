import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos/core/permissions/data_scope.dart';
import 'package:pos/core/permissions/data_scoping_layer.dart';
import 'package:pos/core/permissions/permission_service.dart';

class MockPermissionService extends Mock implements PermissionService {}

class _Item {
  final String id;
  final String? branchId;
  final String? userId;
  const _Item(this.id, this.branchId, this.userId);
}

void main() {
  late MockPermissionService permissionService;
  late DataScopingLayer layer;

  setUp(() {
    permissionService = MockPermissionService();
    layer = DataScopingLayer(permissionService: permissionService);
  });

  void givenScope(DataScope scope) {
    when(() => permissionService.getDataScope()).thenReturn(scope);
  }

  const items = [
    _Item('1', 'branchA', 'userA'),
    _Item('2', 'branchA', 'userB'),
    _Item('3', 'branchB', 'userA'),
  ];

  group('apply()', () {
    test('allBranches scope returns every item unfiltered', () {
      givenScope(const DataScope.unrestricted());
      final result = layer.apply(items: items, getBranchId: (i) => i.branchId);
      expect(result, hasLength(3));
    });

    test('branchOnly scope keeps only items in the scoped branch', () {
      givenScope(const DataScope.branch('branchA'));
      final result = layer.apply(items: items, getBranchId: (i) => i.branchId);
      expect(result.map((i) => i.id), ['1', '2']);
    });

    test('ownOnly scope keeps only items matching both branch and user', () {
      givenScope(const DataScope.own(branchId: 'branchA', userId: 'userA'));
      final result = layer.apply(
        items: items,
        getBranchId: (i) => i.branchId,
        getUserId: (i) => i.userId,
      );
      expect(result.map((i) => i.id), ['1']);
    });

    test('ownOnly scope without a getUserId only filters by branch', () {
      givenScope(const DataScope.own(branchId: 'branchA', userId: 'userA'));
      final result = layer.apply(items: items, getBranchId: (i) => i.branchId);
      expect(result.map((i) => i.id), ['1', '2']);
    });
  });

  group('canAccessBranch()', () {
    test('allBranches can access any branch', () {
      givenScope(const DataScope.unrestricted());
      expect(layer.canAccessBranch('anything'), isTrue);
    });

    test('branchOnly can access only its own branch', () {
      givenScope(const DataScope.branch('branchA'));
      expect(layer.canAccessBranch('branchA'), isTrue);
      expect(layer.canAccessBranch('branchB'), isFalse);
    });
  });

  group('canAccessUserData()', () {
    test('allBranches can access any user', () {
      givenScope(const DataScope.unrestricted());
      expect(layer.canAccessUserData('whoever'), isTrue);
    });

    test('branchOnly can access any user within the branch (no user narrowing)', () {
      givenScope(const DataScope.branch('branchA'));
      expect(layer.canAccessUserData('whoever'), isTrue);
    });

    test('ownOnly can access only its own user', () {
      givenScope(const DataScope.own(branchId: 'branchA', userId: 'userA'));
      expect(layer.canAccessUserData('userA'), isTrue);
      expect(layer.canAccessUserData('userB'), isFalse);
    });
  });

  group('effectiveBranchFilter / effectiveUserFilter', () {
    test('allBranches has no branch or user filter', () {
      givenScope(const DataScope.unrestricted());
      expect(layer.effectiveBranchFilter, isNull);
      expect(layer.effectiveUserFilter, isNull);
    });

    test('branchOnly filters by branch but not by user', () {
      givenScope(const DataScope.branch('branchA'));
      expect(layer.effectiveBranchFilter, 'branchA');
      expect(layer.effectiveUserFilter, isNull);
    });

    test('ownOnly filters by both branch and user', () {
      givenScope(const DataScope.own(branchId: 'branchA', userId: 'userA'));
      expect(layer.effectiveBranchFilter, 'branchA');
      expect(layer.effectiveUserFilter, 'userA');
    });
  });
}
