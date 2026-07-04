import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/fraud_flags_dao.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/features/alert/data/alert_model.dart';
import 'package:pos/features/alert/presentation/cubit/fraud_cubit.dart';
import 'package:pos/features/alert/presentation/cubit/fraud_state.dart';
import 'package:pos/features/alert/presentation/widgets/alert_detail_dialog.dart';
import 'package:pos/features/alert/presentation/widgets/alert_detail_page.dart';
import 'package:pos/features/alert/presentation/widgets/alert_filter_bar.dart';
import 'package:pos/features/alert/presentation/widgets/alert_list_item.dart';
import 'package:pos/core/widgets/stat_card.dart';

class AlertPage extends StatelessWidget {
  const AlertPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FraudCubit(
        flagsDao: sl<FraudFlagsDao>(),
        db: sl<AppDatabase>(),
        permissionService: sl<PermissionService>(),
        activeBusinessContext: sl<ActiveBusinessContext>(),
        auditLogService: sl<AuditLogService>(),
      )..load(),
      child: const _AlertView(),
    );
  }
}

class _AlertView extends StatefulWidget {
  const _AlertView();

  @override
  State<_AlertView> createState() => _AlertViewState();
}

class _AlertViewState extends State<_AlertView> {
  String _selectedStatus = 'All';
  String _selectedSeverity = 'All Severity';

  List<FraudAlert> _filtered(List<FraudAlert> alerts) {
    return alerts.where((alert) {
      final statusMatch = _selectedStatus == 'All' ||
          (_selectedStatus == 'New' && alert.status == AlertStatus.newAlert) ||
          (_selectedStatus == 'Investigating' &&
              alert.status == AlertStatus.investigating) ||
          (_selectedStatus == 'Resolved' &&
              alert.status == AlertStatus.resolved) ||
          (_selectedStatus == 'Dismissed' &&
              (alert.status == AlertStatus.dismissed ||
                  alert.status == AlertStatus.falsePositive));

      final severityMatch = _selectedSeverity == 'All Severity' ||
          (_selectedSeverity == 'Critical' &&
              alert.severity == AlertSeverity.critical) ||
          (_selectedSeverity == 'High' &&
              alert.severity == AlertSeverity.high) ||
          (_selectedSeverity == 'Medium' &&
              alert.severity == AlertSeverity.medium) ||
          (_selectedSeverity == 'Low' && alert.severity == AlertSeverity.low);

      return statusMatch && severityMatch;
    }).toList();
  }

  void _openDetail(BuildContext context, FraudAlert alert) {
    final cubit = context.read<FraudCubit>();
    final canResolve = cubit.canResolveAlert(alert);
    void onSetStatus(AlertStatus status, String? note) {
      cubit.setStatus(alert, status, note);
      Navigator.of(context).pop();
    }

    if (Breakpoints.isDesktop(context)) {
      showDialog(
        context: context,
        builder: (_) => AlertDetailDialog(
          alert: alert,
          canResolve: canResolve,
          onSetStatus: onSetStatus,
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlertDetailPage(
            alert: alert,
            canResolve: canResolve,
            onSetStatus: onSetStatus,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FraudCubit, FraudState>(
      builder: (context, state) {
        if (state is FraudLoading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            ),
          );
        }
        if (state is FraudError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                state.message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        final all = (state as FraudLoaded).alerts;
        final alerts = _filtered(all);
        final newCount =
            all.where((a) => a.status == AlertStatus.newAlert).length;
        final highCount = all
            .where((a) =>
                a.severity == AlertSeverity.high ||
                a.severity == AlertSeverity.critical)
            .length;
        final investigatingCount =
            all.where((a) => a.status == AlertStatus.investigating).length;
        final resolvedCount =
            all.where((a) => a.status == AlertStatus.resolved).length;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PageHeader(totalCount: all.length),
                _StatCardsSection(
                  newCount: newCount,
                  highCount: highCount,
                  investigatingCount: investigatingCount,
                  resolvedCount: resolvedCount,
                ),
                AlertFilterBar(
                  selectedStatus: _selectedStatus,
                  selectedSeverity: _selectedSeverity,
                  newCount: newCount,
                  onStatusChanged: (v) => setState(() => _selectedStatus = v),
                  onSeverityChanged: (v) =>
                      setState(() => _selectedSeverity = v),
                ),
                Expanded(
                  child: alerts.isEmpty
                      ? _EmptyState(hasAny: all.isNotEmpty)
                      : ListView.separated(
                          itemCount: alerts.length,
                          separatorBuilder: (_, _) => const Divider(
                              height: 1, color: AppColors.borderSoft),
                          itemBuilder: (context, i) => AlertListItem(
                            alert: alerts[i],
                            onTap: () => _openDetail(context, alerts[i]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  final int totalCount;
  const _PageHeader({required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Fraud & Risk',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: totalCount > 0 ? AppColors.errorSoft : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$totalCount alert${totalCount == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: totalCount > 0 ? AppColors.error : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardsSection extends StatelessWidget {
  final int newCount;
  final int highCount;
  final int investigatingCount;
  final int resolvedCount;

  const _StatCardsSection({
    required this.newCount,
    required this.highCount,
    required this.investigatingCount,
    required this.resolvedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: StatCardsRow(
        cards: [
          AppStatCard(
            title: 'New Alerts',
            value: '$newCount',
            icon: IconlyBold.danger,
            iconColor: AppColors.error,
          ),
          AppStatCard(
            title: 'High Severity',
            value: '$highCount',
            icon: IconlyLight.danger,
            iconColor: AppColors.warning,
          ),
          AppStatCard(
            title: 'Investigating',
            value: '$investigatingCount',
            icon: IconlyLight.search,
            iconColor: AppColors.info,
          ),
          AppStatCard(
            title: 'Resolved',
            value: '$resolvedCount',
            icon: IconlyBold.tick_square,
            iconColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasAny;
  const _EmptyState({required this.hasAny});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(IconlyLight.shield_done,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            hasAny ? 'No alerts match these filters' : 'No fraud alerts',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasAny
                ? 'Try adjusting your filters'
                : 'Detection runs automatically — unusual refunds, discounts, '
                    'stock write-offs, and audit-trail issues will appear here.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
