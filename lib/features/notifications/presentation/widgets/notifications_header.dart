import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:pos/features/notifications/presentation/cubit/notifications_state.dart';

/// "Mark all as read" action bar shown above the list when unread items exist.
class NotificationsHeader extends StatelessWidget {
  final NotificationsState state;

  const NotificationsHeader({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final hasUnread =
        state is NotificationsLoaded &&
        (state as NotificationsLoaded).unreadCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasUnread)
            OutlinedButton.icon(
              onPressed: () =>
                  context.read<NotificationsCubit>().markAllAsRead(),
              icon: const Icon(IconlyBold.tick_square, size: 16),
              label: Text(
                'Mark All as Read',
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.borderSoft),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
