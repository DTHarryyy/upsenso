import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          final cards = [
            _SummaryCard(
              label: 'Unread',
              count: unread,
              color: AppColors.brand,
              isSelected: active == NotificationFilter.unread,
              onTap: () => context.read<NotificationsCubit>().setFilter(
                NotificationFilter.unread,
              ),
            ),
            _SummaryCard(
              label: 'Fraud Alerts',
              count: fraud,
              color: AppColors.error,
              isSelected: active == NotificationFilter.fraud,
              onTap: () => context.read<NotificationsCubit>().setFilter(
                NotificationFilter.fraud,
              ),
            ),
            _SummaryCard(
              label: 'Low Stock',
              count: stock,
              color: AppColors.warning,
              isSelected: active == NotificationFilter.stock,
              onTap: () => context.read<NotificationsCubit>().setFilter(
                NotificationFilter.stock,
              ),
            ),
            _SummaryCard(
              label: 'Pending Approvals',
              count: approvals,
              color: const Color(0xFF8B5CF6),
              isSelected: active == NotificationFilter.approvals,
              onTap: () => context.read<NotificationsCubit>().setFilter(
                NotificationFilter.approvals,
              ),
            ),
          ];

          if (isNarrow) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 10),
                    Expanded(child: cards[1]),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: cards[2]),
                    const SizedBox(width: 10),
                    Expanded(child: cards[3]),
                  ],
                ),
              ],
            );
          }

          return Row(
            children:
                cards
                    .map((c) => Expanded(child: c))
                    .expand((w) => [w, const SizedBox(width: 12)])
                    .toList()
                  ..removeLast(),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(18) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.borderSoft,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: getOutfitStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
