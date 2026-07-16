import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/services/fraud_rules/robust_baseline.dart';

void main() {
  group('RobustBaseline', () {
    test('computes median and MAD', () {
      final b = RobustBaseline.fromSamples([100, 200, 300, 400, 500]);
      expect(b.median, 300);
      expect(b.mad, 100); // deviations 200,100,0,100,200 → median 100
      expect(b.sampleCount, 5);
    });

    test('even sample count averages the middle pair', () {
      final b = RobustBaseline.fromSamples([100, 200, 300, 400]);
      expect(b.median, 250);
    });

    test('cold start: below minSamples nothing is anomalous', () {
      final b = RobustBaseline.fromSamples([10, 10, 10]);
      expect(
        b.isAnomalous(1000000, k: 4, minSpread: 500, minSamples: 14),
        isFalse,
      );
    });

    test('outliers barely move the threshold (robustness)', () {
      final samples = [
        ...List.filled(20, 500.0),
        50000.0, // one wild historical day must not desensitize detection
      ];
      final b = RobustBaseline.fromSamples(samples);
      expect(b.median, 500);
      expect(
        b.isAnomalous(5000, k: 4, minSpread: 500, minSamples: 14),
        isTrue,
      );
    });

    test('zero MAD (flat history) uses the spread floor, not zero', () {
      // 20 identical days: mad == 0. Without the floor, value 501 would flag.
      final b = RobustBaseline.fromSamples(List.filled(20, 500.0));
      expect(b.mad, 0);
      expect(
        b.isAnomalous(600, k: 4, minSpread: 500, minSamples: 14),
        isFalse,
      );
      expect(
        b.isAnomalous(3000, k: 4, minSpread: 500, minSamples: 14),
        isTrue,
      );
    });

    test('empty samples are safe', () {
      final b = RobustBaseline.fromSamples([]);
      expect(b.median, 0);
      expect(
        b.isAnomalous(100, k: 4, minSpread: 1, minSamples: 1),
        isFalse,
      );
    });
  });
}
