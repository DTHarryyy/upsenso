import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/inventory/data/inventory_data.dart';
import 'package:pos/features/inventory/presentation/widgets/stock_status_badge.dart';

class InventoryDesktopTable extends StatelessWidget {
  final List<InventoryItem> items;
  final List<BranchInfo> branches;
  final void Function(InventoryItem item, bool isIncoming) onAdjust;

  const InventoryDesktopTable({
    super.key,
    required this.items,
    required this.branches,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          _TableHeader(branches: branches),
          const Divider(height: 1, color: AppColors.borderSoft),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, i) =>
                const Divider(height: 1, color: AppColors.borderSoft),
            itemBuilder: (_, i) => _TableRow(
              item: items[i],
              branches: branches,
              onAdjust: onAdjust,
              isEven: i.isEven,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final List<BranchInfo> branches;
  const _TableHeader({required this.branches});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _HeaderCell('Product', flex: 3),
          _HeaderCell('SKU', flex: 2),
          ...branches.map((b) => _HeaderCell(b.name, flex: 2)),
          _HeaderCell('Total', flex: 1),
          _HeaderCell('Reorder Level', flex: 2),
          _HeaderCell('Status', flex: 2),
          _HeaderCell('Actions', flex: 2, align: TextAlign.right),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;

  const _HeaderCell(this.text, {this.flex = 1, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: getOutfitStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final InventoryItem item;
  final List<BranchInfo> branches;
  final void Function(InventoryItem item, bool isIncoming) onAdjust;
  final bool isEven;

  const _TableRow({
    required this.item,
    required this.branches,
    required this.onAdjust,
    required this.isEven,
  });

  Color _stockColor(int qty, int reorder) {
    if (reorder <= 0) return qty <= 0 ? AppColors.error : AppColors.textPrimary;
    if (qty <= reorder) return AppColors.error;
    if (qty <= (reorder * 1.5).ceil()) return AppColors.warning;
    return AppColors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isEven ? Colors.transparent : AppColors.surfaceAlt.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Product name + variant
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: getOutfitStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.variantName.isNotEmpty)
                  Text(
                    item.variantName,
                    style: getOutfitStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          // SKU
          Expanded(
            flex: 2,
            child: Text(
              item.sku ?? '—',
              style: getOutfitStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          // Per-branch stock
          ...branches.map((b) {
            final qty = item.stockByBranch[b.id] ?? 0;
            final color = _stockColor(qty, item.reorderLevel);
            return Expanded(
              flex: 2,
              child: Text(
                '$qty',
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            );
          }),
          // Total
          Expanded(
            flex: 1,
            child: Text(
              '${item.totalStock}',
              style: getOutfitStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Reorder level
          Expanded(
            flex: 2,
            child: Text(
              item.reorderLevel > 0 ? '${item.reorderLevel}' : '—',
              style: getOutfitStyle(
                fontSize: 13,
                color: item.reorderLevel > 0
                    ? AppColors.textSecondary
                    : AppColors.textMuted,
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: StockStatusBadge(status: item.status),
          ),
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(
                  label: '+ In',
                  color: AppColors.success,
                  bgColor: AppColors.successSoft,
                  onTap: () => onAdjust(item, true),
                ),
                const SizedBox(width: 6),
                _ActionButton(
                  label: '− Out',
                  color: AppColors.error,
                  bgColor: AppColors.errorSoft,
                  onTap: () => onAdjust(item, false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: getOutfitStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'No products found',
              style: getOutfitStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Add products to start tracking inventory',
              style: getOutfitStyle(
                  fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
