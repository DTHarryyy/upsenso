import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/widgets/app_bottom_sheet_scaffold.dart';
import 'package:pos/core/widgets/app_data_table.dart';
import 'package:pos/core/widgets/app_modal.dart';
import 'package:pos/features/reports/presentation/widgets/report_card.dart';
import 'package:pos/features/reports/presentation/widgets/report_ranked_list.dart';

/// Full revenue breakdown (every product or category) behind the "View all"
/// action on a [ReportRankedListCard]. Adapts to a bottom sheet on phones and
/// a centred dialog on larger screens via [showAppModal].
class SalesBreakdownSheet extends StatelessWidget {
  final String title;
  final String nameColumnLabel;
  final List<RankedRevenueItem> items;

  const SalesBreakdownSheet({
    super.key,
    required this.title,
    required this.nameColumnLabel,
    required this.items,
  });

  static const _palette = AppColors.chartPalette;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String nameColumnLabel,
    required List<RankedRevenueItem> items,
  }) {
    return showAppModal<void>(
      context: context,
      builder: (_) => SalesBreakdownSheet(
        title: title,
        nameColumnLabel: nameColumnLabel,
        items: items,
      ),
    );
  }

  // Products carry a "sold" subtitle; categories don't. Drives the Qty column.
  bool get _hasQty => items.any((i) => i.subtitle != null);

  List<AppTableColumn> get _columns => [
    const AppTableColumn(label: '#', width: 36),
    AppTableColumn(label: nameColumnLabel, flex: 5),
    if (_hasQty)
      const AppTableColumn(label: 'Qty', flex: 2, align: TextAlign.right),
    const AppTableColumn(label: 'Revenue', flex: 3, align: TextAlign.right),
    const AppTableColumn(label: 'Share', flex: 2, align: TextAlign.right),
  ];

  @override
  Widget build(BuildContext context) {
    final total = items.fold(0.0, (s, i) => s + i.value);

    return AppBottomSheetScaffold(
      title: title,
      titleTrailing: _CountBadge(count: items.length),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppDataTable(
              columns: _columns,
              rowCount: items.length,
              rowCellsBuilder: (ctx, i) => _rowCells(ctx, i),
            ),
            const SizedBox(height: 10),
            _TotalsBar(total: total, hasQty: _hasQty),
          ],
        ),
      ),
    );
  }

  List<Widget> _rowCells(BuildContext ctx, int i) {
    final item = items[i];
    final pct = (item.share * 100).toStringAsFixed(1);
    return [
      Text(
        '${i + 1}',
        style: AppTextStyles.caption(
          ctx,
        ).copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w700),
      ),
      Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _palette[i % _palette.length],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              item.name,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(ctx).copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      if (_hasQty)
        Text(
          item.subtitle?.replaceAll(' sold', '') ?? '—',
          style: AppTextStyles.body(ctx).copyWith(color: AppColors.textPrimary),
        ),
      Text(
        fmtCurrency(item.value),
        style: AppTextStyles.body(ctx).copyWith(color: AppColors.textPrimary),
      ),
      Text(
        '$pct%',
        style: AppTextStyles.caption(ctx).copyWith(color: AppColors.textMuted),
      ),
    ];
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.caption(
          context,
        ).copyWith(color: AppColors.brand, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// Brand-tinted totals strip matching the on-screen report tables.
class _TotalsBar extends StatelessWidget {
  final double total;
  final bool hasQty;
  const _TotalsBar({required this.total, required this.hasQty});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'TOTAL',
              style: AppTextStyles.caption(context).copyWith(
                color: AppColors.brand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            fmtCurrency(total),
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '100%',
            style: AppTextStyles.caption(context).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
