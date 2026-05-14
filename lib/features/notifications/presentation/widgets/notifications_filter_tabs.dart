import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:pos/features/notifications/presentation/cubit/notifications_state.dart';

/// Horizontal scrollable chip bar for filtering notifications by type.
class NotificationsFilterTabs extends StatelessWidget {
  final NotificationsState state;

  const NotificationsFilterTabs({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final active = state is NotificationsLoaded
        ? (state as NotificationsLoaded).activeFilter
        : NotificationFilter.all;
    final unreadCount = state is NotificationsLoaded
        ? (state as NotificationsLoaded).unreadCount
        : 0;

    final tabs = [
      _Tab(label: 'All', filter: NotificationFilter.all),
      _Tab(
        label: 'Unread',
        filter: NotificationFilter.unread,
        badge: unreadCount,
      ),
      _Tab(label: 'Fraud', filter: NotificationFilter.fraud),
      _Tab(label: 'Stock', filter: NotificationFilter.stock),
      _Tab(label: 'Approvals', filter: NotificationFilter.approvals),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              tabs
                  .map(
                    (t) => _TabChip(
                      tab: t,
                      isActive: active == t.filter,
                      onTap: () => context.read<NotificationsCubit>().setFilter(
                        t.filter,
                      ),
                    ),
                  )
                  .expand((w) => [w, const SizedBox(width: 6)])
                  .toList()
                ..removeLast(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Tab {
  final String label;
  final NotificationFilter filter;
  final int badge;
  const _Tab({required this.label, required this.filter, this.badge = 0});
}

class _TabChip extends StatelessWidget {
  final _Tab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _TabChip({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.brand : AppColors.borderSoft,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tab.label,
              style: getOutfitStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
            if (tab.badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withAlpha(60)
                      : AppColors.brand,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${tab.badge}',
                  style: getOutfitStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
