import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';
import 'package:pos/core/widgets/app_dropdown.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/domain/repositories/i_reports_repository.dart';
import 'package:pos/features/reports/pdf/report_pdf_exporter.dart';
import 'package:pos/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:pos/features/reports/presentation/cubit/reports_state.dart';
import 'package:pos/features/reports/presentation/widgets/branch_comparison.dart';
import 'package:pos/features/reports/presentation/widgets/inventory_health_tab.dart';
import 'package:pos/features/reports/presentation/widgets/profit_summary_tab.dart';
import 'package:pos/features/reports/presentation/widgets/report_nav_chip.dart';
import 'package:pos/features/reports/presentation/widgets/sales_report_tab.dart';

// ─── Page ─────────────────────────────────────────────────────────────────────

class ReportsAndAnalyticsPage extends StatefulWidget {
  const ReportsAndAnalyticsPage({super.key});

  @override
  State<ReportsAndAnalyticsPage> createState() =>
      _ReportsAndAnalyticsPageState();
}

class _ReportsAndAnalyticsPageState extends State<ReportsAndAnalyticsPage> {
  late final ReportsCubit _cubit;

  int _selectedTab = 0;
  ReportPeriod _period = ReportPeriod.last7Days;
  bool _exporting = false;

  static const _tabs = [
    ReportTab(icon: Icons.bar_chart_rounded, label: 'Sales Report'),
    ReportTab(icon: Icons.inventory_2_outlined, label: 'Inventory Health'),
    ReportTab(icon: Icons.attach_money_rounded, label: 'Profit Summary'),
    ReportTab(icon: Icons.store_rounded, label: 'Branch Comparison'),
  ];

  @override
  void initState() {
    super.initState();
    _cubit = ReportsCubit(sl<IReportsRepository>());
    WidgetsBinding.instance.addPostFrameCallback((_) => _startWatching());
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _startWatching() {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final branchId = context
        .read<BranchCubit>()
        .getSelectedBranchIdForFiltering();

    _cubit.startWatching(
      businessId: authState.user.businessId ?? '',
      branchId: branchId,
      period: _period,
    );
  }

  void _onPeriodChanged(ReportPeriod p) {
    setState(() => _period = p);
    _cubit.changePeriod(p);
  }

  Future<void> _onExport(BuildContext context, ReportsData data) async {
    if (_exporting) return;

    // Capture context-dependent values before any async gap.
    final authState = context.read<AuthBloc>().state;
    final businessName = authState is AuthAuthenticated
        ? (authState.user.businessName ?? '')
        : '';
    final branchLabel =
        context.read<BranchCubit>().state.selectedBranch ?? 'All Branches';

    setState(() => _exporting = true);
    try {
      await ReportPdfExporter.export(
        data: data,
        period: _period,
        businessName: businessName,
        branchLabel: branchLabel,
      );
      if (mounted) {
        StatusSnack.show(
          this.context,
          type: StatusType.success,
          title: 'PDF Ready',
          message: 'Choose where to save from the share sheet.',
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        StatusSnack.show(
          this.context,
          type: StatusType.error,
          title: 'Export Failed',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: MultiBlocListener(
        listeners: [
          BlocListener<BranchCubit, BranchState>(
            listenWhen: (p, c) => p.selectedBranchId != c.selectedBranchId,
            listener: (_, _) => _cubit.changeBranch(
              context.read<BranchCubit>().getSelectedBranchIdForFiltering(),
            ),
          ),
        ],
        child: BlocBuilder<ReportsCubit, ReportsState>(
          builder: (ctx, state) {
            final data = state is ReportsLoaded
                ? state.data
                : ReportsData.empty();
            final isLoading = state is ReportsLoading;

            return Scaffold(
              backgroundColor: AppColors.background,
              body: RefreshIndicator(
                onRefresh: () async => _startWatching(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(ctx, data),
                      const SizedBox(height: 16),
                      ReportNavChipBar(
                        tabs: _tabs,
                        selectedIndex: _selectedTab,
                        onTabSelected: (i) => setState(() => _selectedTab = i),
                      ),
                      const SizedBox(height: 20),
                      if (isLoading)
                        const SizedBox(
                          height: 300,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (state is ReportsError)
                        _ErrorView(
                          message: state.message,
                          onRetry: _startWatching,
                        )
                      else
                        _buildTabContent(data),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ReportsData data) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final narrow = constraints.maxWidth < 600;
        final periodPicker = SizedBox(
          width: 160,
          child: AppDropdown<ReportPeriod>(
            value: _period,
            dense: true,
            items: ReportPeriod.values
                .map(
                  (p) => AppDropdownItem(
                    value: p,
                    label: p.label,
                    icon: Icons.calendar_today_outlined,
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) _onPeriodChanged(v);
            },
          ),
        );
        final exportBtn = _ExportButton(
          isLoading: _exporting,
          onTap: () => _onExport(context, data),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TitleSection(),
              const SizedBox(height: 12),
              Row(
                children: [periodPicker, const SizedBox(width: 8), exportBtn],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _TitleSection(),
            const Spacer(),
            periodPicker,
            const SizedBox(width: 8),
            exportBtn,
          ],
        );
      },
    );
  }

  Widget _buildTabContent(ReportsData data) {
    switch (_selectedTab) {
      case 0:
        return SalesReportTab(data: data, period: _period);
      case 1:
        return InventoryHealthTab(data: data);
      case 2:
        return ProfitSummaryTab(data: data, period: _period);
      case 3:
        return BranchComparisonTab(data: data);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Header sub-widgets ───────────────────────────────────────────────────────

class _TitleSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports & Analytics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Business intelligence and insights',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  const _ExportButton({required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.textSecondary,
                ),
              )
            else
              const Icon(
                Icons.download_rounded,
                size: 15,
                color: AppColors.textSecondary,
              ),
            const SizedBox(width: 6),
            Text(
              isLoading ? 'Exporting…' : 'Export PDF',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'Failed to load reports',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
