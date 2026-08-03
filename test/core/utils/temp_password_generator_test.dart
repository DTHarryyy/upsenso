import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/utils/temp_password_generator.dart';

void main() {
  group('generateTemporaryPassword', () {
    test('clears the server RPC\'s 8-char floor with room to spare', () {
      final password = generateTemporaryPassword(random: Random(1));
      final withoutDashes = password.replaceAll('-', '');
      expect(withoutDashes.length, 12);
      expect(password.length, greaterThanOrEqualTo(8));
    });

    test('excludes ambiguous glyphs that are easy to mistype', () {
      // A large sample from a fixed seed is deterministic and gives good
      // alphabet coverage without relying on Random.secure() in a unit test.
      final chars = List.generate(
        200,
        (i) => generateTemporaryPassword(random: Random(i)),
      ).join().replaceAll('-', '');

      for (final ambiguous in ['0', 'O', 'o', '1', 'l', 'I']) {
        expect(
          chars.contains(ambiguous),
          isFalse,
          reason: '"$ambiguous" should never appear in a generated password',
        );
      }
    });

    test('is grouped into three dash-separated blocks of 4', () {
      final password = generateTemporaryPassword(random: Random(42));
      final parts = password.split('-');
      expect(parts.length, 3);
      for (final part in parts) {
        expect(part.length, 4);
      }
    });

    test('produces distinct passwords across many draws', () {
      final rng = Random.secure();
      final passwords = List.generate(
        1000,
        (_) => generateTemporaryPassword(random: rng),
      ).toSet();
      expect(passwords.length, 1000);
    });

    test('defaults to Random.secure() when none is provided', () {
      // Just confirm it runs without a supplied Random and yields well-formed
      // output — the two calls only need to *usually* differ.
      final a = generateTemporaryPassword();
      final b = generateTemporaryPassword();
      expect(a.replaceAll('-', ''), hasLength(12));
      expect(a == b, isFalse);
    });
  });
}
