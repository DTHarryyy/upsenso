import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Raw role name from the authenticated user (e.g. 'cashier',
  /// 'inventory_staff', 'branch_manager', 'Super Admin').
  final String? userRole;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final role = (userRole ?? '').trim().toLowerCase().replaceAll(' ', '_');
    final isCashier = role == 'cashier';
    final isInventoryStaff = role == 'inventory_staff';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (!isCashier && !isInventoryStaff)
                _buildNavItem(
                  icon: IconlyLight.home,
                  activeIcon: IconlyBold.home,
                  label: 'Dashboard',
                  index: 0,
                ),
              if (!isCashier && !isInventoryStaff)
                _buildNavItem(
                  icon: IconlyLight.bag,
                  activeIcon: IconlyBold.bag,
                  label: 'Products',
                  index: 1,
                ),
              // Center POS button — visible to all except inventory staff
              if (!isInventoryStaff) _buildCenterPOSButton(),
              if (!isCashier && !isInventoryStaff)
                _buildNavItem(
                  icon: IconlyLight.chart,
                  activeIcon: IconlyBold.chart,
                  label: 'Reports',
                  index: 3,
                ),
              if (!isCashier)
                _buildNavItem(
                  icon: IconlyLight.category,
                  activeIcon: IconlyBold.category,
                  label: 'Inventory',
                  index: 4,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterPOSButton() {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(2),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brand,
              ),
              child: Icon(
                IconlyBold.scan,
                color: AppColors.textInverse,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.brand : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.brand : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
