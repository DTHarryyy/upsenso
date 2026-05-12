import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/services/cart_service.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';

/// Shows the discount sheet – as a dialog on tablet/desktop, bottom-sheet on mobile.
void showDiscountSheet(
  BuildContext context,
  CartService cartService,
  double subtotal,
) {
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
            child: DiscountSheet(
              cartService: cartService,
              subtotal: subtotal,
              isDialog: true,
            ),
          ),
        ),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          DiscountSheet(cartService: cartService, subtotal: subtotal),
    );
  }
}

class DiscountSheet extends StatefulWidget {
  final CartService cartService;
  final double subtotal;
  final bool isDialog;

  const DiscountSheet({
    super.key,
    required this.cartService,
    required this.subtotal,
    this.isDialog = false,
  });

  @override
  State<DiscountSheet> createState() => _DiscountSheetState();
}

class _DiscountSheetState extends State<DiscountSheet> {
  late DiscountType _type;
  late double _value;
  final _controller = TextEditingController();

  static const _pctPresets = [5.0, 10.0, 15.0, 20.0, 50.0];
  static const _fixedPresets = [10.0, 20.0, 50.0, 100.0, 200.0, 500.0];

  @override
  void initState() {
    super.initState();
    _type = widget.cartService.discountType ?? DiscountType.percentage;
    _value = widget.cartService.discountValue;
    if (_value > 0) {
      _controller.text = _value % 1 == 0
          ? _value.toInt().toString()
          : _value.toStringAsFixed(2);
    }
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final v = double.tryParse(_controller.text) ?? 0;
    if (v != _value) setState(() => _value = v);
  }

  void _setPreset(double v) {
    setState(() => _value = v);
    _controller.text = v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
  }

  double get _discountedAmount {
    if (_value <= 0) return 0;
    if (_type == DiscountType.percentage) {
      return (widget.subtotal * _value / 100).clamp(0, widget.subtotal);
    }
    return _value.clamp(0, widget.subtotal);
  }

  double get _finalTotal =>
      (widget.subtotal - _discountedAmount).clamp(0.0, double.infinity);

  bool get _canApply => _value > 0;

  @override
  Widget build(BuildContext context) {
    final presets = _type == DiscountType.percentage
        ? _pctPresets
        : _fixedPresets;
    final bottomPad = widget.isDialog
        ? 0.0
        : MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 6, 20, 20 + bottomPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDialog
            ? BorderRadius.circular(20)
            : const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle — hidden in dialog mode
          if (!widget.isDialog)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.borderSoft,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            )
          else
            const SizedBox(height: 10),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brand, AppColors.brandDark],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Apply Discount',
                style: getOutfitStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Type toggle
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                DiscountTypeTab(
                  label: '% Percentage',
                  icon: Icons.percent_rounded,
                  selected: _type == DiscountType.percentage,
                  onTap: () => setState(() {
                    _type = DiscountType.percentage;
                    _value = 0;
                    _controller.clear();
                  }),
                ),
                DiscountTypeTab(
                  label: '₱ Fixed Amount',
                  icon: Icons.attach_money_rounded,
                  selected: _type == DiscountType.fixed,
                  onTap: () => setState(() {
                    _type = DiscountType.fixed;
                    _value = 0;
                    _controller.clear();
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Input
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: getOutfitStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              prefixText: _type == DiscountType.fixed ? '₱  ' : null,
              suffixText: _type == DiscountType.percentage ? '%' : null,
              prefixStyle: getOutfitStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
              suffixStyle: getOutfitStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
              hintText: '0',
              hintStyle: getOutfitStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.borderSoft,
              ),
              filled: true,
              fillColor: AppColors.inputFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.brand,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Preset chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((p) {
              final isSelected = _value == p;
              final label = _type == DiscountType.percentage
                  ? '${p.toInt()}%'
                  : '₱${p.toInt()}';
              return GestureDetector(
                onTap: () => _setPreset(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.brand : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.brand
                          : AppColors.borderSoft,
                    ),
                  ),
                  child: Text(
                    label,
                    style: getOutfitStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Live preview
          if (_canApply)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discount',
                        style: getOutfitStyle(
                          fontSize: 12,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        '− ${AppFormatters.currency(_discountedAmount)}',
                        style: getOutfitStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'New Total',
                        style: getOutfitStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        AppFormatters.currency(_finalTotal),
                        style: getOutfitStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              if (widget.cartService.hasDiscount) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.cartService.clearDiscount();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Remove',
                      style: getOutfitStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _canApply
                      ? () {
                          widget.cartService.applyDiscount(_type, _value);
                          Navigator.pop(context);
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply Discount',
                    style: getOutfitStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DiscountTypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const DiscountTypeTab({
    super.key,
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
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
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
                color: selected ? AppColors.brand : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.brand : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
