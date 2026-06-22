import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/sync/sync_service.dart';

/// Guards the detection rule behind the tenant self-heal: syncAll() scans
/// each push's stringified errors for a Postgres 42501 (RLS) rejection — the
/// signature of a stale active business_id — and hands off to AuthBloc to
/// re-resolve identity and wipe the orphaned local data.
void main() {
  group('containsTenantRejection', () {
    test('false for an empty error list', () {
      expect(containsTenantRejection([]), isFalse);
    });

    test('false when errors are unrelated to RLS', () {
      expect(
        containsTenantRejection([
          'Category Rice: PostgrestException(message: connection closed, code: null, details: null, hint: null)',
        ]),
        isFalse,
      );
    });

    test('true when a PostgrestException carries code 42501', () {
      expect(
        containsTenantRejection([
          'Category Rice: PostgrestException(message: new row violates row-level security policy, code: 42501, details: null, hint: null)',
        ]),
        isTrue,
      );
    });

    test('true when only one of several errors is a 42501', () {
      expect(
        containsTenantRejection([
          'Variant X: PostgrestException(message: duplicate key, code: 23505, details: null, hint: null)',
          'Product Y: PostgrestException(message: denied, code: 42501, details: null, hint: null)',
        ]),
        isTrue,
      );
    });
  });
}
