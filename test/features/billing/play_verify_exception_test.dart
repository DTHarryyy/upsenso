import 'package:flutter_test/flutter_test.dart';

import 'package:pos/features/billing/data/billing_remote_ds.dart';

/// The retry policy for a charged purchase is decided entirely by these three
/// getters, so each class has to stay distinguishable: retrying a permanent
/// refusal burns round trips, while treating our own misconfiguration as
/// transient leaves a paying user watching a retry that can never succeed.
void main() {
  group('PlayVerifyException classification', () {
    test('4xx is permanent and not a config fault', () {
      const e = PlayVerifyException(409, 'Subscription not active');
      expect(e.isPermanent, isTrue);
      expect(e.isConfigFault, isFalse);
    });

    test('a plain 5xx is transient — retrying can genuinely help', () {
      const e = PlayVerifyException(500, 'Verification could not complete',
          code: 'play_transient', stage: 'grant');
      expect(e.isPermanent, isFalse);
      expect(e.isConfigFault, isFalse);
    });

    test('play_config arrives as 5xx but must never be retried', () {
      const e = PlayVerifyException(500, 'Billing is temporarily misconfigured',
          code: 'play_config', stage: 'google_get_sub');
      expect(e.isPermanent, isFalse);
      expect(e.isConfigFault, isTrue);
    });

    test('a network failure (status 0) is transient', () {
      const e = PlayVerifyException(0, 'connection closed');
      expect(e.isPermanent, isFalse);
      expect(e.isConfigFault, isFalse);
    });

    test('toString carries the stage for support triage', () {
      const e = PlayVerifyException(500, 'boom',
          code: 'play_config', stage: 'google_token');
      expect(e.toString(), contains('google_token'));
      expect(e.toString(), contains('boom'));
    });
  });
}
