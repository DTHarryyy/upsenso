import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/session/active_business_context.dart';

void main() {
  group('ActiveBusinessContext', () {
    late ActiveBusinessContext ctx;

    setUp(() => ctx = ActiveBusinessContext());

    test('starts empty with no active business', () {
      expect(ctx.userId, isNull);
      expect(ctx.businessId, isNull);
      expect(ctx.hasBusiness, isFalse);
    });

    test('binds the active session', () {
      ctx.set(
        userId: 'user-a',
        businessId: 'biz-a',
        branchId: 'branch-a',
        branchName: 'Main',
        roleName: 'Business Owner',
        fullName: 'Alice',
      );
      expect(ctx.userId, 'user-a');
      expect(ctx.businessId, 'biz-a');
      expect(ctx.branchId, 'branch-a');
      expect(ctx.roleName, 'Business Owner');
      expect(ctx.hasBusiness, isTrue);
    });

    test('normalises blank/whitespace businessId to null (pre-onboarding)', () {
      ctx.set(userId: 'user-new', businessId: '   ');
      expect(ctx.userId, 'user-new');
      expect(ctx.businessId, isNull);
      expect(ctx.hasBusiness, isFalse, reason: 'guards must treat blank as none');
    });

    test('clear() drops every field — used on logout', () {
      ctx.set(userId: 'user-a', businessId: 'biz-a', roleName: 'Cashier');
      ctx.clear();
      expect(ctx.userId, isNull);
      expect(ctx.businessId, isNull);
      expect(ctx.roleName, isNull);
      expect(ctx.hasBusiness, isFalse);
    });

    test('re-binding to a different account fully replaces the prior tenant', () {
      ctx.set(userId: 'user-a', businessId: 'biz-a', branchId: 'br-a');
      ctx.set(userId: 'user-b', businessId: 'biz-b');
      expect(ctx.userId, 'user-b');
      expect(ctx.businessId, 'biz-b');
      // No stale branch carried over from account A.
      expect(ctx.branchId, isNull);
    });
  });
}
