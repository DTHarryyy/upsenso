import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/table_action_button.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/audit_logs/domain/entities/audit_log.dart';

/// Builds the list of table cells for a single [AuditLog] row.
///
/// Used by [AuditLogPage] as the `rowCellsBuilder` for [AppDataTable].
/// Each element maps 1-to-1 with the audit log table columns.
List<Widget> auditLogTableCells(
  BuildContext context,
  AuditLog log, {
  VoidCallback? onViewDetails,
}) {
  final color = _colorFor(log.actionType);
  final badgeLabel = _badgeLabelFor(log.actionType);

  return [
    // ── Timestamp ────────────────────────────────────────────────────────
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppFormatters.shortDate(log.createdAt.toLocal()),
          style: getOutfitStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          AppFormatters.time12h(log.createdAt.toLocal()),
          style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    ),

    // ── Action badge ─────────────────────────────────────────────────────
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        badgeLabel,
        style: getOutfitStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // ── Entity ───────────────────────────────────────────────────────────
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _capitalize(log.entityType),
          style: getOutfitStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (log.entityName != null && log.entityName!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            log.entityName!,
            style: getOutfitStyle(fontSize: 11, color: AppColors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    ),

    // ── User ─────────────────────────────────────────────────────────────
    Text(
      log.userName ?? log.userId,
      style: getOutfitStyle(fontSize: 13, color: AppColors.textSecondary),
      overflow: TextOverflow.ellipsis,
    ),

    // ── Branch ───────────────────────────────────────────────────────────
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.store_outlined, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            log.branchName ?? 'All Branches',
            style: getOutfitStyle(fontSize: 13, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),

    // ── Device / IP ──────────────────────────────────────────────────────
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.devices_outlined,
          size: 13,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            log.deviceId,
            style: getOutfitStyle(fontSize: 12, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),

    // ── Details (eye button) ─────────────────────────────────────────────
    TableActionButton(
      icon: Icons.visibility_outlined,
      color: onViewDetails != null ? AppColors.brand : AppColors.textMuted,
      background: AppColors.brandSoft,
      tooltip: 'View details',
      onTap: onViewDetails ?? () {},
    ),
  ];
}

// ── Details bottom sheet ───────────────────────────────────────────────────

/// Shows a bottom sheet (or dialog on desktop) with the log's full metadata.
void showAuditLogDetails(BuildContext context, AuditLog log) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (_) => _AuditLogDetailSheet(log: log),
  );
}

class _AuditLogDetailSheet extends StatelessWidget {
  final AuditLog log;
  const _AuditLogDetailSheet({required this.log});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(log.actionType);
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _badgeLabelFor(log.actionType),
                    style: getOutfitStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    log.description,
                    style: getOutfitStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSoft),
          // Body
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                _DetailRow(
                  'Timestamp',
                  '${AppFormatters.shortDate(log.createdAt.toLocal())}  ${AppFormatters.time12h(log.createdAt.toLocal())}',
                ),
                _DetailRow(
                  'Entity',
                  '${_capitalize(log.entityType)}'
                      '${log.entityName != null && log.entityName!.isNotEmpty ? ' · ${log.entityName}' : ''}',
                ),
                _DetailRow('User', log.userName ?? log.userId),
                _DetailRow('Branch', log.branchName ?? 'All Branches'),
                _DetailRow('Device', log.deviceId),
                if (log.metadata.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'METADATA',
                    style: getOutfitStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...log.metadata.entries
                      .where((e) => !e.key.startsWith('_'))
                      .map((e) => _DetailRow(_formatKey(e.key), '${e.value}')),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatKey(String k) => k
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: getOutfitStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: getOutfitStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

// ── Mobile card ────────────────────────────────────────────────────────────

/// Compact card for a single [AuditLog] — used on narrow screens.
Widget auditLogMobileCard(
  BuildContext context,
  AuditLog log, {
  VoidCallback? onTap,
}) {
  final color = _colorFor(log.actionType);
  final badgeLabel = _badgeLabelFor(log.actionType);

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap ?? () => showAuditLogDetails(context, log),
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left color accent ───────────────────────────────────────
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),

              // ── Card body ───────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header: badge + timestamp ───────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeLabel,
                              style: getOutfitStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                AppFormatters.shortDate(
                                  log.createdAt.toLocal(),
                                ),
                                style: getOutfitStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                AppFormatters.time12h(log.createdAt.toLocal()),
                                style: getOutfitStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ── Entity + description ────────────────────────────
                      RichText(
                        text: TextSpan(
                          style: getOutfitStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          children: [
                            TextSpan(text: _capitalize(log.entityType)),
                            if (log.entityName != null &&
                                log.entityName!.isNotEmpty)
                              TextSpan(
                                text: '  ·  ${log.entityName}',
                                style: getOutfitStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        log.description,
                        style: getOutfitStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 10),
                      const Divider(height: 1, color: AppColors.borderSoft),
                      const SizedBox(height: 10),

                      // ── Footer: user + branch chips ─────────────────────
                      Row(
                        children: [
                          Flexible(
                            child: _InfoChip(
                              icon: Icons.person_outline_rounded,
                              label: log.userName ?? log.userId,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: _InfoChip(
                              icon: Icons.store_outlined,
                              label: log.branchName ?? 'All Branches',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: getOutfitStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

String _badgeLabelFor(AuditLogActionType type) {
  switch (type) {
    case AuditLogActionType.saleCreated:
    case AuditLogActionType.refundCreated:
    case AuditLogActionType.expenseCreated:
    case AuditLogActionType.stockAdded:
      return 'CREATE';
    case AuditLogActionType.stockUpdated:
    case AuditLogActionType.stockTransferred:
    case AuditLogActionType.discountApplied:
      return 'UPDATE';
    case AuditLogActionType.stockAdjusted:
      return 'ADJUST';
    case AuditLogActionType.saleVoided:
    case AuditLogActionType.expenseRejected:
      return 'DELETE';
    case AuditLogActionType.expenseApproved:
      return 'APPROVE';
    case AuditLogActionType.userLogin:
      return 'LOGIN';
    case AuditLogActionType.userLogout:
      return 'LOGOUT';
    case AuditLogActionType.syncStarted:
    case AuditLogActionType.syncCompleted:
    case AuditLogActionType.syncFailed:
      return 'SYNC';
    case AuditLogActionType.employeeCreated:
      return 'CREATE';
    case AuditLogActionType.employeeUpdated:
    case AuditLogActionType.employeeRoleChanged:
    case AuditLogActionType.employeeStatusChanged:
    case AuditLogActionType.employeeDuplicateDetected:
      return 'UPDATE';
    case AuditLogActionType.employeeArchived:
      return 'ARCHIVE';
    case AuditLogActionType.employeeRestored:
      return 'RESTORE';
    case AuditLogActionType.permissionDenied:
      return 'DENIED';
    case AuditLogActionType.refundApprovedByManager:
    case AuditLogActionType.voidApprovedByManager:
    case AuditLogActionType.stockAdjustmentApproved:
    case AuditLogActionType.stockTransferApproved:
      return 'APPROVE';
  }
}

Color _colorFor(AuditLogActionType type) {
  switch (type) {
    case AuditLogActionType.saleCreated:
    case AuditLogActionType.stockAdded:
    case AuditLogActionType.expenseApproved:
    case AuditLogActionType.syncCompleted:
      return AppColors.success;
    case AuditLogActionType.saleVoided:
    case AuditLogActionType.expenseRejected:
    case AuditLogActionType.syncFailed:
      return AppColors.error;
    case AuditLogActionType.refundCreated:
    case AuditLogActionType.stockUpdated:
    case AuditLogActionType.stockTransferred:
    case AuditLogActionType.syncStarted:
      return AppColors.brand;
    case AuditLogActionType.discountApplied:
    case AuditLogActionType.stockAdjusted:
      return AppColors.warning;
    case AuditLogActionType.expenseCreated:
      return AppColors.brand;
    case AuditLogActionType.userLogin:
    case AuditLogActionType.userLogout:
      return const Color(0xFF8B5CF6); // violet
    case AuditLogActionType.employeeCreated:
    case AuditLogActionType.employeeUpdated:
    case AuditLogActionType.employeeRoleChanged:
    case AuditLogActionType.employeeStatusChanged:
    case AuditLogActionType.employeeRestored:
      return AppColors.brand;
    case AuditLogActionType.employeeArchived:
    case AuditLogActionType.employeeDuplicateDetected:
      return AppColors.warning;
    case AuditLogActionType.permissionDenied:
      return AppColors.error;
    case AuditLogActionType.refundApprovedByManager:
    case AuditLogActionType.voidApprovedByManager:
    case AuditLogActionType.stockAdjustmentApproved:
    case AuditLogActionType.stockTransferApproved:
      return AppColors.success;
  }
}
