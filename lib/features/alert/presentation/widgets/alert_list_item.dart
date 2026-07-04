import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/alert/data/alert_model.dart';
import 'package:pos/features/alert/presentation/widgets/alert_icons.dart';

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
              _AlertTypeIcon(ruleCode: alert.ruleCode, severity: alert.severity),
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
  final String ruleCode;
  final AlertSeverity severity;

  const _AlertTypeIcon({required this.ruleCode, required this.severity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Icon(alertIconFor(ruleCode), color: _iconColor, size: 20),
    );
  }

  Color get _iconColor {
    switch (severity) {
      case AlertSeverity.critical:
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
      case AlertSeverity.critical:
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
      case AlertSeverity.critical:
        return 'critical';
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
      case AlertSeverity.critical:
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
      case AlertSeverity.critical:
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

  String get _label => status.label;

  Color get _bg {
    switch (status) {
      case AlertStatus.newAlert:
        return AppColors.errorSoft;
      case AlertStatus.investigating:
        return AppColors.brandSoft;
      case AlertStatus.resolved:
        return AppColors.successSoft;
      case AlertStatus.dismissed:
      case AlertStatus.falsePositive:
        return AppColors.surfaceAlt;
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
      case AlertStatus.dismissed:
      case AlertStatus.falsePositive:
        return AppColors.textMuted;
    }
  }
}
