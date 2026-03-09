import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';

class UserProfileSection extends StatelessWidget {
  final String userName;
  final String userRole;
  final String? userAvatar;

  const UserProfileSection({
    super.key,
    required this.userName,
    required this.userRole,
    this.userAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = !Breakpoints.isTablet(context);
    Future<void> _showLogoutDialog(BuildContext context) async {
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ],
          );
        },
      );

      if (shouldLogout == true && context.mounted) {
        context.read<AuthBloc>().add(AuthLogoutRequested());
      }
    }

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 4 : 8,
          vertical: 2,
        ),
        child: PopupMenuButton<_UserProfileMenuAction>(
          offset: Offset(0, 40),

          onSelected: (action) {
            switch (action) {
              case _UserProfileMenuAction.profile:
                debugPrint("Profile clicked");
                break;

              case _UserProfileMenuAction.settings:
                debugPrint("Settings clicked");
                break;

              case _UserProfileMenuAction.logout:
                _showLogoutDialog(context);
                break;
            }
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          color: Theme.of(context).cardColor,

          itemBuilder: (context) => [
            PopupMenuItem(
              height: 32,
              value: _UserProfileMenuAction.profile,
              child: Row(
                children: [
                  Icon(Icons.person, size: 18, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text(
                    "Profile",
                    style: getOutfitStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              height: 32,
              value: _UserProfileMenuAction.settings,
              child: Row(
                children: [
                  Icon(
                    Icons.settings,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Settings",
                    style: getOutfitStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              height: 32,
              value: _UserProfileMenuAction.logout,
              child: Row(
                children: const [
                  Icon(Icons.logout, size: 18, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text("Logout", style: TextStyle(color: Colors.redAccent)),
                ],
              ),
            ),
          ],

          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brand, width: 1.5),
                ),
                child: userAvatar != null && userAvatar!.startsWith('http')
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(userAvatar!, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(
                          _getInitials(userName),
                          style: getOutfitStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
              ),

              if (!isMobile) ...[
                const SizedBox(width: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userName,
                      style: getOutfitStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      userRole,
                      style: getOutfitStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 4),

                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(" ");
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

enum _UserProfileMenuAction { profile, settings, logout }
