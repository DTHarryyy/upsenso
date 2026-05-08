import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/presentation/widgets/report_card.dart';

// ─── Inventory Health tab ─────────────────────────────────────────────────────

class InventoryHealthTab extends StatelessWidget {
  final ReportsData data;
  const InventoryHealthTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(children: [_InventoryTable(items: data.inventoryItems)]);
  }
}

// ─── Inventory status table ───────────────────────────────────────────────────

class _InventoryTable extends StatelessWidget {
  final List<InventoryStatusItem> items;
  const _InventoryTable({required this.items});

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inventory Status',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const _TableHeader(),
          const Divider(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: 4),
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
          else
            ...items.map((item) => _InventoryRow(item: item)),
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
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text('PRODUCT', style: style)),
          Expanded(flex: 2, child: Text('STATUS', style: style)),
          Expanded(
            flex: 2,
            child: Text('STOCK', style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('AVG/DAY', style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('DAYS LEFT', style: style, textAlign: TextAlign.center),
          ),
          Expanded(flex: 3, child: Text('NOTES', style: style)),
        ],
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  final InventoryStatusItem item;
  const _InventoryRow({required this.item});

  static Color _statusColor(InventoryStatusType s) {
    switch (s) {
      case InventoryStatusType.low:
        return AppColors.error;
      case InventoryStatusType.warning:
        return AppColors.warning;
      case InventoryStatusType.ok:
        return AppColors.success;
      case InventoryStatusType.slowMoving:
        return AppColors.brand;
    }
  }

  static Color _statusBg(InventoryStatusType s) {
    switch (s) {
      case InventoryStatusType.low:
        return AppColors.errorSoft;
      case InventoryStatusType.warning:
        return AppColors.warningSoft;
      case InventoryStatusType.ok:
        return AppColors.successSoft;
      case InventoryStatusType.slowMoving:
        return AppColors.brandSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysText = item.daysLeft == null
        ? '∞'
        : item.daysLeft! > 999
        ? '999+'
        : item.daysLeft!.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
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
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              daysText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              item.notes ?? '-',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
