import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/const/qty_format.dart';
import 'package:pos/features/products/domain/entities/product.dart';
import 'package:pos/features/products/domain/entities/product_variant.dart';
import 'package:pos/core/widgets/app_filled_button.dart';

void showProductSelectionSheet(
  BuildContext context, {
  required Product product,
  required List<ProductVariant> variants,
  Map<String, double> variantStock = const {},
  void Function(ProductVariant variant, double quantity)? onConfirm,
  VoidCallback? onEdit,
}) {
  if (Breakpoints.isTablet(context)) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _ProductSelectionSheet(
              product: product,
              variants: variants,
              variantStock: variantStock,
              onConfirm: onConfirm,
              onEdit: onEdit,
              isDialog: true,
            ),
          ),
        ),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      // Root navigator: this page's tab lives in a StatefulShellRoute branch
      // Navigator, which is confined to the body area below the outer shell's
      // AI assistant FAB. Without this, the sheet renders behind the FAB
      // instead of covering the whole screen.
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductSelectionSheet(
        product: product,
        variants: variants,
        variantStock: variantStock,
        onConfirm: onConfirm,
        onEdit: onEdit,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProductSelectionSheet extends StatefulWidget {
  final Product product;
  final List<ProductVariant> variants;
  final Map<String, double> variantStock;
  final void Function(ProductVariant, double)? onConfirm;
  final VoidCallback? onEdit;
  final bool isDialog;

  const _ProductSelectionSheet({
    required this.product,
    required this.variants,
    this.variantStock = const {},
    this.onConfirm,
    this.onEdit,
    this.isDialog = false,
  });

  @override
  State<_ProductSelectionSheet> createState() => _ProductSelectionSheetState();
}

class _ProductSelectionSheetState extends State<_ProductSelectionSheet> {
  ProductVariant? _selected;
  double _qty = 1;

  bool get _isFraction => widget.product.sellBy == 'fraction';

  /// Unit label (kg/g/L/ml) for weighed products, else null.
  String? get _unit {
    if (!_isFraction) return null;
    final u = _selected?.unit ?? (_active.isEmpty ? null : _active.first.unit);
    return (u != null && u.isNotEmpty) ? u : null;
  }

  List<ProductVariant> get _active =>
      widget.variants.where((v) => v.isActive).toList();

  @override
  void initState() {
    super.initState();
    final active = _active;
    // Auto-select for simple products or when only one active variant exists
    if (!widget.product.hasVariants && active.isNotEmpty) {
      _selected = active.first;
    } else if (widget.product.hasVariants && active.length == 1) {
      _selected = active.first;
    }
  }

  void _increment() {
    setState(() {
      _qty = _isFraction
          ? (_qty + 0.5).clamp(0.5, 999)
          : (_qty + 1).clamp(1, 999);
    });
  }

  void _decrement() {
    setState(() {
      _qty = _isFraction
          ? (_qty - 0.5).clamp(0.5, 999)
          : (_qty - 1).clamp(1, 999);
    });
  }

  bool get _canConfirm => _selected != null && _qty >= (_isFraction ? 0.5 : 1);

  void _confirm() {
    final s = _selected;
    if (s == null) return;
    Navigator.pop(context);
    widget.onConfirm?.call(s, _qty);
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = (_selected?.price ?? 0) * _qty;
    final bool hasVariants = widget.product.hasVariants;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDialog
            ? BorderRadius.circular(20)
            : const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle — hidden in dialog mode
          if (!widget.isDialog)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSoft,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )
          else
            const SizedBox(height: 16),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),

                  if (hasVariants) ...[
                    _buildVariantSection(),
                    const SizedBox(height: 20),
                  ],

                  // Quantity picker is only shown when the user can add to
                  // cart (i.e. onConfirm is provided). Inventory staff who
                  // cannot make sales will not see it.
                  if (widget.onConfirm != null) ...[
                    _buildQuantitySection(),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),

          // Add to Order button — hidden when sales are not permitted for
          // this role (onConfirm == null, e.g. inventory staff).
          if (widget.onConfirm != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                widget.isDialog
                    ? 16
                    : MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: AppFilledButton(
                label: _selected != null
                    ? 'Add to Order · ₱${totalPrice.toStringAsFixed(2)}'
                    : hasVariants
                    ? 'Select a variant'
                    : 'Add to Order',
                onPressed: _canConfirm ? _confirm : null,
                verticalPadding: 14,
              ),
            )
          else
            SizedBox(
              height: widget.isDialog
                  ? 16
                  : MediaQuery.viewInsetsOf(context).bottom + 16,
            ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final active = _active;
    final minPrice = active.isEmpty
        ? null
        : active.map((v) => v.price).reduce((a, b) => a < b ? a : b);

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              _isFraction ? Icons.scale_outlined : Icons.inventory_2_outlined,
              size: 26,
              color: AppColors.brand,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.name,
                style: getOutfitStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (minPrice != null)
                    Text(
                      () {
                        final base = widget.product.hasVariants
                            ? 'From ₱${minPrice.toStringAsFixed(2)}'
                            : '₱${minPrice.toStringAsFixed(2)}';
                        return _unit != null ? '$base / $_unit' : base;
                      }(),
                      style: getOutfitStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brand,
                      ),
                    ),
                  if (widget.product.hasVariants) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.brand.withAlpha(50),
                        ),
                      ),
                      child: Text(
                        '${active.length} variants',
                        style: getOutfitStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (widget.onEdit != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onEdit!();
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.textSecondary,
            tooltip: 'Edit product',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceAlt,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ],
    );
  }

  // ── Variant Section ─────────────────────────────────────────────────────────

  Widget _buildVariantSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose a variant',
          style: getOutfitStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        ..._active.map((v) {
          final branchQty = widget.variantStock[v.id] ?? 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _VariantCard(
              variant: v,
              branchStock: branchQty,
              isSelected: _selected?.id == v.id,
              isFraction: _isFraction,
              onTap: () => setState(() {
                _selected = v;
                _qty = _isFraction ? 0.5 : 1;
              }),
            ),
          );
        }),
      ],
    );
  }

  // ── Quantity Section ────────────────────────────────────────────────────────

  Widget _buildQuantitySection() {
    final s = _selected;
    final isFraction = _isFraction;

    // Stock info — use branch-filtered stock when available
    final branchQty = s != null ? (widget.variantStock[s.id] ?? 0.0) : 0.0;
    final ({String label, Color color}) stockInfo = _resolveStockInfo(
      s,
      isFraction,
      branchQty,
    );

    final canDec = _qty > (isFraction ? 0.5 : 1);
    final canInc = _qty < 999;

    return Opacity(
      opacity: s == null ? 0.38 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quantity',
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: stockInfo.color,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    stockInfo.label,
                    style: getOutfitStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: stockInfo.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Row(
              children: [
                _QtyButton(
                  icon: Icons.remove_rounded,
                  enabled: s != null && canDec,
                  onTap: s != null && canDec ? _decrement : null,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      isFraction && _unit != null
                          ? '${_qty.toStringAsFixed(1)} $_unit'
                          : _qty.toStringAsFixed(isFraction ? 1 : 0),
                      style: getOutfitStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                _QtyButton(
                  icon: Icons.add_rounded,
                  enabled: s != null && canInc,
                  onTap: s != null && canInc ? _increment : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({String label, Color color}) _resolveStockInfo(
    ProductVariant? variant,
    bool isFraction,
    num branchQty,
  ) {
    if (variant == null) return (label: '—', color: AppColors.textMuted);

    // Not tracked — show no stock info
    if (!variant.trackStock) return (label: '—', color: AppColors.textMuted);

    // Simple products: never hard-block with "Out of stock"
    if (!widget.product.hasVariants) {
      if (isFraction) {
        final s = variant.stock;
        if (s <= 0) return (label: '—', color: AppColors.textMuted);
        if (s <= 2.0) {
          return (
            label: '${s.toStringAsFixed(1)} available',
            color: AppColors.lowStock,
          );
        }
        return (
          label: '${s.toStringAsFixed(1)} available',
          color: AppColors.inStock,
        );
      }
      if (branchQty <= 0) return (label: '—', color: AppColors.textMuted);
      if (branchQty <= 5) {
        return (
          label: '${qtyLabel(branchQty)} left',
          color: AppColors.lowStock,
        );
      }
      return (
        label: '${qtyLabel(branchQty)} in stock',
        color: AppColors.inStock,
      );
    }

    if (isFraction) {
      final s = variant.stock;
      if (s <= 0) return (label: 'Out of stock', color: AppColors.outOfStock);
      if (s <= 2.0) {
        return (
          label: '${s.toStringAsFixed(1)} available',
          color: AppColors.lowStock,
        );
      }
      return (
        label: '${s.toStringAsFixed(1)} available',
        color: AppColors.inStock,
      );
    }
    if (branchQty == 0) {
      return (label: 'Out of stock', color: AppColors.outOfStock);
    }
    if (branchQty <= 5) {
      return (label: '$branchQty left', color: AppColors.lowStock);
    }
    return (label: '$branchQty in stock', color: AppColors.inStock);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Variant Card
// ─────────────────────────────────────────────────────────────────────────────

class _VariantCard extends StatelessWidget {
  final ProductVariant variant;
  final double branchStock;
  final bool isSelected;
  final bool isFraction;
  final VoidCallback? onTap;

  const _VariantCard({
    required this.variant,
    required this.branchStock,
    required this.isSelected,
    required this.isFraction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = variant.trackStock && !isFraction && branchStock <= 0;
    final badge = _stockBadge();

    return Opacity(
      opacity: isOutOfStock ? 0.7 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.brand : AppColors.borderSoft,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          splashColor: AppColors.brand.withAlpha(20),
          highlightColor: AppColors.brandSoft.withAlpha(80),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Selection circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.brand : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.brand
                          : AppColors.borderSoft,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Variant name
                Expanded(
                  child: Text(
                    variant.name,
                    style: getOutfitStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.brand
                          : AppColors.textPrimary,
                    ),
                  ),
                ),

                // Stock badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badge.color.withAlpha(18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: badge.color.withAlpha(40)),
                  ),
                  child: Text(
                    badge.label,
                    style: getOutfitStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: badge.color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Price
                Text(
                  '₱${variant.price.toStringAsFixed(2)}',
                  style: getOutfitStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ({String label, Color color}) _stockBadge() {
    if (!variant.trackStock) return (label: '—', color: AppColors.textMuted);
    if (isFraction) {
      final s = variant.stock;
      if (s <= 0) return (label: 'Out', color: AppColors.outOfStock);
      if (s <= 2) {
        return (
          label: '${s.toStringAsFixed(1)} left',
          color: AppColors.lowStock,
        );
      }
      return (label: s.toStringAsFixed(1), color: AppColors.inStock);
    }
    if (branchStock == 0) {
      return (label: 'Out of stock', color: AppColors.outOfStock);
    }
    if (branchStock <= 5) {
      return (
        label: '${qtyLabel(branchStock)} left',
        color: AppColors.lowStock,
      );
    }
    return (label: qtyLabel(branchStock), color: AppColors.inStock);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quantity Button
// ─────────────────────────────────────────────────────────────────────────────

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashColor: AppColors.brand.withAlpha(25),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            icon,
            size: 22,
            color: enabled ? AppColors.textPrimary : AppColors.disabledText,
          ),
        ),
      ),
    );
  }
}
