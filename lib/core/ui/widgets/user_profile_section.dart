import 'package:flutter/material.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/user_avatar.dart';

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

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 4 : 8,
        vertical: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(
            avatarUrl: userAvatar,
            name: userName,
            radius: 18,
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
          ],
        ],
      ),
    );
  }
}
