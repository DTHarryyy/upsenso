import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/dashboard/data/dashboard_data.dart';

class BranchComparisonCard extends StatelessWidget {
  final List<BranchStat> stats;
  const BranchComparisonCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxRevenue =
        stats.isEmpty ? 1.0 : stats.map((s) => s.totalRevenue).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.store_rounded,
                    size: 17, color: AppColors.brand),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Branch Comparison',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (stats.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${stats.length} branch${stats.length == 1 ? '' : 'es'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Content ──────────────────────────────────────
          if (stats.isEmpty)
            _EmptyState()
          else
            Column(
              children: stats
                  .take(5)
                  .map((s) => _BranchRow(stat: s, maxRevenue: maxRevenue))
                  .toList(),
            ),

          if (stats.isNotEmpty) ...[
            const SizedBox(height: 4),
            const Divider(height: 1, color: AppColors.borderSoft),
            const SizedBox(height: 12),

            // ── Footer summary ──────────────────────────────
            Row(
              children: [
                _SummaryChip(
                  label: 'Total Revenue',
                  value: _fmtRevenue(
                      stats.fold(0.0, (s, b) => s + b.totalRevenue)),
                  color: AppColors.brand,
                ),
                const SizedBox(width: 8),
                _SummaryChip(
                  label: 'Total Txns',
                  value:
                      stats.fold(0, (s, b) => s + b.txnCount).toString(),
                  color: AppColors.accent,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Branch row ───────────────────────────────────────────────────────────────

class _BranchRow extends StatelessWidget {
  final BranchStat stat;
  final double maxRevenue;

  const _BranchRow({required this.stat, required this.maxRevenue});

  @override
  Widget build(BuildContext context) {
    final fraction =
        maxRevenue > 0 ? (stat.totalRevenue / maxRevenue).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + badge + revenue
          Row(
            children: [
              // Branch initial avatar
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: stat.isTop
                      ? AppColors.brandSoft
                      : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _initial(stat.name),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: stat.isTop
                          ? AppColors.brand
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Name
              Expanded(
                child: Text(
                  stat.name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Top badge
              if (stat.isTop) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Top',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],

              const SizedBox(width: 8),

              // Revenue
              Text(
                '₱${_fmtRevenue(stat.totalRevenue)}',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          // Progress bar
          Row(
            children: [
              const SizedBox(width: 38), // aligns with text after avatar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 5,
                        backgroundColor: AppColors.surfaceAlt,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          stat.isTop ? AppColors.brand : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stat.txnCount} transaction${stat.txnCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initial(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    // Take up to 2 initials from words
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return clean[0].toUpperCase();
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.store_outlined,
                  size: 28, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            const Text(
              'No branch data yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sales data will appear here once\ntransactions are recorded.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary chip ─────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formatter ────────────────────────────────────────────────────────────────

String _fmtRevenue(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toStringAsFixed(0);
}
