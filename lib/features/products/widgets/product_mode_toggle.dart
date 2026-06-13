import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/products/presentation/cubit/product_form_state.dart';

class ProductModeToggle extends StatelessWidget {
  final ProductFormMode mode;
  final ValueChanged<ProductFormMode> onChanged;

  const ProductModeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSimple = mode == ProductFormMode.simple;
    return LayoutBuilder(
      builder: (ctx, c) {
        final pillWidth = (c.maxWidth - 8) / 2;
        return Container(
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSoft, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D101828),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: Color(0x06101828),
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment:
                    isSimple ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: pillWidth,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brand.withAlpha(55),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _ModeChip(
                      icon: Icons.bolt_rounded,
                      label: 'Simple',
                      active: isSimple,
                      onTap: () => onChanged(ProductFormMode.simple),
                    ),
                  ),
                  Expanded(
                    child: _ModeChip(
                      icon: Icons.tune_rounded,
                      label: 'Advanced',
                      active: !isSimple,
                      onTap: () => onChanged(ProductFormMode.advanced),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: getOutfitStyle(
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
