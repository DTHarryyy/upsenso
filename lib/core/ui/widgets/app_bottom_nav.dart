import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';

/// Floating bottom nav: a rounded pill holds the regular tabs, and a
/// standalone circular scanner button sits to its right — tapping it jumps
/// straight to the POS terminal (branch index 2).
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Row(
          children: [
            // ── Tab pill ─────────────────────────────────────────────────
            Expanded(
              child: Container(
                height: 62,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(31),
                  border: Border.all(color: AppColors.borderSoft),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    for (final item in items)
                      _NavPillItem(
                        spec: item,
                        isActive: currentIndex == item.index,
                        onTap: () => onTap(item.index),
                      ),
                  ],
                ),
              ),
            ),

            // ── Standalone scanner button → POS terminal ─────────────────
            if (canUsePOS) ...[
              const SizedBox(width: 10),
              _ScannerButton(onTap: () => onTap(2)),
            ],
          ],
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

class _NavPillItem extends StatelessWidget {
  final _NavSpec spec;
  final bool isActive;
  final VoidCallback onTap;

  const _NavPillItem({
    required this.spec,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          // Full-slot stadium highlight — hugging the content squeezed the
          // label into clipped text on narrow screens.
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isActive ? AppColors.brandSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cross-fade + gentle scale between the light and bold glyph
                // so the icon swap doesn't pop.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Icon(
                    isActive ? spec.activeIcon : spec.icon,
                    key: ValueKey<bool>(isActive),
                    color: isActive ? AppColors.brand : AppColors.textMuted,
                    size: 21,
                  ),
                ),
                const SizedBox(height: 3),
                // Fixed-height FittedBox: the label shrinks to fit its slot
                // instead of clipping, even at bumped device text scales.
                SizedBox(
                  height: 13,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      style: getOutfitStyle(
                        fontSize: 10.5,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color:
                            isActive ? AppColors.brand : AppColors.textMuted,
                      ),
                      child: Text(spec.label, maxLines: 1),
                    ),
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

class _ScannerButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ScannerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brand,
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          IconlyBold.scan,
          color: AppColors.textInverse,
          size: 26,
        ),
      ),
    );
  }
}
