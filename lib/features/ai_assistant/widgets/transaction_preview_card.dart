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
    setState(() {
      _products[index] = _products[index].selectVariant(variant);
    });
    _notifyPreviewUpdated();
  }

  void _removeProduct(int index) {
    setState(() {
      _products.removeAt(index);
    });
    _notifyPreviewUpdated();
  }

  void _notifyPreviewUpdated() {
    final subtotal = _products.fold(0.0, (sum, p) => sum + p.lineTotal);
    final totalTax = _products.fold(0.0, (sum, p) => sum + p.lineTax);
    final updated = AiTransactionPreview(
      matchedProducts: _products,
      unmatchedNames: widget.preview.unmatchedNames,
      subtotal: subtotal,
      totalTax: totalTax,
      grandTotal: subtotal + totalTax,
    );
    widget.onPreviewUpdated?.call(updated);
  }

  double get _subtotal => _products.fold(0.0, (sum, p) => sum + p.lineTotal);
  double get _totalTax => _products.fold(0.0, (sum, p) => sum + p.lineTax);
  double get _grandTotal => _subtotal + _totalTax;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  size: 20,
                  color: AppColors.brand,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Transaction Preview',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.brand,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_products.length} item${_products.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Line items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                for (int i = 0; i < _products.length; i++)
                  _LineItemRow(
                    product: _products[i],
                    onVariantSelected: _products[i].needsVariantSelection
                        ? (variant) => _selectVariant(i, variant)
                        : null,
                    onRemove: () => _removeProduct(i),
                  ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1, color: AppColors.borderSoft),

          // Totals
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _TotalRow(
                  label: 'Subtotal',
                  value: _subtotal,
                ),
                if (_totalTax > 0) ...[
                  const SizedBox(height: 4),
                  _TotalRow(
                    label: 'Tax',
                    value: _totalTax,
                  ),
                ],
                const SizedBox(height: 8),
                _TotalRow(
                  label: 'Total',
                  value: _grandTotal,
                  isBold: true,
                ),
              ],
            ),
          ),

          // Unmatched warning
          if (widget.preview.unmatchedNames.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Not found: ${widget.preview.unmatchedNames.join(", ")}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Cancel
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.isProcessing ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.borderSoft),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.isProcessing ? null : widget.onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: AppColors.textInverse,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: widget.isProcessing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textInverse,
                            ),
                          )
                        : const Text(
                            'CONFIRM',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
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
    final showVariant =
        product.variantName != 'Default' && product.variantName.isNotEmpty;
    final hasTax = (product.taxRate ?? 0) > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Remove button
              GestureDetector(
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.only(right: 6, top: 2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.error,
                  ),
                ),
              ),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: product.trackStock && product.availableStock <= 0
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        decoration: product.trackStock && product.availableStock <= 0
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (product.trackStock && product.availableStock <= 0)
                      const Text(
                        'Out of stock',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (showVariant && !product.needsVariantSelection)
                      Text(
                        product.variantName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              // Quantity
              Text(
                '×${_formatQty(product.quantity)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              // Unit price
              Text(
                '₱${_formatNum(product.unitPrice)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              // Line total
              Text(
                '₱${_formatNum(product.lineTotal)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          // Per-line tax info
          if (hasTax)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Tax ${product.taxRate!.toStringAsFixed(0)}%: ₱${_formatNum(product.lineTax)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          // Variant radio buttons
          if (product.needsVariantSelection && onVariantSelected != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose variant:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  ...product.availableVariants.map((v) {
                    final isSelected = v.variantId == product.variantId;
                    final isOutOfStock = v.trackStock && v.stock <= 0;
                    return GestureDetector(
                      onTap: isOutOfStock
                          ? null
                          : () => onVariantSelected!(v),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 18,
                              color: isOutOfStock
                                  ? AppColors.textMuted.withAlpha(100)
                                  : isSelected
                                      ? AppColors.brand
                                      : AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              v.variantName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isOutOfStock
                                    ? AppColors.textMuted.withAlpha(100)
                                    : isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₱${_formatNum(v.price)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isOutOfStock
                                    ? AppColors.textMuted.withAlpha(100)
                                    : isSelected
                                        ? AppColors.brand
                                        : AppColors.textMuted,
                              ),
                            ),
                            if (isOutOfStock) ...[
                              const SizedBox(width: 6),
                              const Text(
                                'Out of stock',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

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
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          '₱${_formatNum(value)}',
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? AppColors.brand : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

String _formatQty(double qty) {
  if (qty == qty.toInt().toDouble()) return qty.toInt().toString();
  return qty.toStringAsFixed(2);
}

String _formatNum(double value) {
  if (value == value.toInt().toDouble()) {
    return value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
  return value.toStringAsFixed(2).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+\.)'),
    (m) => '${m[1]},',
  );
}
