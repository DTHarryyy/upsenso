import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/widgets/app_data_table.dart';
import 'package:pos/features/audit_logs/domain/repositories/i_audit_log_repository.dart';
import 'package:pos/features/audit_logs/presentation/bloc/audit_log_bloc.dart';
import 'package:pos/features/audit_logs/presentation/bloc/audit_log_event.dart';
import 'package:pos/features/audit_logs/presentation/bloc/audit_log_state.dart';
import 'package:pos/features/audit_logs/presentation/widgets/audit_log_filter_bar.dart';
import 'package:pos/features/audit_logs/presentation/widgets/audit_log_tile.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';

class AuditLogPage extends StatelessWidget {
  const AuditLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuditLogBloc(repository: sl<IAuditLogRepository>()),
      child: const _AuditLogView(),
    );
  }
}

class _AuditLogView extends StatefulWidget {
  const _AuditLogView();

  @override
  State<_AuditLogView> createState() => _AuditLogViewState();
}

class _AuditLogViewState extends State<_AuditLogView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    context.read<AuditLogBloc>().add(
      LoadAuditLogs(businessId: authState.user.businessId ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BranchCubit, BranchState>(
      listener: (_, _) => _load(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text('Audit Logs', style: AppTextStyles.title(context)),
          leading: (ModalRoute.of(context)?.canPop ?? false)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
          actions: [
            BlocBuilder<AuditLogBloc, AuditLogState>(
              builder: (context, state) => IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                color: AppColors.brand,
                onPressed: () =>
                    context.read<AuditLogBloc>().add(const RefreshAuditLogs()),
              ),
            ),
          ],
        ),
        body: const Column(
          children: [
            AuditLogFilterBar(),
            Expanded(child: _Body()),
          ],
        ),
      ),
    );
  }
}

// ── Table columns definition ────────────────────────────────────────────────

const _kColumns = [
  AppTableColumn(label: 'Timestamp', flex: 3),
  AppTableColumn(label: 'Action', flex: 2),
  AppTableColumn(label: 'Entity', flex: 3),
  AppTableColumn(label: 'User', flex: 2),
  AppTableColumn(label: 'Branch', flex: 2),
  AppTableColumn(label: 'Device / IP', flex: 2),
  AppTableColumn(label: 'Details', flex: 1, align: TextAlign.center),
];

// ── Body ────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuditLogBloc, AuditLogState>(
      builder: (context, state) {
        if (state is AuditLogLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.brand),
          );
        }

        if (state is AuditLogError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  state.message,
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (state is AuditLogLoaded) {
          // Apply in-memory search across userId, entityId, entityType,
          // deviceId, and description.
          final query = state.searchQuery.toLowerCase();
          final logs = query.isEmpty
              ? state.logs
              : state.logs.where((l) {
                  return l.userId.toLowerCase().contains(query) ||
                      (l.entityId?.toLowerCase().contains(query) ?? false) ||
                      l.entityType.toLowerCase().contains(query) ||
                      l.deviceId.toLowerCase().contains(query) ||
                      l.description.toLowerCase().contains(query);
                }).toList();

          if (Breakpoints.isPhone(context)) {
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: logs.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: auditLogMobileCard(
                  ctx,
                  logs[i],
                  onTap: () => showAuditLogDetails(ctx, logs[i]),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: AppDataTable(
              columns: _kColumns,
              rowCount: logs.length,
              columnGap: 12,
              rowCellsBuilder: (ctx, i) => auditLogTableCells(
                ctx,
                logs[i],
                onViewDetails: () => showAuditLogDetails(ctx, logs[i]),
              ),
              emptyState: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 56,
                      color: AppColors.textMuted.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.hasActiveFilter || query.isNotEmpty
                          ? 'No logs match the current filters.'
                          : 'No audit logs yet.',
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
