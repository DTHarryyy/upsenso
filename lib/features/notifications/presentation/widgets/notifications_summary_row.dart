import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/stat_card.dart';
import 'package:pos/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:pos/features/notifications/presentation/cubit/notifications_state.dart';

/// Four at-a-glance count cards (Unread, Fraud, Low Stock, Approvals).
/// Tapping a card applies the corresponding filter.
class NotificationsSummaryRow extends StatelessWidget {
  final NotificationsState state;

  const NotificationsSummaryRow({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    int unread = 0, fraud = 0, stock = 0, approvals = 0;
    NotificationFilter active = NotificationFilter.all;

    if (state is NotificationsLoaded) {
      final s = state as NotificationsLoaded;
      unread = s.unreadCount;
      fraud = s.unreadFraud;
      stock = s.unreadStock;
      approvals = s.unreadApprovals;
      active = s.activeFilter;
    }

    final cubit = context.read<NotificationsCubit>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: StatCardsRow(
        cards: [
          AppStatCard(
            title: 'Unread',
            value: '$unread',
            icon: IconlyLight.notification,
            iconColor: AppColors.brand,
            isSelected: active == NotificationFilter.unread,
            onTap: () => cubit.setFilter(NotificationFilter.unread),
          ),
          AppStatCard(
            title: 'Fraud Alerts',
            value: '$fraud',
            icon: IconlyBold.danger,
            iconColor: AppColors.error,
            isSelected: active == NotificationFilter.fraud,
            onTap: () => cubit.setFilter(NotificationFilter.fraud),
          ),
          AppStatCard(
            title: 'Low Stock',
            value: '$stock',
            icon: IconlyLight.category,
            iconColor: AppColors.warning,
            isSelected: active == NotificationFilter.stock,
            onTap: () => cubit.setFilter(NotificationFilter.stock),
          ),
          AppStatCard(
            title: 'Pending Approvals',
            value: '$approvals',
            icon: IconlyLight.paper,
            iconColor: const Color(0xFF8B5CF6),
            isSelected: active == NotificationFilter.approvals,
            onTap: () => cubit.setFilter(NotificationFilter.approvals),
          ),
        ],
      ),
    );
  }
}
