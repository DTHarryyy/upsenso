import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/utils/formatters.dart';

void main() {
  group('AppFormatters.shortRef', () {
    test('derives an EXP code from the UUID tail', () {
      expect(
        AppFormatters.shortRef('e77fc7d0-ec05-4bad-b7c9-16f023767c68'),
        'EXP-767C68',
      );
    });

    test('honours a custom prefix', () {
      expect(
        AppFormatters.shortRef('e77fc7d0-ec05-4bad-b7c9-16f023767c68',
            prefix: 'PO'),
        'PO-767C68',
      );
    });

    test('falls back to the whole id when shorter than 6 chars', () {
      expect(AppFormatters.shortRef('ab12'), 'EXP-AB12');
    });

    test('handles an empty id', () {
      expect(AppFormatters.shortRef(''), 'EXP-');
    });
  });
}
