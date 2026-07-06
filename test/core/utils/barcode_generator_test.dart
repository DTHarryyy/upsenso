import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/utils/barcode_generator.dart';

// Independent EAN-13 check-digit implementation to validate the generator.
int expectedCheckDigit(String first12) {
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    final d = int.parse(first12[i]);
    sum += d * (i.isEven ? 1 : 3);
  }
  final mod = sum % 10;
  return mod == 0 ? 0 : 10 - mod;
}

void main() {
  group('generateEan13', () {
    test('produces a 13-digit numeric string with an in-store prefix', () {
      final code = generateEan13(random: Random(1));
      expect(code.length, 13);
      expect(RegExp(r'^\d{13}$').hasMatch(code), isTrue);
      // GS1 restricted-distribution prefix: first digit is 2 (20–29 range).
      expect(code[0], '2');
    });

    test('appends a valid EAN-13 check digit', () {
      for (var seed = 0; seed < 500; seed++) {
        final code = generateEan13(random: Random(seed));
        final check = int.parse(code[12]);
        expect(check, expectedCheckDigit(code.substring(0, 12)),
            reason: 'bad check digit for $code');
      }
    });

    test('is highly unlikely to repeat across many draws', () {
      final rng = Random(42);
      final seen = <String>{};
      for (var i = 0; i < 1000; i++) {
        seen.add(generateEan13(random: rng));
      }
      expect(seen.length, 1000);
    });
  });
}
