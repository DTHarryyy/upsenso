import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/products/data/holder/variant_form.dart';
import 'package:pos/features/products/widgets/barcode_toggle_field.dart';

class VariantCard extends StatefulWidget {
  final int index;
  final VariantForm form;
  final bool isFraction;
  final bool trackInventory;
  final bool canDelete;
  final VoidCallback onDelete;

  const VariantCard({
    super.key,
    required this.index,
    required this.form,
    required this.isFraction,
    required this.trackInventory,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  State<VariantCard> createState() => VariantCardState();
}
class VariantCardState extends State<VariantCard> {
  final FocusNode _stockFocusNode = FocusNode();

  @override
  void dispose() {
    _stockFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deco = appInputDeco('',
        fillColor: AppColors.background, radius: 8, isDense: true);
    final isFraction = widget.isFraction;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — badge shows entered name once typed
          Row(
            children: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.form.name,
                builder: (_, nameVal, _) {
                  final label = nameVal.text.trim();
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label.isEmpty ? 'Variant ${widget.index}' : label,
                      style: getOutfitStyle(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              if (widget.canDelete)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Name
          TextFormField(
            controller: widget.form.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: deco.copyWith(
              hintText: 'Variant name  (e.g. Small, Regular)',
              labelText: 'Name *',
            ),
            style: getOutfitStyle(color: AppColors.textPrimary),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name required' : null,
          ),
          const SizedBox(height: 8),

          // Price + Cost (2-column, NO retail)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.form.price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  textInputAction: TextInputAction.next,
                  decoration: deco.copyWith(
                      hintText: '0.00',
                      prefixText: '₱ ',
                      labelText: 'Price *'),
                  style: getOutfitStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: widget.form.cost,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  textInputAction: TextInputAction.done,
                  decoration: deco.copyWith(
                      hintText: '0.00',
                      prefixText: '₱ ',
                      labelText: 'Cost'),
                  style: getOutfitStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),

          // Stock — 2-column layout, only when trackInventory ON
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            child: widget.trackInventory
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: widget.form.stock,
                            focusNode: _stockFocusNode,
                            keyboardType: isFraction
                                ? const TextInputType.numberWithOptions(
                                    decimal: true)
                                : TextInputType.number,
                            inputFormatters: isFraction
                                ? [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,3}'))
                                  ]
                                : [FilteringTextInputFormatter.digitsOnly],
                            textInputAction: TextInputAction.next,
                            decoration: deco.copyWith(
                              hintText: isFraction ? '0.000' : '0',
                              labelText: isFraction ? 'Stock (kg) *' : 'Stock *',
                            ),
                            style: getOutfitStyle(color: AppColors.textPrimary),
                            validator: (v) {
                              if (widget.trackInventory &&
                                  (v == null || v.trim().isEmpty)) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: widget.form.lowStock,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textInputAction: TextInputAction.done,
                            decoration: deco.copyWith(
                              hintText: 'e.g. 5',
                              labelText: 'Low Stock Alert',
                            ),
                            style: getOutfitStyle(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),

          const SizedBox(height: 8),

          // Barcode (per-variant, toggleable)
          BarcodeToggleField(controller: widget.form.barcode),
        ],
      ),
    );
  }
}

// ── Product Image Picker ──────────────────────────────────────────────────────

