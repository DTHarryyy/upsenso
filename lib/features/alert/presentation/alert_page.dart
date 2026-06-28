import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/features/alert/data/alert_model.dart';
import 'package:pos/features/alert/presentation/widgets/alert_detail_dialog.dart';
import 'package:pos/features/alert/presentation/widgets/alert_detail_page.dart';
import 'package:pos/features/alert/presentation/widgets/alert_filter_bar.dart';
import 'package:pos/features/alert/presentation/widgets/alert_list_item.dart';
import 'package:pos/core/widgets/stat_card.dart';

class AlertPage extends StatefulWidget {
  const AlertPage({super.key});

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  String _selectedStatus = 'All';
  String _selectedSeverity = 'All Severity';

  List<FraudAlert> get _filteredAlerts {
    return mockFraudAlerts.where((alert) {
      final statusMatch = _selectedStatus == 'All' ||
          (_selectedStatus == 'New' &&
              alert.status == AlertStatus.newAlert) ||
          (_selectedStatus == 'Investigating' &&
              alert.status == AlertStatus.investigating) ||
          (_selectedStatus == 'Resolved' &&
              alert.status == AlertStatus.resolved);

      final severityMatch = _selectedSeverity == 'All Severity' ||
          (_selectedSeverity == 'High' &&
              alert.severity == AlertSeverity.high) ||
          (_selectedSeverity == 'Medium' &&
              alert.severity == AlertSeverity.medium) ||
          (_selectedSeverity == 'Low' && alert.severity == AlertSeverity.low);

      return statusMatch && severityMatch;
    }).toList();
  }

  int get _newCount =>
      mockFraudAlerts.where((a) => a.status == AlertStatus.newAlert).length;

  int get _highCount =>
      mockFraudAlerts.where((a) => a.severity == AlertSeverity.high).length;

  int get _investigatingCount =>
      mockFraudAlerts
          .where((a) => a.status == AlertStatus.investigating)
          .length;

  int get _resolvedCount =>
      mockFraudAlerts.where((a) => a.status == AlertStatus.resolved).length;

  void _openDetail(BuildContext context, FraudAlert alert) {
    if (Breakpoints.isDesktop(context)) {
      showDialog(
        context: context,
        builder: (_) => AlertDetailDialog(alert: alert),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AlertDetailPage(alert: alert)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _filteredAlerts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(totalCount: mockFraudAlerts.length),
            _StatCardsSection(
              newCount: _newCount,
              highCount: _highCount,
              investigatingCount: _investigatingCount,
              resolvedCount: _resolvedCount,
            ),
            AlertFilterBar(
              selectedStatus: _selectedStatus,
              selectedSeverity: _selectedSeverity,
              newCount: _newCount,
              onStatusChanged: (v) => setState(() => _selectedStatus = v),
              onSeverityChanged: (v) => setState(() => _selectedSeverity = v),
            ),
            Expanded(
              child: alerts.isEmpty
                  ? const _EmptyState()
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
              'Fraud Alerts',
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
              color: AppColors.errorSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$totalCount alerts',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
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
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(IconlyLight.shield_done, size: 48, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text(
            'No alerts found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try adjusting your filters',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
