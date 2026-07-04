import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/features/alert/data/alert_model.dart';
import 'package:pos/features/alert/presentation/widgets/alert_icons.dart';

class AlertDetailContent extends StatelessWidget {
  final FraudAlert alert;

  /// False hides all triage actions — either the viewer lacks fraud.resolve
  /// or they are the implicated subject (the server enforces both; this is
  /// the UX mirror).
  final bool canResolve;
  final void Function(AlertStatus status, String? note)? onSetStatus;

  const AlertDetailContent({
    super.key,
    required this.alert,
    this.canResolve = false,
    this.onSetStatus,
  });

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
                  const Icon(IconlyLight.paper,
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
        if (alert.resolutionNote?.isNotEmpty == true) ...[
          const SizedBox(height: 20),
          _SectionLabel(label: 'Resolution Note'),
          const SizedBox(height: 8),
          Text(
            alert.resolutionNote!,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
        if (canResolve && onSetStatus != null) ...[
          const SizedBox(height: 24),
          _ActionButtons(alert: alert, onSetStatus: onSetStatus!),
        ],
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

  IconData get _icon => alertIconFor(alert.ruleCode);

  Color get _iconColor {
    switch (alert.severity) {
      case AlertSeverity.critical:
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
      case AlertSeverity.critical:
        return 'CRITICAL';
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
      case AlertSeverity.critical:
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
      case AlertSeverity.critical:
      case AlertSeverity.high:
        return AppColors.error;
      case AlertSeverity.medium:
        return AppColors.warning;
      case AlertSeverity.low:
        return AppColors.info;
    }
  }

  String get _statusLabel => alert.status.label;

  Color get _statusBg {
    switch (alert.status) {
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

  Color get _statusFg {
    switch (alert.status) {
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
  final FraudAlert alert;
  final void Function(AlertStatus status, String? note) onSetStatus;

  const _ActionButtons({required this.alert, required this.onSetStatus});

  @override
  Widget build(BuildContext context) {
    final isOpen = alert.status == AlertStatus.newAlert ||
        alert.status == AlertStatus.investigating;
    final buttons = <Widget>[
      if (alert.status == AlertStatus.newAlert)
        ElevatedButton.icon(
          onPressed: () => onSetStatus(AlertStatus.investigating, null),
          icon: const Icon(IconlyLight.search, size: 16),
          label: const Text('Start Investigation'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: AppColors.textInverse,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      if (isOpen)
        OutlinedButton.icon(
          onPressed: () => _withNote(context, AlertStatus.resolved),
          icon: const Icon(IconlyBold.tick_square, size: 16),
          label: const Text('Mark as Resolved'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.success,
            side: const BorderSide(color: AppColors.success),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      if (isOpen)
        OutlinedButton.icon(
          onPressed: () => _withNote(context, AlertStatus.dismissed),
          icon: const Icon(IconlyLight.close_square, size: 16),
          label: const Text('Dismiss'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.borderSoft),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      if (isOpen)
        OutlinedButton.icon(
          onPressed: () => _withNote(context, AlertStatus.falsePositive),
          icon: const Icon(IconlyLight.shield_done, size: 16),
          label: const Text('Not fraud (false positive)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.borderSoft),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 480;
        if (isWide) {
          return Wrap(spacing: 10, runSpacing: 10, children: buttons);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < buttons.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              buttons[i],
            ],
          ],
        );
      },
    );
  }

  /// Resolving/dismissing is an accountability event — ask for the why.
  /// The note lands on the flag AND in the chained audit entry.
  Future<void> _withNote(BuildContext context, AlertStatus status) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          switch (status) {
            AlertStatus.resolved => 'Resolve alert',
            AlertStatus.falsePositive => 'Mark as false positive',
            _ => 'Dismiss alert',
          },
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'What did you find? (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              switch (status) {
                AlertStatus.resolved => 'Resolve',
                AlertStatus.falsePositive => 'Confirm',
                _ => 'Dismiss',
              },
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final note = controller.text.trim();
      onSetStatus(status, note.isEmpty ? null : note);
    }
    controller.dispose();
  }
}
