import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/widgets/app_data_table.dart';
import 'package:pos/core/widgets/app_inline_banner.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/core/widgets/app_view_toggle.dart';
import 'package:pos/features/audit_logs/presentation/widgets/audit_chain_verify_dialog.dart';
import 'package:pos/features/audit_logs/domain/repositories/i_audit_log_repository.dart';
import 'package:pos/features/audit_logs/presentation/bloc/audit_log_bloc.dart';
import 'package:pos/features/audit_logs/presentation/bloc/audit_log_event.dart';
import 'package:pos/features/audit_logs/presentation/bloc/audit_log_state.dart'; // ignore: unused_import
import 'package:pos/features/audit_logs/presentation/widgets/audit_log_filter_bar.dart';
import 'package:pos/features/audit_logs/presentation/widgets/audit_log_skeleton.dart';
import 'package:pos/features/audit_logs/presentation/widgets/audit_log_tile.dart';
import 'package:pos/features/audit_logs/presentation/widgets/audit_log_empty_state.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _kViewModeKey = 'audit_log_view_mode';

  AppViewMode? _viewMode; // null = not yet restored from storage

  /// Persist the chosen layout and rebuild.
  void _setViewMode(AppViewMode mode) {
    setState(() => _viewMode = mode);
    SharedPreferences.getInstance().then(
      (p) => p.setString(_kViewModeKey, mode.name),
    );
  }

  /// Restore the last-used layout from local storage.
  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kViewModeKey);
    // Skip if the user already toggled the view while this load was in
    // flight — applying the stale saved value now would silently revert
    // their tap.
    if (saved != null && mounted && _viewMode == null) {
      setState(() {
        _viewMode = AppViewMode.values.firstWhere(
          (m) => m.name == saved,
          orElse: () => AppViewMode.cards,
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadViewMode();
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
            appBar: Breakpoints.isPhone(context)
                ? AppSubPageBar(title: 'Audit Logs')
                : null,
            body: Column(
              children: [
                AuditLogFilterBar(
                  viewMode: effectiveMode,
                  onViewModeChanged: _setViewMode,
                ),
                // Tamper-evidence check — owner-level (audit_logs.verify).
                if (sl<PermissionService>().can(PermissionKeys.auditLogsVerify))
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: TextButton.icon(
                        onPressed: () => showAuditChainVerifyDialog(context),
                        icon: const Icon(IconlyLight.shield_done, size: 16),
                        label: Text(
                          'Verify integrity',
                          style: AppTextStyles.caption(context).copyWith(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.brand,
                        ),
                      ),
                    ),
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

// Flex (not fixed) widths so the table fills the whole container width on
// tablet/desktop instead of leaving dead space on the right. Ratios roughly
// preserve the old pixel proportions.
const _kColumns = [
  AppTableColumn(label: 'Timestamp', flex: 12),
  AppTableColumn(label: 'Action', flex: 13),
  AppTableColumn(label: 'Entity', flex: 14),
  AppTableColumn(label: 'User', flex: 12),
  AppTableColumn(label: 'Branch', flex: 12),
  AppTableColumn(label: 'Device / IP', flex: 14),
  AppTableColumn(label: 'Details', flex: 6, align: TextAlign.center),
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
          return AuditLogSkeleton(viewMode: viewMode);
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
              return AuditLogEmptyState(
                hasFilters: state.hasActiveFilter || query.isNotEmpty,
              );
            }
            final showFooter = state.hasMore;
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: logs.length + (showFooter ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == logs.length) {
                  return _LoadMoreFooter(
                    isFetchingOlder: state.isFetchingOlder,
                    error: state.serverFetchError,
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: auditLogMobileCard(
                    ctx,
                    logs[i],
                    onTap: () => showAuditLogDetails(ctx, logs[i]),
                  ),
                );
              },
            );
          }

          // Wrap in vertical scroll so many rows don't overflow the
          // Expanded container.
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppDataTable(
                  columns: _kColumns,
                  rowCount: logs.length,
                  columnGap: 12,
                  rowCellsBuilder: (ctx, i) => auditLogTableCells(
                    ctx,
                    logs[i],
                    onViewDetails: () => showAuditLogDetails(ctx, logs[i]),
                  ),
                  emptyState: AuditLogEmptyState(
                    hasFilters: state.hasActiveFilter || query.isNotEmpty,
                  ),
                ),
                if (state.hasMore && logs.isNotEmpty)
                  _LoadMoreFooter(
                    isFetchingOlder: state.isFetchingOlder,
                    error: state.serverFetchError,
                  ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ── Load more footer ────────────────────────────────────────────────────────

/// Widens the local Drift query window while local history remains; once
/// that's exhausted, the same button fetches the next older page from the
/// server instead — [isFetchingOlder] shows a spinner for that network call
/// (local widening is synchronous and needs none), and [error] surfaces a
/// failed/offline attempt inline without losing what's already loaded.
class _LoadMoreFooter extends StatelessWidget {
  final bool isFetchingOlder;
  final String? error;

  const _LoadMoreFooter({this.isFetchingOlder = false, this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: AppInlineBanner(
                message: error,
                variant: AppInlineBannerVariant.warning,
              ),
            ),
          Center(
            child: TextButton.icon(
              onPressed: isFetchingOlder
                  ? null
                  : () => context.read<AuditLogBloc>().add(
                      const LoadMoreAuditLogs(),
                    ),
              icon: isFetchingOlder
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brand,
                      ),
                    )
                  : const Icon(IconlyLight.arrow_down_2, size: 16),
              label: Text(
                isFetchingOlder
                    ? 'Loading older entries…'
                    : (error != null ? 'Retry' : 'Load more'),
                style: AppTextStyles.body(
                  context,
                ).copyWith(color: AppColors.brand, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(foregroundColor: AppColors.brand),
            ),
          ),
        ],
      ),
    );
  }
}
