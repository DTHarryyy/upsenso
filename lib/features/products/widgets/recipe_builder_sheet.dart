import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/products/presentation/cubit/product_form_state.dart';
import 'package:pos/features/products/widgets/ingredient_picker_sheet.dart';
import 'package:pos/features/products/widgets/recipe_line_tile.dart';

class RecipeBuilderSheet extends StatefulWidget {
  final String title;
  final List<RecipeLineFormEntry> initialLines;
  final double? sellingPrice;
  final String businessId;
  final void Function(List<RecipeLineFormEntry>) onSave;
  final List<RecipeLineFormEntry> templateLines;
  final String? templateLabel;

  const RecipeBuilderSheet({
    super.key,
    required this.title,
    required this.initialLines,
    required this.businessId,
    required this.onSave,
    this.sellingPrice,
    this.templateLines = const [],
    this.templateLabel,
  });

  @override
  State<RecipeBuilderSheet> createState() => _RecipeBuilderSheetState();
}

class _RecipeBuilderSheetState extends State<RecipeBuilderSheet> {
  late List<RecipeLineFormEntry> _lines;

  @override
  void initState() {
    super.initState();
    _lines = List.of(widget.initialLines);
  }

  double get _recipeCost =>
      _lines.fold(0.0, (s, l) => s + (l.costPrice ?? 0.0) * l.quantity);

  void _remove(String id) =>
      setState(() => _lines.removeWhere((l) => l.ingredientVariantId == id));

  void _updateQty(String id, double qty) {
    setState(() {
      _lines = _lines.map((l) {
        return l.ingredientVariantId == id ? l.copyWith(quantity: qty) : l;
      }).toList();
    });
  }

  Future<void> _addIngredient() async {
    final excluded = _lines.map((l) => l.ingredientVariantId).toSet();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IngredientPickerSheet(
        businessId: widget.businessId,
        excludeIds: excluded,
        onSelected: (entry) => setState(() => _lines = [..._lines, entry]),
      ),
    );
  }

  void _save() {
    widget.onSave(_lines);
    Navigator.of(context).pop();
  }

  Widget _buildEmptyState() {
    final hasTemplate = widget.templateLines.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.blender_outlined,
              color: AppColors.brand,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No ingredients yet',
            style: getOutfitStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add the ingredients consumed each time\nthis product is sold.',
            textAlign: TextAlign.center,
            style: getOutfitStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          if (hasTemplate) ...[
            OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _lines = List.of(widget.templateLines)),
              icon: const Icon(Icons.copy_outlined, size: 15),
              label: Text(
                widget.templateLabel ?? 'Copy from other variant',
                style: getOutfitStyle(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brand,
                side: const BorderSide(color: AppColors.brand),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
            const SizedBox(height: 10),
          ],
          ElevatedButton.icon(
            onPressed: _addIngredient,
            icon:
                const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            label: Text(
              'Add Ingredient',
              style: getOutfitStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 46),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cost = _recipeCost;
    final hasCost = cost > 0;
    final price = widget.sellingPrice;
    final margin = (price != null && price > 0 && hasCost)
        ? (price - cost) / price * 100
        : null;

    final Color marginColor = margin == null
        ? AppColors.textMuted
        : margin >= 40
            ? AppColors.success
            : margin >= 20
                ? AppColors.warning
                : AppColors.error;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(widget.title, style: AppTextStyles.title(context)),
                const Spacer(),
                TextButton(
                  onPressed: _save,
                  child: Text(
                    'Done',
                    style: getOutfitStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSoft),
          Flexible(
            child: _lines.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    shrinkWrap: true,
                    itemCount: _lines.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (_, i) => RecipeLineTile(
                      line: _lines[i],
                      onRemove: () =>
                          _remove(_lines[i].ingredientVariantId),
                      onQtyChanged: (qty) =>
                          _updateQty(_lines[i].ingredientVariantId, qty),
                    ),
                  ),
          ),
          if (_lines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: OutlinedButton.icon(
                onPressed: _addIngredient,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  'Add Ingredient',
                  style: getOutfitStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  side: const BorderSide(color: AppColors.brand),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 46),
                ),
              ),
            ),
          if (hasCost) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recipe cost',
                          style: getOutfitStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                        Text(
                          '₱${cost.toStringAsFixed(2)}',
                          style: getOutfitStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (price != null && price > 0) ...[
                    Container(
                      width: 1,
                      height: 32,
                      color: AppColors.borderSoft,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Margin',
                            style: getOutfitStyle(
                                color: AppColors.textMuted, fontSize: 11),
                          ),
                          Text(
                            margin != null
                                ? '₱${(price - cost).toStringAsFixed(2)} · ${margin.toStringAsFixed(0)}%'
                                : '—',
                            style: getOutfitStyle(
                              color: marginColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          SizedBox(
            height: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
        ],
      ),
    );
  }
}
