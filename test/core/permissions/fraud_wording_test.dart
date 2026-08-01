import 'package:flutter_test/flutter_test.dart';

import 'package:pos/core/permissions/app_feature.dart';
import 'package:pos/core/permissions/app_permission.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';

/// The naming split is deliberate and load-bearing in both directions: the UI
/// must never accuse anyone of fraud, and the wire values must never stop
/// saying it. Either half breaking silently is what this file exists to catch.
void main() {
  group('nothing a user reads says "fraud"', () {
    test('the feature label', () {
      expect(AppFeature.fraudAlerts.displayLabel, 'Unusual Activity');
    });

    test('the permission labels', () {
      expect(AppPermission.viewFraudAlerts.displayLabel, isNot(_saysFraud));
      expect(AppPermission.resolveFraudAlerts.displayLabel, isNot(_saysFraud));
    });

    // Derived by lower-casing the label — a rename that reads fine in title
    // case can still land badly here.
    test('the derived denial messages', () {
      expect(AppFeature.fraudAlerts.deniedMessage, isNot(_saysFraud));
      expect(AppPermission.viewFraudAlerts.deniedMessage, isNot(_saysFraud));
      expect(
        AppFeature.fraudAlerts.deniedMessage,
        contains('unusual activity'),
      );
    });

    test('the audit-log action chips', () {
      expect(AuditLogActionType.fraudFlagRaised.displayLabel, isNot(_saysFraud));
      expect(
        AuditLogActionType.fraudFlagResolved.displayLabel,
        isNot(_saysFraud),
      );
    });
  });

  // The other half of the split. These cross the wire — the permission codes
  // are evaluated by RLS on `fraud_flags`, and the action types are hashed into
  // the tamper-evident audit chain, so renaming them breaks verification of
  // every historic row. A find-and-replace "tidying up" the mismatch above is
  // exactly the accident this guards.
  group('everything on the wire still says "fraud"', () {
    test('permission codes', () {
      expect(PermissionKeys.fraudView, 'fraud.view');
      expect(PermissionKeys.fraudResolve, 'fraud.resolve');
      expect(PermissionKeys.navFraud, 'nav.fraud');
      expect(AppPermission.viewFraudAlerts.permissionKey, 'fraud.view');
      expect(AppPermission.resolveFraudAlerts.permissionKey, 'fraud.resolve');
    });

    test('hash-chained audit action types', () {
      expect(AuditLogActionType.fraudFlagRaised.value, 'FRAUD_FLAG_RAISED');
      expect(AuditLogActionType.fraudFlagResolved.value, 'FRAUD_FLAG_RESOLVED');
    });
  });
}

final _saysFraud = contains('fraud');
