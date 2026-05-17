import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/routes/app_routes.dart';

class QuickActionsBar extends StatelessWidget {
  final VoidCallback? onNewSale;

  const QuickActionsBar({super.key, this.onNewSale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
      children: [
        _QuickAction(
          icon: IconlyBold.buy,
          label: 'New Sale',
          iconColor: AppColors.brand,
          bgColor: AppColors.brandSoft,
          onTap: () => onNewSale?.call(),
        ),
        _QuickAction(
          icon: IconlyBold.plus,
          label: 'Add Product',
          iconColor: AppColors.success,
          bgColor: AppColors.successSoft,
          onTap: () => context.push(AppRoutes.addProduct),
        ),
        _QuickAction(
          icon: IconlyBold.category,
          label: 'Stock Adjust',
          iconColor: AppColors.warning,
          bgColor: AppColors.warningSoft,
          onTap: () => context.push(AppRoutes.inventory),
        ),
        _QuickAction(
          icon: IconlyBold.paper,
          label: 'Expense',
          iconColor: AppColors.error,
          bgColor: AppColors.errorSoft,
          onTap: () => context.push(AppRoutes.expenses),
        ),
        // Transfer — not yet implemented
        // _QuickAction(
        //   icon: Icons.swap_horiz_rounded,
        //   label: 'Transfer',
        //   iconColor: AppColors.transfer,
        //   bgColor: const Color(0xFFE0F2FE),
        //   onTap: () {},
        // ),
      ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: iconColor.withValues(alpha: 0.15),
          highlightColor: iconColor.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
