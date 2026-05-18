import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/inventory/data/inventory_data.dart';
import 'package:pos/features/inventory/presentation/widgets/stock_status_badge.dart';

// Fixed column widths — the table scrolls horizontally when branches make it
// wider than the viewport, rather than squashing every column.
const double _colProduct = 180;
const double _colSku = 110;
const double _colBranch = 110;
const double _colTotal = 80;
const double _colReorder = 110;
const double _colStatus = 110;
const double _colActions = 140;

double _tableMinWidth(int branchCount) =>
    _colProduct +
    _colSku +
    (_colBranch * branchCount) +
    _colTotal +
    _colReorder +
    _colStatus +
    _colActions;

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
      return const _EmptyState();
    }

    final minWidth = _tableMinWidth(branches.length);

    // LayoutBuilder must be OUTSIDE the horizontal SingleChildScrollView.
    // Inside the scroll view, maxWidth is unbounded (infinity), which flows
    // into SizedBox(width: infinity) and crashes the layout engine.
    // Here the constraints come from the parent Column, which is always finite.
    return LayoutBuilder(
      builder: (context, constraints) {
        // constraints.maxWidth can be infinite if a parent has no width bound.
        // Fall back to minWidth so we always have a finite, renderable value.
        // Row padding (16 each side) is NOT part of minWidth, but is consumed
        // by the container — add it back so the SizedBox is large enough.
        const rowPadTotal = 16.0 * 2;
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : minWidth + rowPadTotal;
        // If the viewport is wide enough for content + padding, fill it.
        // Otherwise use minWidth + padding and let horizontal scroll take over.
        final tableWidth = availableWidth > (minWidth + rowPadTotal)
            ? availableWidth
            : minWidth + rowPadTotal;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSoft),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TableHeader(branches: branches, tableWidth: tableWidth),
                  const Divider(height: 1, color: AppColors.borderSoft),
                  Expanded(
                    child: ListView.separated(
                      physics: const ClampingScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (context, i) =>
                          const Divider(height: 1, color: AppColors.borderSoft),
                      itemBuilder: (_, i) => _TableRow(
                        item: items[i],
                        branches: branches,
                        onAdjust: onAdjust,
                        isEven: i.isEven,
                        tableWidth: tableWidth,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Column widths helper ─────────────────────────────────────────────────────

/// Returns the actual widths for all columns given the real [tableWidth].
/// Extra space (when table is wider than minWidth) is distributed to Product
/// and branch columns proportionally, so the layout breathes on large screens.
List<double> _columnWidths(int branchCount, double tableWidth) {
  final min = _tableMinWidth(branchCount);
  final extra = (tableWidth - min).clamp(0.0, double.infinity);

  // Distribute extra space: 40% to Product, 60% split equally among branches
  final productExtra = extra * 0.4;
  final branchExtra = branchCount > 0 ? (extra * 0.6) / branchCount : 0.0;

  return [
    _colProduct + productExtra, // Product
    _colSku, // SKU
    for (var i = 0; i < branchCount; i++) _colBranch + branchExtra, // branches
    _colTotal, // Total
    _colReorder, // Reorder
    _colStatus, // Status
    _colActions, // Actions
  ];
}

// ── Header ───────────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final List<BranchInfo> branches;
  final double tableWidth;

  const _TableHeader({required this.branches, required this.tableWidth});

  // Horizontal padding applied to each row — must be subtracted before
  // computing column widths so columns don't exceed the available inner width.
  static const double _rowPadH = 16;

  @override
  Widget build(BuildContext context) {
    final widths = _columnWidths(branches.length, tableWidth - _rowPadH * 2);
    final labels = [
      'Product',
      'SKU',
      ...branches.map((b) => b.name),
      'Total',
      'Reorder Level',
      'Status',
      'Actions',
    ];

    return Container(
      color: AppColors.surfaceAlt,
      padding: const EdgeInsets.symmetric(horizontal: _rowPadH, vertical: 11),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            SizedBox(
              width: widths[i],
              child: Text(
                labels[i],
                textAlign: i == labels.length - 1
                    ? TextAlign.right
                    : TextAlign.left,
                overflow: TextOverflow.ellipsis,
                style: getOutfitStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Row ──────────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  final InventoryItem item;
  final List<BranchInfo> branches;
  final void Function(InventoryItem item, bool isIncoming) onAdjust;
  final bool isEven;
  final double tableWidth;

  const _TableRow({
    required this.item,
    required this.branches,
    required this.onAdjust,
    required this.isEven,
    required this.tableWidth,
  });

  Color _stockColor(int qty, int reorder) {
    if (reorder <= 0) return qty <= 0 ? AppColors.error : AppColors.textPrimary;
    if (qty <= reorder) return AppColors.error;
    if (qty <= (reorder * 1.5).ceil()) return AppColors.warning;
    return AppColors.textPrimary;
  }

  static const double _rowPadH = 16;

  @override
  Widget build(BuildContext context) {
    final widths = _columnWidths(branches.length, tableWidth - _rowPadH * 2);
    var colIdx = 0;

    Widget cell(Widget child) =>
        SizedBox(width: widths[colIdx++], child: child);

    return Container(
      color: isEven
          ? Colors.transparent
          : AppColors.surfaceAlt.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(horizontal: _rowPadH, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product
          cell(
            Column(
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
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          // SKU
          cell(
            Text(
              item.sku ?? '—',
              overflow: TextOverflow.ellipsis,
              style: getOutfitStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          // Per-branch
          for (final b in branches)
            cell(() {
              if (!item.trackStock) {
                return Text(
                  '—',
                  style: getOutfitStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                );
              }
              final qty = item.stockByBranch[b.id] ?? 0;
              return Text(
                '$qty',
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _stockColor(qty, item.reorderLevel),
                ),
              );
            }()),
          // Total
          cell(
            Text(
              item.trackStock ? '${item.totalStock}' : '—',
              style: getOutfitStyle(
                fontSize: 13,
                fontWeight: item.trackStock ? FontWeight.w600 : FontWeight.w400,
                color: item.trackStock
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ),
          ),
          // Reorder
          cell(
            Text(
              (!item.trackStock || item.reorderLevel <= 0)
                  ? '—'
                  : '${item.reorderLevel}',
              style: getOutfitStyle(
                fontSize: 13,
                color: (item.trackStock && item.reorderLevel > 0)
                    ? AppColors.textSecondary
                    : AppColors.textMuted,
              ),
            ),
          ),
          // Status
          cell(
            Align(
              alignment: Alignment.centerLeft,
              child: StockStatusBadge(status: item.status),
            ),
          ),
          // Actions — hidden for untracked items
          cell(
            item.trackStock
                ? Row(
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
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

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

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(IconlyLight.category, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'No products found',
              style: getOutfitStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add products to start tracking inventory',
              style: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
