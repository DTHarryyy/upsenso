import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';

// Guards the audit serialization contract: the local row stores `value`, and
// reads map it back with fromValue. A duplicate or renamed code would silently
// resolve to the wrong action (or the syncStarted fallback) in the audit page.
void main() {
  test('every action type round-trips through value/fromValue', () {
    for (final type in AuditLogActionType.values) {
      expect(AuditLogActionTypeX.fromValue(type.value), type,
          reason: '${type.name} did not round-trip');
    }
  });

  test('all action codes are unique', () {
    final codes = AuditLogActionType.values.map((t) => t.value).toList();
    expect(codes.toSet().length, codes.length, reason: 'duplicate action code');
  });

  test('every action type has a display label', () {
    for (final type in AuditLogActionType.values) {
      expect(type.displayLabel.trim(), isNotEmpty, reason: type.name);
    }
  });
}
