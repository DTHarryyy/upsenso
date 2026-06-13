import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter/services.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/products/data/holder/variant_form.dart';
import 'package:pos/features/products/presentation/cubit/product_form_state.dart';
import 'package:pos/features/products/widgets/barcode_toggle_field.dart';

class VariantCard extends StatefulWidget {
  final int index;
  final VariantForm form;
  final bool isFraction;
  final bool trackInventory;
  final bool canDelete;
  final VoidCallback onDelete;
  final bool stockReadOnly;

  // Recipe mode
  final bool isRecipeMode;
  final VoidCallback? onEditRecipe;

  const VariantCard({
    super.key,
    required this.index,
    required this.form,
    required this.isFraction,
    required this.trackInventory,
    required this.canDelete,
    required this.onDelete,
    this.stockReadOnly = false,
    this.isRecipeMode = false,
    this.onEditRecipe,
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
          // Header
          Row(
            children: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.form.name,
                builder: (_, nameVal, _) {
                  final label = nameVal.text.trim();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
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
                  child: const Icon(IconlyLight.delete,
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

          // Price + Cost
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

          // Stock row — hidden in recipe mode
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            child: (!widget.isRecipeMode && widget.trackInventory)
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Opacity(
                            opacity: widget.stockReadOnly ? 0.6 : 1.0,
                            child: TextFormField(
                              controller: widget.form.stock,
                              focusNode: _stockFocusNode,
                              readOnly: widget.stockReadOnly,
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
                                labelText:
                                    isFraction ? 'Stock (kg) *' : 'Stock *',
                                filled: true,
                                fillColor: widget.stockReadOnly
                                    ? AppColors.surfaceAlt
                                    : AppColors.background,
                              ),
                              style: getOutfitStyle(
                                  color: AppColors.textPrimary),
                              validator: (v) {
                                if (!widget.stockReadOnly &&
                                    widget.trackInventory &&
                                    (v == null || v.trim().isEmpty)) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
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
                            style: getOutfitStyle(
                                color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),

          // Recipe row — only in recipe mode
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            child: widget.isRecipeMode
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _VariantRecipeRow(
                      form: widget.form,
                      onEdit: widget.onEditRecipe,
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

/// Compact recipe status row shown inside each variant card.
/// Tapping it opens the per-variant recipe builder sheet.
class _VariantRecipeRow extends StatelessWidget {
  final VariantForm form;
  final VoidCallback? onEdit;

  const _VariantRecipeRow({required this.form, this.onEdit});

  static double _cost(List<RecipeLineFormEntry> lines) =>
      lines.fold(0.0, (s, l) => s + (l.costPrice ?? 0.0) * l.quantity);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: form.price,
      builder: (_, priceVal, _) {
        final lines = form.recipeLines;
        final count = lines.length;
        final cost = _cost(lines);
        final hasCost = cost > 0;
        final price = double.tryParse(priceVal.text.trim());
        final margin = (price != null && price > 0 && hasCost)
            ? (price - cost) / price * 100
            : null;

        final Color color;
        final Color bg;
        if (count == 0) {
          color = AppColors.textMuted;
          bg = AppColors.surfaceAlt;
        } else if (margin == null || margin >= 40) {
          color = AppColors.success;
          bg = AppColors.successSoft;
        } else if (margin >= 20) {
          color = AppColors.warning;
          bg = AppColors.warningSoft;
        } else {
          color = AppColors.error;
          bg = AppColors.errorSoft;
        }

        return GestureDetector(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withAlpha(40)),
            ),
            child: Row(
              children: [
                Icon(Icons.blender_outlined, size: 14, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: count == 0
                      ? Text(
                          'No ingredients set',
                          style: getOutfitStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        )
                      : Text(
                          hasCost
                              ? (margin != null
                                  ? '$count ingredient${count == 1 ? '' : 's'} · ₱${cost.toStringAsFixed(2)} cost · ${margin.toStringAsFixed(0)}% margin'
                                  : '$count ingredient${count == 1 ? '' : 's'} · ₱${cost.toStringAsFixed(2)} cost')
                              : '$count ingredient${count == 1 ? '' : 's'}',
                          style: getOutfitStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                const SizedBox(width: 6),
                Text(
                  count == 0 ? 'Set recipe' : 'Edit',
                  style: getOutfitStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 15, color: color),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Product Image Picker ──────────────────────────────────────────────────────
