import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/inventory/data/inventory_data.dart';
import 'package:pos/features/inventory/presentation/widgets/stock_status_badge.dart';

/// Used on mobile (full card) and tablet (structured row inside card).
class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final List<BranchInfo> branches;
  final bool isTablet;
  final void Function(InventoryItem item, bool isIncoming) onAdjust;

  const InventoryItemCard({
    super.key,
    required this.item,
    required this.branches,
    required this.onAdjust,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: isTablet ? _TabletLayout(item: item, branches: branches, onAdjust: onAdjust)
                      : _MobileLayout(item: item, branches: branches, onAdjust: onAdjust),
    );
  }
}

// ── Mobile: stacked card layout ────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final InventoryItem item;
  final List<BranchInfo> branches;
  final void Function(InventoryItem, bool) onAdjust;

  const _MobileLayout({
    required this.item,
    required this.branches,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name + badge
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: getOutfitStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (item.variantName.isNotEmpty)
                      Text(item.variantName,
                          style: getOutfitStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    if (item.sku != null)
                      Text(item.sku!,
                          style: getOutfitStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              StockStatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 12),

          // Branch stock grid
          if (branches.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...branches.map((b) => _BranchChip(
                      label: b.name,
                      qty: item.stockByBranch[b.id] ?? 0,
                      reorderLevel: item.reorderLevel,
                    )),
                _BranchChip(
                  label: 'Total',
                  qty: item.totalStock,
                  reorderLevel: item.reorderLevel,
                  isTotal: true,
                ),
              ],
            )
          else
            _BranchChip(
              label: 'Total Stock',
              qty: item.totalStock,
              reorderLevel: item.reorderLevel,
              isTotal: true,
            ),

          const SizedBox(height: 8),
          if (item.reorderLevel > 0)
            Text(
              'Reorder at: ${item.reorderLevel}',
              style: getOutfitStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _MobileActionBtn(
                  label: '+ Stock In',
                  color: AppColors.success,
                  bgColor: AppColors.successSoft,
                  onTap: () => onAdjust(item, true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MobileActionBtn(
                  label: '− Stock Out',
                  color: AppColors.error,
                  bgColor: AppColors.errorSoft,
                  onTap: () => onAdjust(item, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tablet: horizontal row inside a card ───────────────────────────────────

class _TabletLayout extends StatelessWidget {
  final InventoryItem item;
  final List<BranchInfo> branches;
  final void Function(InventoryItem, bool) onAdjust;

  const _TabletLayout({
    required this.item,
    required this.branches,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Product info
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
                  Text(item.variantName,
                      style: getOutfitStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                if (item.sku != null)
                  Text(item.sku!,
                      style: getOutfitStyle(
                          fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          // Branch stock inline
          Expanded(
            flex: 4,
            child: Wrap(
              spacing: 8,
              children: [
                ...branches.map((b) => _BranchChip(
                      label: b.name,
                      qty: item.stockByBranch[b.id] ?? 0,
                      reorderLevel: item.reorderLevel,
                    )),
                _BranchChip(
                  label: 'Total',
                  qty: item.totalStock,
                  reorderLevel: item.reorderLevel,
                  isTotal: true,
                ),
              ],
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Center(child: StockStatusBadge(status: item.status)),
          ),
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _MobileActionBtn(
                  label: '+ In',
                  color: AppColors.success,
                  bgColor: AppColors.successSoft,
                  onTap: () => onAdjust(item, true),
                  compact: true,
                ),
                const SizedBox(width: 6),
                _MobileActionBtn(
                  label: '− Out',
                  color: AppColors.error,
                  bgColor: AppColors.errorSoft,
                  onTap: () => onAdjust(item, false),
                  compact: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ──────────────────────────────────────────────────────

class _BranchChip extends StatelessWidget {
  final String label;
  final int qty;
  final int reorderLevel;
  final bool isTotal;

  const _BranchChip({
    required this.label,
    required this.qty,
    required this.reorderLevel,
    this.isTotal = false,
  });

  Color get _qtyColor {
    if (reorderLevel <= 0) return qty <= 0 ? AppColors.error : AppColors.textPrimary;
    if (qty <= reorderLevel) return AppColors.error;
    if (qty <= (reorderLevel * 1.5).ceil()) return AppColors.warning;
    return AppColors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isTotal ? AppColors.brandSoft : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTotal ? AppColors.brand.withValues(alpha: 0.3) : AppColors.borderSoft,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: getOutfitStyle(
              fontSize: 10,
              color: isTotal ? AppColors.brand : AppColors.textSecondary,
            ),
          ),
          Text(
            '$qty',
            style: getOutfitStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isTotal ? AppColors.brand : _qtyColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  final bool compact;

  const _MobileActionBtn({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 6 : 9,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: getOutfitStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
