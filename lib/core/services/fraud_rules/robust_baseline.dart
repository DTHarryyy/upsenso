import 'dart:math' as math;

/// Median/MAD statistics over historical samples — the self-calibrating
/// alternative to fixed thresholds. A knowledgeable insider can structure
/// under a published number forever; they can't easily stay under "your own
/// and your peers' normal", which shifts as they push it.
///
/// Deliberately not ML: two robust statistics, fully deterministic, and the
/// evidence they produce reads like "₱4,200 today vs median ₱600".
class RobustBaseline {
  final double median;

  /// Median absolute deviation — robust spread (outliers barely move it).
  final double mad;
  final int sampleCount;

  const RobustBaseline({
    required this.median,
    required this.mad,
    required this.sampleCount,
  });

  static RobustBaseline fromSamples(List<double> samples) {
    if (samples.isEmpty) {
      return const RobustBaseline(median: 0, mad: 0, sampleCount: 0);
    }
    final sorted = [...samples]..sort();
    final med = _median(sorted);
    final deviations = [for (final s in sorted) (s - med).abs()]..sort();
    return RobustBaseline(
      median: med,
      mad: _median(deviations),
      sampleCount: samples.length,
    );
  }

  /// Anomaly threshold: median + k·spread. A zero MAD (flat history — e.g.
  /// an employee whose every day was 0 refunds) would make ANY activity
  /// anomalous, so the spread is floored by [minSpread] and by a fraction of
  /// the median.
  double thresholdFor({required double k, required double minSpread}) {
    final spread = math.max(mad, math.max(median * 0.25, minSpread));
    return median + k * spread;
  }

  bool isAnomalous(
    double value, {
    required double k,
    required double minSpread,
    required int minSamples,
  }) {
    if (sampleCount < minSamples) return false;
    return value > thresholdFor(k: k, minSpread: minSpread);
  }

  static double _median(List<double> sorted) {
    final n = sorted.length;
    if (n == 0) return 0;
    final mid = n ~/ 2;
    return n.isOdd ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
  }
}
