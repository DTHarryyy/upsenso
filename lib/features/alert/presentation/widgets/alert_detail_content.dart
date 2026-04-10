import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/alert/data/alert_model.dart';

class AlertDetailContent extends StatelessWidget {
  final FraudAlert alert;

  const AlertDetailContent({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailHeader(alert: alert),
        const SizedBox(height: 16),
        _ChipsRow(alert: alert),
        const SizedBox(height: 16),
        const Divider(color: AppColors.borderSoft),
        const SizedBox(height: 16),
        _SectionLabel(label: 'Description'),
        const SizedBox(height: 8),
        Text(
          alert.description,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Evidence'),
        const SizedBox(height: 8),
        _EvidenceTable(evidence: alert.evidence),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Related Records'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: alert.relatedRecords.map((record) {
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderSoft),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surfaceAlt,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    record,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _ActionButtons(),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final FraudAlert alert;
  const _DetailHeader({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_icon, color: _iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            alert.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  IconData get _icon {
    switch (alert.type) {
      case AlertType.refund:
        return Icons.replay_rounded;
      case AlertType.priceOverride:
        return Icons.timer_outlined;
      case AlertType.shiftHours:
        return Icons.schedule_rounded;
      case AlertType.inventoryShrinkage:
        return Icons.warning_amber_rounded;
      case AlertType.transferMismatch:
        return Icons.info_outline_rounded;
    }
  }

  Color get _iconColor {
    switch (alert.severity) {
      case AlertSeverity.high:
        return AppColors.error;
      case AlertSeverity.medium:
        return AppColors.warning;
      case AlertSeverity.low:
        return AppColors.info;
    }
  }

  Color get _iconBg {
    switch (alert.severity) {
      case AlertSeverity.high:
        return AppColors.errorSoft;
      case AlertSeverity.medium:
        return AppColors.warningSoft;
      case AlertSeverity.low:
        return AppColors.infoSoft;
    }
  }
}

class _ChipsRow extends StatelessWidget {
  final FraudAlert alert;
  const _ChipsRow({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _DetailChip(
          label: '$_severityLabel Severity',
          bg: _severityBg,
          fg: _severityFg,
        ),
        _DetailChip(
          label: _statusLabel,
          bg: _statusBg,
          fg: _statusFg,
        ),
      ],
    );
  }

  String get _severityLabel {
    switch (alert.severity) {
      case AlertSeverity.high:
        return 'HIGH';
      case AlertSeverity.medium:
        return 'MEDIUM';
      case AlertSeverity.low:
        return 'LOW';
    }
  }

  Color get _severityBg {
    switch (alert.severity) {
      case AlertSeverity.high:
        return AppColors.errorSoft;
      case AlertSeverity.medium:
        return AppColors.warningSoft;
      case AlertSeverity.low:
        return AppColors.infoSoft;
    }
  }

  Color get _severityFg {
    switch (alert.severity) {
      case AlertSeverity.high:
        return AppColors.error;
      case AlertSeverity.medium:
        return AppColors.warning;
      case AlertSeverity.low:
        return AppColors.info;
    }
  }

  String get _statusLabel {
    switch (alert.status) {
      case AlertStatus.newAlert:
        return 'New';
      case AlertStatus.investigating:
        return 'Investigating';
      case AlertStatus.resolved:
        return 'Resolved';
    }
  }

  Color get _statusBg {
    switch (alert.status) {
      case AlertStatus.newAlert:
        return AppColors.errorSoft;
      case AlertStatus.investigating:
        return AppColors.brandSoft;
      case AlertStatus.resolved:
        return AppColors.successSoft;
    }
  }

  Color get _statusFg {
    switch (alert.status) {
      case AlertStatus.newAlert:
        return AppColors.error;
      case AlertStatus.investigating:
        return AppColors.brand;
      case AlertStatus.resolved:
        return AppColors.success;
    }
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _DetailChip({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _EvidenceTable extends StatelessWidget {
  final Map<String, String> evidence;
  const _EvidenceTable({required this.evidence});

  @override
  Widget build(BuildContext context) {
    final entries = evidence.entries.toList();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderSoft),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: List.generate(entries.length, (i) {
          final isLast = i == entries.length - 1;
          return Container(
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(color: AppColors.borderSoft)),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entries[i].key,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  entries[i].value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 480;
        if (isWide) {
          return Row(
            children: [
              _InvestigateButton(),
              const SizedBox(width: 10),
              _ResolvedButton(),
              const SizedBox(width: 10),
              _ExportButton(),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InvestigateButton(),
            const SizedBox(height: 10),
            _ResolvedButton(),
            const SizedBox(height: 10),
            _ExportButton(),
          ],
        );
      },
    );
  }
}

class _InvestigateButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.manage_search_rounded, size: 16),
      label: const Text('Start Investigation'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.warning,
        foregroundColor: AppColors.textInverse,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ResolvedButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
      label: const Text('Mark as Resolved'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.success,
        side: const BorderSide(color: AppColors.success),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.file_copy_outlined, size: 16),
      label: const Text('Export Report'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.borderSoft),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
