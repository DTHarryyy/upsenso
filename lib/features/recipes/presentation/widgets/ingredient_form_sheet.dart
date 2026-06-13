import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_dropdown.dart';
import 'package:pos/core/widgets/app_field_label.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/widgets/app_input_decoration.dart';
import 'package:pos/features/recipes/domain/entities/ingredient.dart';
import 'package:pos/features/recipes/presentation/cubit/ingredients_cubit.dart';

/// All units of measure supported for ingredient stock tracking.
const _kUnits = ['pcs', 'g', 'kg', 'ml', 'L', 'oz', 'lb', 'fl oz'];

class IngredientFormSheet extends StatefulWidget {
  /// Null = create mode; non-null = edit mode.
  final Ingredient? ingredient;

  /// Selected branch for opening-stock seeding (null = all branches — no seed).
  final String? branchId;

  const IngredientFormSheet({super.key, this.ingredient, this.branchId});

  @override
  State<IngredientFormSheet> createState() => _IngredientFormSheetState();
}

class _IngredientFormSheetState extends State<IngredientFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _openingStock;
  late final TextEditingController _lowStockAlert;
  String? _selectedUnit;
  bool _saving = false;

  bool get _isEdit => widget.ingredient != null;

  @override
  void initState() {
    super.initState();
    final ing = widget.ingredient;
    _name = TextEditingController(text: ing?.name);
    _openingStock = TextEditingController();
    _lowStockAlert = TextEditingController(
      text: ing?.lowStockAlert?.toString() ?? '',
    );
    _selectedUnit = ing?.unit ?? 'pcs';
  }

  @override
  void dispose() {
    _name.dispose();
    _openingStock.dispose();
    _lowStockAlert.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final cubit = context.read<IngredientsCubit>();
      final lowAlert = int.tryParse(_lowStockAlert.text.trim());
      if (_isEdit) {
        await cubit.update(
          variantId: widget.ingredient!.id,
          productId: widget.ingredient!.productId,
          name: _name.text.trim(),
          unit: _selectedUnit,
          lowStockAlert: lowAlert,
        );
      } else {
        final opening = double.tryParse(_openingStock.text.trim()) ?? 0;
        await cubit.create(
          name: _name.text.trim(),
          unit: _selectedUnit,
          openingStock: opening,
          branchId: widget.branchId,
          lowStockAlert: lowAlert,
        );
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _DragHandle(),
              const SizedBox(height: 16),
              Text(
                _isEdit ? 'Edit Ingredient' : 'Add Ingredient',
                style: getOutfitStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Name
              const AppFieldLabel('Ingredient Name *'),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                style:
                    getOutfitStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: appInputDeco('e.g. Milk'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Unit of measure
              const AppFieldLabel('Unit of Measure'),
              AppDropdown<String>(
                value: _selectedUnit,
                hint: 'Select unit',
                items: _kUnits
                    .map((u) => AppDropdownItem(value: u, label: u))
                    .toList(),
                onChanged: (v) => setState(() => _selectedUnit = v),
              ),
              const SizedBox(height: 14),

              // Opening stock (create only)
              if (!_isEdit) ...[
                const AppFieldLabel('Opening Stock (optional)'),
                _numericField(_openingStock, '0', decimal: true),
                const SizedBox(height: 14),
              ],

              // Low-stock alert
              const AppFieldLabel('Low Stock Alert (optional)'),
              _numericField(_lowStockAlert, 'Notify when stock drops below'),
              const SizedBox(height: 24),

              AppFilledButton(
                label: _isEdit ? 'Save Changes' : 'Add Ingredient',
                icon: _isEdit ? IconlyLight.tick_square : IconlyLight.plus,
                loading: _saving,
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numericField(
    TextEditingController ctrl,
    String hint, {
    bool decimal = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType:
          TextInputType.numberWithOptions(decimal: decimal, signed: false),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
        ),
      ],
      style: getOutfitStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: appInputDeco(hint),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderSoft,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
