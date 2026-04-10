import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/inventory/data/inventory_data.dart';
import 'package:pos/features/inventory/presentation/widgets/stock_status_badge.dart';

/// Self-adapting inventory card.
/// Uses its own [LayoutBuilder] to switch between a compact horizontal layout
/// (≥ 520 logical pixels wide) and a stacked mobile layout (< 520).
/// No `isTablet` flag required — the card decides based on its own width.
class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final List<BranchInfo> branches;
  final void Function(InventoryItem item, bool isIncoming) onAdjust;

  const InventoryItemCard({
    super.key,
    required this.item,
    required this.branches,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return constraints.maxWidth >= 520
              ? _HorizontalLayout(
                  item: item, branches: branches, onAdjust: onAdjust)
              : _StackedLayout(
                  item: item, branches: branches, onAdjust: onAdjust);
        },
      ),
    );
  }
}

// ── Stacked (mobile) layout ──────────────────────────────────────────────────

class _StackedLayout extends StatelessWidget {
  final InventoryItem item;
  final List<BranchInfo> branches;
  final void Function(InventoryItem, bool) onAdjust;

  const _StackedLayout({
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
          // Name + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      Text(
                        item.variantName,
                        style: getOutfitStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    if (item.sku != null)
                      Text(
                        item.sku!,
                        style: getOutfitStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StockStatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 12),

          // Stock chips — wraps naturally; hidden for untracked items
          if (item.trackStock) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (branches.isNotEmpty)
                  ...branches.map((b) => _StockChip(
                        label: b.name,
                        qty: item.stockByBranch[b.id] ?? 0,
                        reorderLevel: item.reorderLevel,
                      )),
                _StockChip(
                  label: branches.isNotEmpty ? 'Total' : 'Stock',
                  qty: item.totalStock,
                  reorderLevel: item.reorderLevel,
                  isHighlighted: true,
                ),
              ],
            ),
            if (item.reorderLevel > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Reorder at ${item.reorderLevel}',
                style: getOutfitStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            // Action buttons full-width
            Row(
              children: [
                Expanded(
                  child: _CardActionBtn(
                    label: '+ Stock In',
                    color: AppColors.success,
                    bgColor: AppColors.successSoft,
                    onTap: () => onAdjust(item, true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CardActionBtn(
                    label: '− Stock Out',
                    color: AppColors.error,
                    bgColor: AppColors.errorSoft,
                    onTap: () => onAdjust(item, false),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Stock tracking is disabled for this product.',
              style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Horizontal (tablet) layout ───────────────────────────────────────────────

class _HorizontalLayout extends StatelessWidget {
  final InventoryItem item;
  final List<BranchInfo> branches;
  final void Function(InventoryItem, bool) onAdjust;

  const _HorizontalLayout({
    required this.item,
    required this.branches,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product info — 30% of card width
          Expanded(
            flex: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.productName,
                  overflow: TextOverflow.ellipsis,
                  style: getOutfitStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.variantName.isNotEmpty)
                  Text(
                    item.variantName,
                    overflow: TextOverflow.ellipsis,
                    style: getOutfitStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                if (item.sku != null)
                  Text(
                    item.sku!,
                    overflow: TextOverflow.ellipsis,
                    style: getOutfitStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Stock chips — 35% of card width, wrap naturally
          Expanded(
            flex: 35,
            child: item.trackStock
                ? Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (branches.isNotEmpty)
                        ...branches.map((b) => _StockChip(
                              label: b.name,
                              qty: item.stockByBranch[b.id] ?? 0,
                              reorderLevel: item.reorderLevel,
                            )),
                      _StockChip(
                        label: branches.isNotEmpty ? 'Total' : 'Stock',
                        qty: item.totalStock,
                        reorderLevel: item.reorderLevel,
                        isHighlighted: true,
                      ),
                    ],
                  )
                : Text(
                    'Not tracked',
                    style: getOutfitStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
          ),
          const SizedBox(width: 12),

          // Status badge — 15%
          Expanded(
            flex: 15,
            child: Center(child: StockStatusBadge(status: item.status)),
          ),
          const SizedBox(width: 8),

          // Action buttons — 20% (hidden for untracked items)
          Expanded(
            flex: 20,
            child: item.trackStock
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _CardActionBtn(
                        label: '+ In',
                        color: AppColors.success,
                        bgColor: AppColors.successSoft,
                        onTap: () => onAdjust(item, true),
                        compact: true,
                      ),
                      const SizedBox(width: 6),
                      _CardActionBtn(
                        label: '− Out',
                        color: AppColors.error,
                        bgColor: AppColors.errorSoft,
                        onTap: () => onAdjust(item, false),
                        compact: true,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ───────────────────────────────────────────────────────────

class _StockChip extends StatelessWidget {
  final String label;
  final int qty;
  final int reorderLevel;
  final bool isHighlighted;

  const _StockChip({
    required this.label,
    required this.qty,
    required this.reorderLevel,
    this.isHighlighted = false,
  });

  Color get _qtyColor {
    if (isHighlighted) return AppColors.brand;
    if (reorderLevel <= 0) {
      return qty <= 0 ? AppColors.error : AppColors.textPrimary;
    }
    if (qty <= reorderLevel) return AppColors.error;
    if (qty <= (reorderLevel * 1.5).ceil()) return AppColors.warning;
    return AppColors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.brandSoft : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted
              ? AppColors.brand.withValues(alpha: 0.25)
              : AppColors.borderSoft,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: getOutfitStyle(
              fontSize: 10,
              color: isHighlighted
                  ? AppColors.brand
                  : AppColors.textSecondary,
            ),
          ),
          Text(
            '$qty',
            style: getOutfitStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _qtyColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  final bool compact;

  const _CardActionBtn({
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
          vertical: compact ? 7 : 10,
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
