import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/const/qty_format.dart';
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
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(item: item),
          if (item.trackStock) ...[
            const SizedBox(height: 14),
            // Multi-branch keeps the chip wrap; single-location gets a
            // balanced metric strip so the card never looks half-empty.
            if (branches.isEmpty)
              _StockSummaryStrip(
                qty: item.totalStock,
                reorderLevel: item.reorderLevel,
                status: item.status,
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...branches.map((b) => _StockChip(
                        label: b.name,
                        qty: item.stockByBranch[b.id] ?? 0.0,
                        reorderLevel: item.reorderLevel,
                      )),
                  _StockChip(
                    label: 'Total',
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
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CardActionBtn(
                    label: 'Stock In',
                    icon: Icons.add_rounded,
                    color: AppColors.success,
                    bgColor: AppColors.successSoft,
                    onTap: () => onAdjust(item, true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CardActionBtn(
                    label: 'Stock Out',
                    icon: Icons.remove_rounded,
                    color: AppColors.error,
                    bgColor: AppColors.errorSoft,
                    onTap: () => onAdjust(item, false),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
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

// Header shared by the stacked layout: title block on the left, status on
// the right. SKU sits in a subtle pill so the code reads as metadata.
class _CardHeader extends StatelessWidget {
  final InventoryItem item;

  const _CardHeader({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: getOutfitStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              if (item.variantName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.variantName,
                  style: getOutfitStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
              if (item.sku != null) ...[
                const SizedBox(height: 6),
                _SkuPill(sku: item.sku!),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        StockStatusBadge(status: item.status),
      ],
    );
  }
}

class _SkuPill extends StatelessWidget {
  final String sku;

  const _SkuPill({required this.sku});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        sku,
        style: getOutfitStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// Balanced two-cell stat strip for single-location items. Fills the card
// width with the on-hand figure paired against the reorder threshold.
class _StockSummaryStrip extends StatelessWidget {
  final double qty;
  final int reorderLevel;
  final StockStatus status;

  const _StockSummaryStrip({
    required this.qty,
    required this.reorderLevel,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight gives the row a bounded height so the stretched cells
    // share the same height without an unbounded-constraint crash.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatBox(
              label: 'On hand',
              value: qtyLabel(qty),
              valueColor: _statusColor(status),
              emphasize: true,
            ),
          ),
          if (reorderLevel > 0) ...[
            const SizedBox(width: 10),
            Expanded(
              child: _StatBox(
                label: 'Reorder at',
                value: '$reorderLevel',
                valueColor: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool emphasize;

  const _StatBox({
    required this.label,
    required this.value,
    required this.valueColor,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: getOutfitStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: getOutfitStyle(
              fontSize: emphasize ? 22 : 18,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(StockStatus status) => switch (status) {
      StockStatus.inStock => AppColors.success,
      StockStatus.warning => AppColors.warning,
      StockStatus.lowStock => AppColors.error,
      _ => AppColors.textPrimary,
    };

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
                              qty: item.stockByBranch[b.id] ?? 0.0,
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
                        label: 'In',
                        icon: Icons.add_rounded,
                        color: AppColors.success,
                        bgColor: AppColors.successSoft,
                        onTap: () => onAdjust(item, true),
                        compact: true,
                      ),
                      const SizedBox(width: 6),
                      _CardActionBtn(
                        label: 'Out',
                        icon: Icons.remove_rounded,
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
  final double qty;
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
            qtyLabel(qty),
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
  final IconData? icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  final bool compact;

  const _CardActionBtn({
    required this.label,
    this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 7 : 10,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: compact ? 15 : 17, color: color),
              SizedBox(width: compact ? 4 : 6),
            ],
            Text(
              label,
              style: getOutfitStyle(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
