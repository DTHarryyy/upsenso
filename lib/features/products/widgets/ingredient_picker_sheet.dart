import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/products/presentation/cubit/product_form_state.dart';
import 'package:pos/features/recipes/domain/entities/ingredient.dart';
import 'package:pos/features/recipes/domain/repositories/i_ingredients_repository.dart';

class IngredientPickerSheet extends StatefulWidget {
  final String businessId;
  final Set<String> excludeIds;
  final ValueChanged<RecipeLineFormEntry> onSelected;

  const IngredientPickerSheet({
    super.key,
    required this.businessId,
    required this.excludeIds,
    required this.onSelected,
  });

  @override
  State<IngredientPickerSheet> createState() => _IngredientPickerSheetState();
}

class _IngredientPickerSheetState extends State<IngredientPickerSheet> {
  List<Ingredient>? _ingredients;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all =
        await sl<IIngredientsRepository>().getByBusinessId(widget.businessId);
    if (!mounted) return;
    setState(() {
      _ingredients = all
          .where((i) => !widget.excludeIds.contains(i.id))
          .toList();
    });
  }

  List<Ingredient> get _filtered {
    final items = _ingredients ?? [];
    if (_query.isEmpty) return items;
    final q = _query.toLowerCase();
    return items.where((i) => i.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _pickQuantity(Ingredient ingredient) async {
    final qtyController = TextEditingController(text: '1');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(ingredient.name, style: AppTextStyles.title(ctx)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quantity consumed per unit sold'
              '${ingredient.unit != null ? ' (${ingredient.unit})' : ''}',
              style: getOutfitStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,3}')),
              ],
              decoration: appInputDeco('e.g. 0.25'),
              style:
                  getOutfitStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: getOutfitStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Add',
              style: getOutfitStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final qty = double.tryParse(qtyController.text.trim()) ?? 1.0;
    widget.onSelected(
      RecipeLineFormEntry(
        ingredientVariantId: ingredient.id,
        ingredientName: ingredient.name,
        quantity: qty > 0 ? qty : 1.0,
        unit: ingredient.unit,
        costPrice: ingredient.costPrice,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          Text('Select Ingredient', style: AppTextStyles.title(context)),
          const SizedBox(height: 12),
          TextField(
            autofocus: false,
            onChanged: (v) => setState(() => _query = v),
            decoration: appInputDeco('Search ingredients…').copyWith(
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
            style: getOutfitStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          if (_ingredients == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(
                color: AppColors.brand,
                strokeWidth: 2,
              ),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                _query.isEmpty
                    ? 'No ingredients found.\nAdd them under More → Ingredients.'
                    : 'No match for "$_query"',
                textAlign: TextAlign.center,
                style: getOutfitStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.borderSoft),
                itemBuilder: (_, i) {
                  final ing = items[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      ing.name,
                      style: getOutfitStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      '${ing.stock.toStringAsFixed(ing.stock % 1 == 0 ? 0 : 2)}'
                      '${ing.unit != null ? ' ${ing.unit}' : ''} in stock',
                      style: getOutfitStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.brand,
                      size: 22,
                    ),
                    onTap: () => _pickQuantity(ing),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
