import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/user_avatar.dart';

enum AppSidebarItem { inventory, profile }

class AppSidebar extends StatelessWidget {
  final String userName;
  final String userRole;
  final String? avatarUrl;
  final String? userEmail;
  final AppSidebarItem activeItem;
  final VoidCallback onInventoryTap;
  final VoidCallback onProfileTap;
  final VoidCallback onSettingsTap;
  final VoidCallback onLogoutTap;

  const AppSidebar({
    super.key,
    required this.userName,
    required this.userRole,
    this.avatarUrl,
    this.userEmail,
    required this.activeItem,
    required this.onInventoryTap,
    required this.onProfileTap,
    required this.onSettingsTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                UserAvatar(
                  avatarUrl: avatarUrl,
                  name: userName,
                  email: userEmail,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: getOutfitStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userRole,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: getOutfitStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _SidebarNavTile(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            selected: activeItem == AppSidebarItem.inventory,
            onTap: onInventoryTap,
          ),
          _SidebarNavTile(
            icon: Icons.person_outline,
            label: 'Profile',
            selected: activeItem == AppSidebarItem.profile,
            onTap: onProfileTap,
          ),
          _SidebarNavTile(
            icon: Icons.settings_outlined,
            label: 'Settings',
            selected: false,
            onTap: onSettingsTap,
          ),
          const Spacer(),
          const Divider(height: 1),
          _SidebarNavTile(
            icon: Icons.logout,
            label: 'Log out',
            selected: false,
            iconColor: AppColors.error,
            labelColor: AppColors.error,
            onTap: onLogoutTap,
          ),
        ],
      ),
    );
  }
}


class _SidebarNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _SidebarNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor =
        iconColor ?? (selected ? AppColors.brand : AppColors.textSecondary);
    final resolvedLabelColor =
        labelColor ?? (selected ? AppColors.brandDark : AppColors.textPrimary);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? AppColors.brandSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          leading: Icon(icon, color: resolvedIconColor),
          title: Text(
            label,
            style: getOutfitStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: resolvedLabelColor,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
