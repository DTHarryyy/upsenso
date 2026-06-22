import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';

/// Guards the comparison rule behind AuthBloc's tenant self-heal: a device's
/// cached business_id can go stale if the business is deleted/recreated
/// server-side (e.g. a test-data purge) while the device was offline. This is
/// the check that decides whether the device must wipe local data and
/// re-sync against the server-resolved tenant.
void main() {
  group('businessContextChanged', () {
    test('false when cached and resolved match', () {
      expect(
        businessContextChanged(cached: 'biz-a', resolved: 'biz-a'),
        isFalse,
      );
    });

    test('true when the resolved business differs from cache', () {
      // The exact shape of the incident this guards: cache still points at a
      // business that was purged server-side and replaced with a new one.
      expect(
        businessContextChanged(cached: 'biz-OLD', resolved: 'biz-NEW'),
        isTrue,
      );
    });

    test('true when the resolved business is gone (now null)', () {
      expect(
        businessContextChanged(cached: 'biz-a', resolved: null),
        isTrue,
      );
    });

    test('true when a business appears where there was none cached', () {
      expect(
        businessContextChanged(cached: null, resolved: 'biz-a'),
        isTrue,
      );
    });

    test('false when both sides are null or blank — not a false positive', () {
      expect(businessContextChanged(cached: null, resolved: null), isFalse);
      expect(businessContextChanged(cached: '  ', resolved: null), isFalse);
      expect(businessContextChanged(cached: null, resolved: '   '), isFalse);
      expect(businessContextChanged(cached: '  ', resolved: '  '), isFalse);
    });
  });
}
