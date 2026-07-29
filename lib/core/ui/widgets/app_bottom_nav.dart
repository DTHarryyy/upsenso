import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';

/// Flat bottom nav: a full-width bar with a hairline top border, tabs split
/// evenly around a centered circular scanner button that jumps straight to
/// the POS terminal (branch index 2).
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
    final canUsePOS = service.can(PermissionKeys.navPos) &&
        service.isModuleEnabled('pos');
    final canUseReports = service.can(PermissionKeys.navReports) &&
        service.isModuleEnabled('reports');
    final canUseInventory = service.can(PermissionKeys.navInventory) &&
        service.isModuleEnabled('inventory');
    final canViewProducts = service.can(PermissionKeys.productsView);
    // hasPosByRole: user's role grants POS access regardless of module toggle.
    // Used to distinguish "inventory staff" (never has POS) from "owner with
    // POS module off" — the latter should still get the full nav bar.
    final hasPosByRole = service.can(PermissionKeys.navPos);
    // Derive nav variant from feature access — no hardcoded role strings.
    final isCashierLike = canUsePOS && !canUseReports && !canUseInventory;
    final isInventoryLike = canUseInventory && !hasPosByRole;

    final items = isCashierLike
        ? _cashierItems(canViewProducts: canViewProducts)
        : isInventoryLike
            ? _inventoryStaffItems(canViewProducts: canViewProducts)
            : _fullNavItems(canViewProducts: canViewProducts);

    // The scanner sits in the middle of the row; tabs split around it.
    // Without POS access there's no scanner, so all tabs stay in one run.
    final splitAt = canUsePOS ? (items.length / 2).ceil() : items.length;

    Widget tab(_NavSpec item) => _NavTab(
          spec: item,
          isActive: currentIndex == item.index,
          onTap: () => onTap(item.index),
        );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (final item in items.sublist(0, splitAt)) tab(item),
              if (canUsePOS) _ScannerButton(onTap: () => onTap(2)),
              for (final item in items.sublist(splitAt)) tab(item),
            ],
          ),
        ),
      ),
    );
  }

  // ── Role-specific nav item sets ────────────────────────────────────────

  List<_NavSpec> _cashierItems({required bool canViewProducts}) => [
        const _NavSpec(
          icon: IconlyLight.home,
          activeIcon: IconlyBold.home,
          label: 'Home',
          index: 0,
        ),
        if (canViewProducts)
          const _NavSpec(
            icon: IconlyLight.bag,
            activeIcon: IconlyBold.bag,
            label: 'Products',
            index: 1,
          ),
      ];

  List<_NavSpec> _inventoryStaffItems({required bool canViewProducts}) => [
        const _NavSpec(
          icon: IconlyLight.home,
          activeIcon: IconlyBold.home,
          label: 'Home',
          index: 0,
        ),
        if (canViewProducts)
          const _NavSpec(
            icon: IconlyLight.bag,
            activeIcon: IconlyBold.bag,
            label: 'Products',
            index: 1,
          ),
        const _NavSpec(
          icon: IconlyLight.category,
          activeIcon: IconlyBold.category,
          label: 'Inventory',
          index: 4,
        ),
      ];

  List<_NavSpec> _fullNavItems({required bool canViewProducts}) => [
        const _NavSpec(
          icon: IconlyLight.home,
          activeIcon: IconlyBold.home,
          label: 'Home',
          index: 0,
        ),
        if (canViewProducts)
          const _NavSpec(
            icon: IconlyLight.bag,
            activeIcon: IconlyBold.bag,
            label: 'Products',
            index: 1,
          ),
        const _NavSpec(
          icon: IconlyLight.chart,
          activeIcon: IconlyBold.chart,
          label: 'Reports',
          index: 3,
        ),
        const _NavSpec(
          icon: IconlyLight.category,
          activeIcon: IconlyBold.category,
          label: 'Inventory',
          index: 4,
        ),
      ];
}

class _NavSpec {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;

  const _NavSpec({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
  });
}

class _NavTab extends StatelessWidget {
  final _NavSpec spec;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTab({
    required this.spec,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.brand : AppColors.textMuted;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? spec.activeIcon : spec.icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 4),
            // Fixed-height FittedBox: the label shrinks to fit its slot instead
            // of clipping, even at bumped device text scales.
            SizedBox(
              height: 13,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  spec.label,
                  maxLines: 1,
                  style: getOutfitStyle(
                    fontSize: 10.5,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ScannerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brand,
            ),
            child: const Icon(
              IconlyBold.scan,
              color: AppColors.textInverse,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
