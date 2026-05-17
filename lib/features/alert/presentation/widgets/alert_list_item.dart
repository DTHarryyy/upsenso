import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/alert/data/alert_model.dart';

class AlertListItem extends StatelessWidget {
  final FraudAlert alert;
  final VoidCallback onTap;

  const AlertListItem({
    super.key,
    required this.alert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AlertTypeIcon(type: alert.type, severity: alert.severity),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _SeverityChip(severity: alert.severity),
                        _StatusChip(status: alert.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _MetaItem(
                          icon: IconlyLight.profile,
                          label: alert.author,
                        ),
                        _MetaItem(
                          icon: IconlyBold.work,
                          label: alert.store,
                        ),
                        _MetaItem(
                          icon: IconlyLight.calendar,
                          label: _formatDate(alert.date),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(IconlyLight.arrow_right_2,
                  size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, $hour:$minute $amPm';
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _AlertTypeIcon extends StatelessWidget {
  final AlertType type;
  final AlertSeverity severity;

  const _AlertTypeIcon({required this.type, required this.severity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Icon(_icon, color: _iconColor, size: 20),
    );
  }

  IconData get _icon {
    switch (type) {
      case AlertType.refund:
        return IconlyLight.arrow_left;
      case AlertType.priceOverride:
        return IconlyLight.time_circle;
      case AlertType.shiftHours:
        return IconlyLight.time_circle;
      case AlertType.inventoryShrinkage:
        return IconlyBold.danger;
      case AlertType.transferMismatch:
        return IconlyLight.info_circle;
    }
  }

  Color get _iconColor {
    switch (severity) {
      case AlertSeverity.high:
        return AppColors.error;
      case AlertSeverity.medium:
        return AppColors.warning;
      case AlertSeverity.low:
        return AppColors.info;
    }
  }

  Color get _bgColor {
    switch (severity) {
      case AlertSeverity.high:
        return AppColors.errorSoft;
      case AlertSeverity.medium:
        return AppColors.warningSoft;
      case AlertSeverity.low:
        return AppColors.infoSoft;
    }
  }
}

class _SeverityChip extends StatelessWidget {
  final AlertSeverity severity;
  const _SeverityChip({required this.severity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _fg,
        ),
      ),
    );
  }

  String get _label {
    switch (severity) {
      case AlertSeverity.high:
        return 'high';
      case AlertSeverity.medium:
        return 'medium';
      case AlertSeverity.low:
        return 'low';
    }
  }

  Color get _bg {
    switch (severity) {
      case AlertSeverity.high:
        return AppColors.error;
      case AlertSeverity.medium:
        return AppColors.warningSoft;
      case AlertSeverity.low:
        return AppColors.infoSoft;
    }
  }

  Color get _fg {
    switch (severity) {
      case AlertSeverity.high:
        return AppColors.textInverse;
      case AlertSeverity.medium:
        return AppColors.warning;
      case AlertSeverity.low:
        return AppColors.info;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final AlertStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _fg,
        ),
      ),
    );
  }

  String get _label {
    switch (status) {
      case AlertStatus.newAlert:
        return 'New';
      case AlertStatus.investigating:
        return 'Investigating';
      case AlertStatus.resolved:
        return 'Resolved';
    }
  }

  Color get _bg {
    switch (status) {
      case AlertStatus.newAlert:
        return AppColors.errorSoft;
      case AlertStatus.investigating:
        return AppColors.brandSoft;
      case AlertStatus.resolved:
        return AppColors.successSoft;
    }
  }

  Color get _fg {
    switch (status) {
      case AlertStatus.newAlert:
        return AppColors.error;
      case AlertStatus.investigating:
        return AppColors.brand;
      case AlertStatus.resolved:
        return AppColors.success;
    }
  }
}
