import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/widgets/app_data_table.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/core/widgets/app_view_toggle.dart';
import 'package:pos/features/audit_logs/domain/repositories/i_audit_log_repository.dart';
import 'package:pos/features/audit_logs/presentation/bloc/audit_log_bloc.dart';
import 'package:pos/features/audit_logs/presentation/bloc/audit_log_event.dart';
import 'package:pos/features/audit_logs/presentation/bloc/audit_log_state.dart'; // ignore: unused_import
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
  AppViewMode? _viewMode; // null = not yet set by user

  void _setViewMode(AppViewMode mode) {
    setState(() => _viewMode = mode);
  }

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = Breakpoints.isPhone(context);
          final effectiveMode =
              _viewMode ?? (isNarrow ? AppViewMode.cards : AppViewMode.table);
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppSubPageBar(title: 'Audit Logs'),
            body: Column(
              children: [
                AuditLogFilterBar(
                  viewMode: effectiveMode,
                  onViewModeChanged: _setViewMode,
                ),
                Expanded(child: _Body(viewMode: effectiveMode)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Table columns definition ────────────────────────────────────────────────

const _kColumns = [
  AppTableColumn(label: 'Timestamp', width: 130),
  AppTableColumn(label: 'Action', width: 110),
  AppTableColumn(label: 'Entity', width: 140),
  AppTableColumn(label: 'User', width: 120),
  AppTableColumn(label: 'Branch', width: 120),
  AppTableColumn(label: 'Device / IP', width: 140),
  AppTableColumn(label: 'Details', width: 60, align: TextAlign.center),
];

// ── Body ────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final AppViewMode viewMode;
  const _Body({required this.viewMode});

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
                  IconlyLight.danger,
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

          if (viewMode == AppViewMode.cards) {
            if (logs.isEmpty) {
              return _EmptyState(
                hasFilters: state.hasActiveFilter || query.isNotEmpty,
              );
            }
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

          // Wrap in vertical scroll so many rows don't overflow the
          // Expanded container.
          return SingleChildScrollView(
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
              emptyState: _EmptyState(
                hasFilters: state.hasActiveFilter || query.isNotEmpty,
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  const _EmptyState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilters ? IconlyLight.filter : IconlyLight.activity,
            size: 56,
            color: AppColors.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            hasFilters
                ? 'No logs match the current filters.'
                : 'No audit logs yet.',
            style: AppTextStyles.caption(
              context,
            ).copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          if (hasFilters) ...[
            const SizedBox(height: 6),
            Text(
              'Try adjusting or clearing the filters.',
              style: AppTextStyles.caption(
                context,
              ).copyWith(color: AppColors.textMuted.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
