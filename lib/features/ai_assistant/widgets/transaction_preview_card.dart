import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/ai_assistant/models/ai_models.dart';

class TransactionPreviewCard extends StatefulWidget {
  final AiTransactionPreview preview;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isProcessing;
  final ValueChanged<AiTransactionPreview>? onPreviewUpdated;

  const TransactionPreviewCard({
    super.key,
    required this.preview,
    required this.onConfirm,
    required this.onCancel,
    this.isProcessing = false,
    this.onPreviewUpdated,
  });

  @override
  State<TransactionPreviewCard> createState() => _TransactionPreviewCardState();
}

class _TransactionPreviewCardState extends State<TransactionPreviewCard> {
  late List<AiMatchedProduct> _products;

  @override
  void initState() {
    super.initState();
    _products = List.of(widget.preview.matchedProducts);
  }

  @override
  void didUpdateWidget(TransactionPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preview != widget.preview) {
      _products = List.of(widget.preview.matchedProducts);
    }
  }

  void _selectVariant(int index, AiVariantOption variant) {
    if (variant.trackStock && variant.stock <= 0) return;
    setState(() => _products[index] = _products[index].selectVariant(variant));
    _notifyUpdated();
  }

  void _removeProduct(int index) {
    setState(() => _products.removeAt(index));
    _notifyUpdated();
  }

  void _notifyUpdated() {
    final subtotal = _products.fold(0.0, (s, p) => s + p.lineTotal);
    final totalTax = _products.fold(0.0, (s, p) => s + p.lineTax);
    widget.onPreviewUpdated?.call(AiTransactionPreview(
      matchedProducts: _products,
      unmatchedNames: widget.preview.unmatchedNames,
      subtotal: subtotal,
      totalTax: totalTax,
      grandTotal: subtotal + totalTax,
    ));
  }

  double get _subtotal => _products.fold(0.0, (s, p) => s + p.lineTotal);
  double get _totalTax => _products.fold(0.0, (s, p) => s + p.lineTax);
  double get _grandTotal => _subtotal + _totalTax;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(7),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.brand, AppColors.brandDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    size: 18, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Transaction Preview',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: Colors.white,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_products.length} item${_products.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Line items
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: [
                for (int i = 0; i < _products.length; i++) ...[
                  _LineItemRow(
                    product: _products[i],
                    onVariantSelected: _products[i].needsVariantSelection
                        ? (v) => _selectVariant(i, v)
                        : null,
                    onRemove: () => _removeProduct(i),
                  ),
                  if (i < _products.length - 1)
                    Divider(
                        height: 16,
                        thickness: 1,
                        color: AppColors.borderSoft.withAlpha(180)),
                ],
              ],
            ),
          ),

          // Unmatched warning
          if (widget.preview.unmatchedNames.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.warning.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 15, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Not found: ${widget.preview.unmatchedNames.join(', ')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Totals
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _TotalRow(label: 'Subtotal', value: _subtotal),
                  if (_totalTax > 0) ...[
                    const SizedBox(height: 6),
                    _TotalRow(label: 'Tax', value: _totalTax),
                  ],
                  const SizedBox(height: 8),
                  const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.borderSoft),
                  const SizedBox(height: 8),
                  _TotalRow(
                      label: 'Total', value: _grandTotal, isBold: true),
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                // Cancel
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        widget.isProcessing ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.borderSoft),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Confirm
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed:
                        widget.isProcessing ? null : widget.onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: widget.isProcessing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Confirm Transaction',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Line item ────────────────────────────────────────────────────────────────

class _LineItemRow extends StatelessWidget {
  final AiMatchedProduct product;
  final ValueChanged<AiVariantOption>? onVariantSelected;
  final VoidCallback? onRemove;

  const _LineItemRow({
    required this.product,
    this.onVariantSelected,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final showVariantLabel =
        product.variantName != 'Default' && product.variantName.isNotEmpty;
    final outOfStock =
        product.trackStock && product.availableStock <= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Remove
              GestureDetector(
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 2),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.errorSoft,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 13, color: AppColors.error),
                  ),
                ),
              ),

              // Name + variant
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: outOfStock
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        decoration: outOfStock
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (outOfStock)
                      const Text(
                        'Out of stock',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500),
                      ),
                    if (showVariantLabel && !product.needsVariantSelection)
                      Text(
                        product.variantName,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),

              // Qty × price = total
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱${_fmt(product.lineTotal)}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '×${_fmtQty(product.quantity)}  ₱${_fmt(product.unitPrice)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),

          // Tax line
          if ((product.taxRate ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.only(left: 23, top: 2),
              child: Text(
                'Tax ${product.taxRate!.toStringAsFixed(0)}%: ₱${_fmt(product.lineTax)}',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic),
              ),
            ),

          // Variant picker
          if (product.needsVariantSelection && onVariantSelected != null)
            Padding(
              padding: const EdgeInsets.only(left: 23, top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose variant:',
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: product.availableVariants.map((v) {
                      final isSelected = v.variantId == product.variantId;
                      final oos = v.trackStock && v.stock <= 0;
                      return GestureDetector(
                        onTap: oos ? null : () => onVariantSelected!(v),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.brand.withAlpha(15)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.brand
                                  : AppColors.borderSoft,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                v.variantName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: oos
                                      ? AppColors.textMuted
                                      : isSelected
                                          ? AppColors.brand
                                          : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '₱${_fmt(v.price)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: oos
                                      ? AppColors.textMuted
                                      : AppColors.textMuted,
                                ),
                              ),
                              if (oos) ...[
                                const SizedBox(width: 4),
                                const Text('·',
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11)),
                                const SizedBox(width: 3),
                                const Text(
                                  'Out of stock',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.error),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Total row ────────────────────────────────────────────────────────────────

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14.5 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          '₱${_fmt(value)}',
          style: TextStyle(
            fontSize: isBold ? 16 : 13.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? AppColors.brand : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmtQty(double qty) {
  if (qty == qty.toInt().toDouble()) return qty.toInt().toString();
  return qty.toStringAsFixed(2);
}

String _fmt(double value) {
  final isWhole = value == value.toInt().toDouble();
  final s = isWhole
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
  return s.replaceAllMapped(
    isWhole
        ? RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))')
        : RegExp(r'(\d{1,3})(?=(\d{3})+\.)'),
    (m) => '${m[1]},',
  );
}
