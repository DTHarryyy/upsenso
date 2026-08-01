import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/features/notifications/domain/entities/billing_notice.dart';
import 'package:pos/features/notifications/domain/entities/notification_item.dart';
import 'package:pos/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:pos/features/notifications/presentation/widgets/billing_notice_visuals.dart';

/// A single row in the notification list.
class NotificationTile extends StatelessWidget {
  final NotificationItem item;

  const NotificationTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // Null for every real row. Resolved once so the three branches below all
    // key off the same answer.
    final notice = billingNoticeKindOf(item);
    final config = _NotificationConfig.of(item, notice);

    return Container(
      color: item.isRead ? AppColors.surface : AppColors.brand.withAlpha(6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: config.softColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(config.icon, size: 18, color: config.color),
          ),
          const SizedBox(width: 14),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: getOutfitStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 6, top: 3),
                        decoration: const BoxDecoration(
                          color: AppColors.brand,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.body,
                  style: getOutfitStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                // A standing status notice, not a one-time event — no
                // "time ago" to show for it.
                if (notice == null) ...[
                  const SizedBox(height: 5),
                  Text(
                    _timeAgo(item.createdAt),
                    style: getOutfitStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: notice != null
                ? [
                    NotificationActionBtn(
                      label: notice.ctaLabel,
                      onTap: () => context.push(AppRoutes.billing),
                    ),
                  ]
                : [
                    NotificationActionBtn(
                      label: 'View',
                      onTap: () {
                        if (!item.isRead) {
                          context.read<NotificationsCubit>().markAsRead(
                            item.id,
                          );
                        }
                        _openReference(context);
                      },
                    ),
                    if (!item.isRead) ...[
                      const SizedBox(width: 4),
                      NotificationIconBtn(
                        icon: IconlyLight.tick_square,
                        tooltip: 'Mark as read',
                        onTap: () => context
                            .read<NotificationsCubit>()
                            .markAsRead(item.id),
                      ),
                    ],
                    const SizedBox(width: 4),
                    NotificationIconBtn(
                      icon: IconlyLight.delete,
                      tooltip: 'Delete',
                      color: AppColors.error,
                      onTap: () =>
                          context.read<NotificationsCubit>().delete(item.id),
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  // Deep-link to the entity that raised the notification. Only purchase-order
  // references are wired today; other types simply mark-as-read.
  void _openReference(BuildContext context) {
    final ref = item.referenceId;
    if (item.referenceType == 'purchase_order' && ref != null) {
      context.push(AppRoutes.poDetail, extra: ref);
    }
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}

// ─── Action buttons ───────────────────────────────────────────────────────────

class NotificationActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const NotificationActionBtn({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderSoft),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: getOutfitStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class NotificationIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const NotificationIconBtn({
    super.key,
    required this.icon,
    required this.tooltip,
    this.color = AppColors.textMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ─── Icon / colour config ─────────────────────────────────────────────────────

class _NotificationConfig {
  final IconData icon;
  final Color color;
  final Color softColor;

  const _NotificationConfig({
    required this.icon,
    required this.color,
    required this.softColor,
  });

  factory _NotificationConfig.of(
    NotificationItem item,
    BillingNoticeKind? notice,
  ) {
    if (notice != null) {
      return _NotificationConfig(
        icon: notice.icon,
        color: notice.color,
        softColor: notice.softColor,
      );
    }
    switch (item.type) {
      case NotificationType.fraud:
        return _NotificationConfig(
          icon: IconlyBold.danger,
          color: item.severity == NotificationSeverity.high
              ? AppColors.error
              : AppColors.warning,
          softColor: item.severity == NotificationSeverity.high
              ? AppColors.errorSoft
              : AppColors.warningSoft,
        );
      case NotificationType.lowStock:
        return const _NotificationConfig(
          icon: IconlyLight.category,
          color: AppColors.warning,
          softColor: AppColors.warningSoft,
        );
      case NotificationType.syncConflict:
        return const _NotificationConfig(
          icon: Icons.sync_problem_rounded,
          color: AppColors.brand,
          softColor: AppColors.brandSoft,
        );
      case NotificationType.expenseApproval:
        return const _NotificationConfig(
          icon: IconlyLight.paper,
          color: Color(0xFF8B5CF6),
          softColor: Color(0xFFF3F0FF),
        );
      case NotificationType.poApproval:
        return const _NotificationConfig(
          icon: IconlyLight.bag,
          color: AppColors.brand,
          softColor: AppColors.brandSoft,
        );
      case NotificationType.cashDiscrepancy:
        return const _NotificationConfig(
          icon: IconlyLight.wallet,
          color: AppColors.warning,
          softColor: AppColors.warningSoft,
        );
      case NotificationType.system:
        return const _NotificationConfig(
          icon: IconlyLight.notification,
          color: AppColors.textMuted,
          softColor: AppColors.surfaceAlt,
        );
      case NotificationType.billing:
        return const _NotificationConfig(
          icon: Icons.cloud_off_outlined,
          color: AppColors.warning,
          softColor: AppColors.warningSoft,
        );
    }
  }
}
