import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/procurement/domain/entities/approval_policy.dart';

/// Governance matrix: owners always self-approve; an unset threshold means
/// approvers self-approve any amount; above a set threshold a non-owner needs a
/// separate approver.
void main() {
  group('requiresSeparateApprover', () {
    test('owner is never required to route, even above threshold', () {
      expect(
        ApprovalPolicy.requiresSeparateApprover(
          total: 10000, threshold: 1000, actorIsOwner: true),
        isFalse,
      );
    });

    test('unset threshold never requires a separate approver', () {
      expect(
        ApprovalPolicy.requiresSeparateApprover(
          total: 999999, threshold: null, actorIsOwner: false),
        isFalse,
      );
    });

    test('non-owner above threshold requires a separate approver', () {
      expect(
        ApprovalPolicy.requiresSeparateApprover(
          total: 1500, threshold: 1000, actorIsOwner: false),
        isTrue,
      );
    });

    test('non-owner at or below threshold does not require routing', () {
      expect(
        ApprovalPolicy.requiresSeparateApprover(
          total: 1000, threshold: 1000, actorIsOwner: false),
        isFalse,
      );
    });
  });

  group('canInstantApprove', () {
    test('false without approve permission regardless of amount', () {
      expect(
        ApprovalPolicy.canInstantApprove(
          canApprove: false, total: 1, threshold: null, actorIsOwner: true),
        isFalse,
      );
    });

    test('owner with approve rights instant-approves any amount', () {
      expect(
        ApprovalPolicy.canInstantApprove(
          canApprove: true, total: 50000, threshold: 1000, actorIsOwner: true),
        isTrue,
      );
    });

    test('approver instant-approves at/under threshold but routes above it', () {
      expect(
        ApprovalPolicy.canInstantApprove(
          canApprove: true, total: 1000, threshold: 1000, actorIsOwner: false),
        isTrue,
      );
      expect(
        ApprovalPolicy.canInstantApprove(
          canApprove: true, total: 1001, threshold: 1000, actorIsOwner: false),
        isFalse,
      );
    });
  });
}
