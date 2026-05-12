import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/presentation/widgets/report_card.dart';

class InventoryHealthTab extends StatelessWidget {
  final ReportsData data;
  const InventoryHealthTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(children: [_InventoryTable(items: data.inventoryItems)]);
  }
}

// ─── Table ────────────────────────────────────────────────────────────────────

class _InventoryTable extends StatelessWidget {
  final List<InventoryStatusItem> items;
  const _InventoryTable({required this.items});

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Inventory Status',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (items.isNotEmpty)
                Text(
                  '${items.length} items',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Sticky header
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: const _TableHeader(),
          ),
          const SizedBox(height: 2),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No tracked inventory items',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else ...[
            ...List.generate(
              items.length,
              (i) => _InventoryRow(item: items[i], index: i),
            ),
            const SizedBox(height: 4),
            _TotalsRow(items: items),
          ],
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.textMuted,
      letterSpacing: 0.3,
    );
    return const Row(
      children: [
        Expanded(flex: 5, child: Text('PRODUCT', style: style)),
        Expanded(flex: 2, child: Text('STATUS', style: style)),
        Expanded(
            flex: 2,
            child: Text('STOCK', style: style, textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child: Text('AVG/DAY', style: style, textAlign: TextAlign.center)),
        Expanded(
            flex: 2,
            child:
                Text('DAYS LEFT', style: style, textAlign: TextAlign.center)),
        Expanded(flex: 3, child: Text('NOTES', style: style)),
      ],
    );
  }
}

class _InventoryRow extends StatelessWidget {
  final InventoryStatusItem item;
  final int index;
  const _InventoryRow({required this.item, required this.index});

  static Color _statusColor(InventoryStatusType s) => switch (s) {
        InventoryStatusType.low => AppColors.error,
        InventoryStatusType.warning => AppColors.warning,
        InventoryStatusType.ok => AppColors.success,
        InventoryStatusType.slowMoving => AppColors.brand,
      };

  static Color _statusBg(InventoryStatusType s) => switch (s) {
        InventoryStatusType.low => AppColors.errorSoft,
        InventoryStatusType.warning => AppColors.warningSoft,
        InventoryStatusType.ok => AppColors.successSoft,
        InventoryStatusType.slowMoving => AppColors.brandSoft,
      };

  @override
  Widget build(BuildContext context) {
    final daysText = item.daysLeft == null
        ? '∞'
        : item.daysLeft! > 999
            ? '999+'
            : item.daysLeft!.toStringAsFixed(1);

    return Container(
      color: index.isOdd ? const Color(0xFFF7F9FC) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              item.productName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _statusBg(item.status),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.status.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _statusColor(item.status),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.currentStock % 1 == 0
                  ? item.currentStock.toInt().toString()
                  : item.currentStock.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.avgDailySale < 0.01
                  ? '0'
                  : item.avgDailySale.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              daysText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              item.notes ?? '-',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  final List<InventoryStatusItem> items;
  const _TotalsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final totalStock = items.fold(0.0, (s, i) => s + i.currentStock);
    final lowCount = items.where((i) => i.status == InventoryStatusType.low).length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Row(
        children: [
          const Expanded(
            flex: 5,
            child: Text(
              'TOTALS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$lowCount low',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              totalStock % 1 == 0
                  ? totalStock.toInt().toString()
                  : totalStock.toStringAsFixed(1),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Expanded(flex: 2, child: SizedBox()),
          const Expanded(flex: 2, child: SizedBox()),
          const Expanded(flex: 3, child: SizedBox()),
        ],
      ),
    );
  }
}
