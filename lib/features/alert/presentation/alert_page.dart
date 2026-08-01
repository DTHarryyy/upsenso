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
import 'package:pos/core/widgets/app_empty_state.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';

/// The "Unusual Activity" screen.
///
/// Naming split, on purpose: everything a user reads says "unusual activity",
/// while the code and schema behind it stay `fraud*` — see the note on
/// AppFeature.fraudAlerts in core/permissions/app_feature.dart.
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
  // Owned here rather than by AppSearchBar so "Clear filters" can empty the
  // field, not just the cubit's query.
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters(BuildContext context) {
    _searchController.clear();
    context.read<FraudCubit>().clearFilters();
  }

  void _openDetail(BuildContext context, FraudAlert alert) {
    final cubit = context.read<FraudCubit>();
    final canResolve = cubit.canResolveAlert(alert);
    // The detail closes itself from its own context on success. Popping from
    // this page-level context used to target the shell-branch navigator while
    // the desktop dialog lives on the root navigator — the dialog never
    // closed and triage looked like a dead button.
    Future<String?> onSetStatus(AlertStatus status, String? note) =>
        cubit.setStatus(alert, status, note);

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

  // The shell treats /more/fraud as a stacked sub-page, which nulls the app
  // bar, FAB and bottom nav — so this page has to own its own back control or
  // a phone user has no way out of it. Every state gets the bar, including
  // loading and error, which used to be bare Scaffolds.
  Widget _scaffold({required Widget body}) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppSubPageBar(title: 'Unusual Activity'),
      body: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FraudCubit, FraudState>(
      builder: (context, state) {
        if (state is FraudLoading) {
          return _scaffold(
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            ),
          );
        }
        if (state is FraudError) {
          return _scaffold(
            body: AppEmptyState(
              icon: IconlyLight.danger,
              title: 'Could not load alerts',
              message: state.message,
              actionLabel: 'Try again',
              actionIcon: Icons.refresh_rounded,
              onAction: () => context.read<FraudCubit>().load(),
            ),
          );
        }

        final loaded = state as FraudLoaded;
        final alerts = loaded.visibleAlerts;

        return _scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AlertFilterBar(
                  statusFilter: loaded.statusFilter,
                  severityFilter: loaded.severityFilter,
                  statusCounts: loaded.statusCounts,
                  searchController: _searchController,
                  onSearchChanged: context.read<FraudCubit>().search,
                  onStatusChanged: context.read<FraudCubit>().setStatusFilter,
                  onSeverityChanged: context
                      .read<FraudCubit>()
                      .setSeverityFilter,
                ),
                Expanded(
                  child: alerts.isEmpty
                      ? _emptyState(context, isFiltered: loaded.isFiltered)
                      : ListView.separated(
                          itemCount: alerts.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            color: AppColors.borderSoft,
                          ),
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

  Widget _emptyState(BuildContext context, {required bool isFiltered}) {
    if (isFiltered) {
      return AppEmptyState(
        icon: IconlyLight.filter,
        title: 'No matching alerts',
        message: 'Try a different search or clear your filters.',
        actionLabel: 'Clear filters',
        actionIcon: Icons.filter_alt_off_rounded,
        onAction: () => _clearFilters(context),
      );
    }
    return const AppEmptyState(
      icon: IconlyBold.shield_done,
      title: 'Nothing unusual',
      message:
          'Detection runs automatically — unusual refunds, discounts, '
          'stock write-offs, and audit-trail issues will appear here.',
    );
  }
}
