import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:pos/features/notifications/presentation/cubit/notifications_state.dart';

/// Friendly empty state with an icon, headline, and a reset-filter action.
class NotificationsEmptyState extends StatelessWidget {
  final NotificationFilter filter;

  const NotificationsEmptyState({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    final isFiltered = filter != NotificationFilter.all;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 36,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered ? 'No notifications here' : 'All caught up!',
              style: getOutfitStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'There are no notifications matching this filter.'
                  : 'You have no notifications at the moment.',
              style: getOutfitStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFiltered) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => context.read<NotificationsCubit>().setFilter(
                  NotificationFilter.all,
                ),
                icon: const Icon(Icons.filter_list_off_rounded, size: 16),
                label: Text(
                  'Clear Filter',
                  style: getOutfitStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  side: const BorderSide(color: AppColors.brand),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
