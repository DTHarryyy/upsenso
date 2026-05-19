import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/permissions/app_feature.dart';
import 'package:pos/core/permissions/permission_service.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final service = sl<PermissionService>();
    final canUsePOS = service.canAccessFeature(AppFeature.posTerminal);
    final canUseReports = service.canAccessFeature(AppFeature.reportsAnalytics);
    final canUseInventory = service.canAccessFeature(
      AppFeature.inventoryManagement,
    );
    // Derive nav variant from feature access — no hardcoded role strings.
    final isCashierLike = canUsePOS && !canUseReports && !canUseInventory;
    final isInventoryLike = canUseInventory && !canUsePOS;

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
              // ── Cashier-like (POS but no reports/inventory) ─────────────
              if (isCashierLike) ..._cashierItems(),

              // ── Inventory-like (inventory but no POS) ────────────────────
              if (isInventoryLike) ..._inventoryStaffItems(),

              // ── All other roles: full nav bar ─────────────────────────────
              if (!isCashierLike && !isInventoryLike) ..._fullNavItems(),
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

  // ── Role-specific nav item sets ────────────────────────────────────────

  List<Widget> _cashierItems() => [
    _buildNavItem(
      icon: IconlyLight.home,
      activeIcon: IconlyBold.home,
      label: 'Dashboard',
      index: 0,
    ),
    _buildCenterPOSButton(),
    _buildNavItem(
      icon: IconlyLight.bag,
      activeIcon: IconlyBold.bag,
      label: 'Products',
      index: 1,
    ),
  ];

  List<Widget> _inventoryStaffItems() => [
    _buildNavItem(
      icon: IconlyLight.home,
      activeIcon: IconlyBold.home,
      label: 'Dashboard',
      index: 0,
    ),
    _buildNavItem(
      icon: IconlyLight.bag,
      activeIcon: IconlyBold.bag,
      label: 'Products',
      index: 1,
    ),
    _buildNavItem(
      icon: IconlyLight.category,
      activeIcon: IconlyBold.category,
      label: 'Inventory',
      index: 4,
    ),
  ];

  List<Widget> _fullNavItems() => [
    _buildNavItem(
      icon: IconlyLight.home,
      activeIcon: IconlyBold.home,
      label: 'Dashboard',
      index: 0,
    ),
    _buildNavItem(
      icon: IconlyLight.bag,
      activeIcon: IconlyBold.bag,
      label: 'Products',
      index: 1,
    ),
    _buildCenterPOSButton(),
    _buildNavItem(
      icon: IconlyLight.chart,
      activeIcon: IconlyBold.chart,
      label: 'Reports',
      index: 3,
    ),
    _buildNavItem(
      icon: IconlyLight.category,
      activeIcon: IconlyBold.category,
      label: 'Inventory',
      index: 4,
    ),
  ];

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
