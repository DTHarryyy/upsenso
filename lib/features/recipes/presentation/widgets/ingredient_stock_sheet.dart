import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_dropdown.dart';
import 'package:pos/core/widgets/app_field_label.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/widgets/app_input_decoration.dart';
import 'package:pos/features/recipes/domain/entities/ingredient.dart';

// Reason → icon, for the AppDropdown reason picker (adjust mode only).
const _adjustReasons = <({String value, IconData icon})>[
  (value: 'Spoilage', icon: Icons.delete_outline_rounded),
  (value: 'Wastage', icon: Icons.water_drop_outlined),
  (value: 'Correction', icon: Icons.fact_check_outlined),
  (value: 'Damage', icon: Icons.report_problem_outlined),
  (value: 'Transfer', icon: Icons.swap_horiz_rounded),
];

const _quickAddAmounts = [10, 50, 100, 500];

enum _SheetMode { restock, adjust }

class IngredientStockResult {
  final bool isIncoming;
  final double quantity;
  final String reason;
  final String? note;

  const IngredientStockResult({
    required this.isIncoming,
    required this.quantity,
    required this.reason,
    this.note,
  });
}

Future<IngredientStockResult?> showIngredientStockSheet({
  required BuildContext context,
  required Ingredient ingredient,
  bool restockMode = true,
}) {
  return showModalBottomSheet<IngredientStockResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _IngredientStockSheet(
      ingredient: ingredient,
      initialMode: restockMode ? _SheetMode.restock : _SheetMode.adjust,
    ),
  );
}

class _IngredientStockSheet extends StatefulWidget {
  final Ingredient ingredient;
  final _SheetMode initialMode;

  const _IngredientStockSheet({
    required this.ingredient,
    required this.initialMode,
  });

  @override
  State<_IngredientStockSheet> createState() => _IngredientStockSheetState();
}

class _IngredientStockSheetState extends State<_IngredientStockSheet> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _noteController = TextEditingController();

  late _SheetMode _mode;
  bool _isAddition = true; // only relevant in adjust mode
  String _selectedReason = _adjustReasons.first.value;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _qtyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _incoming => _mode == _SheetMode.restock ? true : _isAddition;

  double get _enteredQty => double.tryParse(_qtyController.text.trim()) ?? 0;

  double get _projectedStock {
    final delta = _incoming ? _enteredQty : -_enteredQty;
    return widget.ingredient.stock + delta;
  }

  bool get _wouldGoNegative => _projectedStock < 0;

  void _applyQuickAdd(int amount) {
    final current = _enteredQty;
    final next = current == current.truncateToDouble()
        ? (current.toInt() + amount).toString()
        : (current + amount).toStringAsFixed(2);
    _qtyController.text = next;
    _qtyController.selection = TextSelection.fromPosition(
      TextPosition(offset: _qtyController.text.length),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final qty = double.tryParse(_qtyController.text.trim());
    if (qty == null || qty <= 0) return;

    final reason = _mode == _SheetMode.restock ? 'Restock' : _selectedReason;
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    Navigator.of(context).pop(
      IngredientStockResult(
        isIncoming: _incoming,
        quantity: qty,
        reason: reason,
        note: note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;
    final unit = widget.ingredient.unit ?? 'pcs';

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

              // Mode toggle
              _ModeToggle(
                mode: _mode,
                onChanged: (m) => setState(() => _mode = m),
              ),
              const SizedBox(height: 20),

              // Ingredient name + current stock
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.ingredient.name,
                      style: getOutfitStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Stock: ${_fmt(widget.ingredient.stock)} $unit',
                      style: getOutfitStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Adjust mode: direction toggle
              if (_mode == _SheetMode.adjust) ...[
                const AppFieldLabel('Direction'),
                Row(
                  children: [
                    _DirectionChip(
                      label: '+ Add',
                      selected: _isAddition,
                      color: AppColors.success,
                      softColor: AppColors.successSoft,
                      onTap: () => setState(() => _isAddition = true),
                    ),
                    const SizedBox(width: 8),
                    _DirectionChip(
                      label: '− Remove',
                      selected: !_isAddition,
                      color: AppColors.error,
                      softColor: AppColors.errorSoft,
                      onTap: () => setState(() => _isAddition = false),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Quantity
              const AppFieldLabel('Quantity *'),
              TextFormField(
                controller: _qtyController,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                style: getOutfitStyle(
                    fontSize: 14, color: AppColors.textPrimary),
                decoration:
                    appInputDeco('Enter quantity').copyWith(suffixText: unit),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a valid quantity';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Quick-add chips
              Wrap(
                spacing: 8,
                children: _quickAddAmounts
                    .map((a) => _QuickAddChip(
                          amount: a,
                          onTap: () => _applyQuickAdd(a),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 14),

              // Live result preview
              if (_enteredQty > 0)
                _ResultPreview(
                  before: widget.ingredient.stock,
                  after: _projectedStock,
                  unit: unit,
                  incoming: _incoming,
                  warnNegative: _wouldGoNegative,
                ),
              if (_enteredQty > 0) const SizedBox(height: 14),

              // Reason (adjust mode only)
              if (_mode == _SheetMode.adjust) ...[
                const AppFieldLabel('Reason *'),
                AppDropdown<String>(
                  value: _selectedReason,
                  hint: 'Select reason',
                  items: _adjustReasons
                      .map((r) => AppDropdownItem(
                            value: r.value,
                            label: r.value,
                            icon: r.icon,
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedReason = v);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Note
              const AppFieldLabel('Note (optional)'),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                style: getOutfitStyle(
                    fontSize: 14, color: AppColors.textPrimary),
                decoration: appInputDeco('Additional details...'),
              ),
              const SizedBox(height: 24),

              AppFilledButton(
                label: _mode == _SheetMode.restock
                    ? 'Confirm Restock'
                    : (_isAddition ? 'Add Stock' : 'Remove Stock'),
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmt(double v) =>
    v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

// ── Live result preview ───────────────────────────────────────────────────────

class _ResultPreview extends StatelessWidget {
  final double before;
  final double after;
  final String unit;
  final bool incoming;
  final bool warnNegative;

  const _ResultPreview({
    required this.before,
    required this.after,
    required this.unit,
    required this.incoming,
    required this.warnNegative,
  });

  @override
  Widget build(BuildContext context) {
    final color = warnNegative
        ? AppColors.error
        : (incoming ? AppColors.success : AppColors.warning);
    final bg = warnNegative
        ? AppColors.errorSoft
        : (incoming ? AppColors.successSoft : AppColors.warningSoft);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_flat_rounded, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                'New stock: ',
                style: getOutfitStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${_fmt(before)} → ${_fmt(after)} $unit',
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          if (warnNegative) ...[
            const SizedBox(height: 4),
            Text(
              'This will set stock below zero.',
              style: getOutfitStyle(fontSize: 11, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Quick-add chip ────────────────────────────────────────────────────────────

class _QuickAddChip extends StatelessWidget {
  final int amount;
  final VoidCallback onTap;

  const _QuickAddChip({required this.amount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Text(
          '+$amount',
          style: getOutfitStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Mode toggle ───────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final _SheetMode mode;
  final ValueChanged<_SheetMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _ModeTab(
            label: 'Restock',
            icon: Icons.add_rounded,
            selected: mode == _SheetMode.restock,
            onTap: () => onChanged(_SheetMode.restock),
          ),
          _ModeTab(
            label: 'Adjust',
            icon: Icons.tune_rounded,
            selected: mode == _SheetMode.adjust,
            onTap: () => onChanged(_SheetMode.adjust),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color:
                    selected ? AppColors.textPrimary : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      selected ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final Color softColor;
  final VoidCallback onTap;

  const _DirectionChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.softColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? softColor : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : AppColors.borderSoft,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: getOutfitStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
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
