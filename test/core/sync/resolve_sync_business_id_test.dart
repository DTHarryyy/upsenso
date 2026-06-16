import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/sync/sync_service.dart';

/// Guards the security-critical rule that a background/connectivity sync can
/// NEVER pull a tenant other than the active one — the core of the cross-account
/// data-leak fix.
void main() {
  group('resolveSyncBusinessId', () {
    test('uses the provided businessId when no session is active', () {
      expect(resolveSyncBusinessId(provided: 'biz-a', active: null), 'biz-a');
    });

    test('falls back to the active business when none is provided', () {
      expect(resolveSyncBusinessId(provided: null, active: 'biz-a'), 'biz-a');
    });

    test('returns null when nothing is available → pull is skipped', () {
      expect(resolveSyncBusinessId(provided: null, active: null), isNull);
      expect(resolveSyncBusinessId(provided: '  ', active: '  '), isNull);
    });

    test('rejects a provided id that differs from the active tenant', () {
      // A stale businessId queued before an account switch must not be pulled.
      expect(
        resolveSyncBusinessId(provided: 'biz-PREVIOUS', active: 'biz-CURRENT'),
        isNull,
      );
    });

    test('allows a provided id that matches the active tenant', () {
      expect(
        resolveSyncBusinessId(provided: 'biz-a', active: 'biz-a'),
        'biz-a',
      );
    });

    test('blank provided id falls back to the active tenant', () {
      expect(resolveSyncBusinessId(provided: '   ', active: 'biz-a'), 'biz-a');
    });

    test('blank active is treated as no active tenant', () {
      // No real active business → a provided id is accepted (initial login pull).
      expect(resolveSyncBusinessId(provided: 'biz-a', active: '  '), 'biz-a');
    });
  });
}
