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
import 'package:pos/features/reports/presentation/widgets/report_card.dart';
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ① KPI summary cards – always visible at top
                      _buildPageSummaryCards(data),
                      const SizedBox(height: 16),
                      // ② Filter row: period picker + export
                      _buildFilterRow(ctx, data),
                      const SizedBox(height: 12),
                      // ③ Tab navigation chips
                      ReportNavChipBar(
                        tabs: _tabs,
                        selectedIndex: _selectedTab,
                        onTabSelected: (i) => setState(() => _selectedTab = i),
                      ),
                      const SizedBox(height: 20),
                      // ④ Detailed tab content
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

  Widget _buildFilterRow(BuildContext context, ReportsData data) {
    return Row(
      children: [
        Expanded(
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
        ),
        const SizedBox(width: 8),
        _ExportButton(
          isLoading: _exporting,
          onTap: () => _onExport(context, data),
        ),
      ],
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

  Widget _buildPageSummaryCards(ReportsData data) {
    switch (_selectedTab) {
      case 0: // Sales Report
        final revChange = pctChange(data.totalRevenue, data.prevTotalRevenue);
        final txnChange = data.totalTransactions - data.prevTotalTransactions;
        final avgChange = pctChange(data.avgTicket, data.prevAvgTicket);
        final itemsChange = data.itemsSold - data.prevItemsSold;
        return ReportStatCardsRow(
          cards: [
            ReportStatCard(
              title: 'Total Revenue',
              value: fmtCurrency(data.totalRevenue),
              changeLabel: '${fmtPct(revChange)} vs prev period',
              isPositive: revChange >= 0,
              icon: Icons.attach_money_rounded,
              iconBg: AppColors.brandSoft,
              iconColor: AppColors.brand,
            ),
            ReportStatCard(
              title: 'Transactions',
              value: '${data.totalTransactions}',
              changeLabel:
                  '${txnChange >= 0 ? '+' : ''}$txnChange vs prev period',
              isPositive: txnChange >= 0,
              icon: Icons.bar_chart_rounded,
              iconBg: const Color(0xFFF3E8FF),
              iconColor: const Color(0xFF7C3AED),
            ),
            ReportStatCard(
              title: 'Avg. Ticket',
              value: fmtCurrency(data.avgTicket),
              changeLabel: '${fmtPct(avgChange)} vs prev period',
              isPositive: avgChange >= 0,
              icon: Icons.trending_up_rounded,
              iconBg: AppColors.successSoft,
              iconColor: AppColors.success,
            ),
            ReportStatCard(
              title: 'Items Sold',
              value: '${data.itemsSold}',
              changeLabel:
                  '${itemsChange >= 0 ? '+' : ''}$itemsChange vs prev period',
              isPositive: itemsChange >= 0,
              icon: Icons.inventory_2_outlined,
              iconBg: AppColors.warningSoft,
              iconColor: AppColors.warning,
            ),
          ],
        );

      case 1: // Inventory Health
        return ReportStatCardsRow(
          cards: [
            ReportStatCard(
              title: 'Low Stock',
              value: '${data.lowStockCount}',
              icon: Icons.inventory_2_outlined,
              iconBg: AppColors.errorSoft,
              iconColor: AppColors.error,
            ),
            ReportStatCard(
              title: 'Fast Movers',
              value: '${data.fastMoversCount}',
              icon: Icons.trending_up_rounded,
              iconBg: AppColors.successSoft,
              iconColor: AppColors.success,
            ),
            ReportStatCard(
              title: 'Dead Stock',
              value: '${data.deadStockCount}',
              icon: Icons.access_time_rounded,
              iconBg: AppColors.warningSoft,
              iconColor: AppColors.warning,
            ),
            ReportStatCard(
              title: 'Total SKUs',
              value: '${data.totalSKUs}',
              icon: Icons.qr_code_2_rounded,
              iconBg: AppColors.brandSoft,
              iconColor: AppColors.brand,
            ),
          ],
        );

      case 2: // Profit Summary
        final netChange = pctChange(data.netProfit, data.prevNetProfit);
        return ReportStatCardsRow(
          cards: [
            ReportStatCard(
              title: 'Gross Revenue',
              value: fmtCurrency(data.grossRevenue),
              icon: Icons.attach_money_rounded,
              iconBg: AppColors.brandSoft,
              iconColor: AppColors.brand,
            ),
            ReportStatCard(
              title: 'Cost of Goods',
              value: fmtCurrency(data.costOfGoods),
              icon: Icons.inventory_2_outlined,
              iconBg: AppColors.errorSoft,
              iconColor: AppColors.error,
            ),
            ReportStatCard(
              title: 'Operating Expenses',
              value: '₱0',
              icon: Icons.receipt_long_outlined,
              iconBg: AppColors.warningSoft,
              iconColor: AppColors.warning,
            ),
            ReportStatCard(
              title: 'Net Profit',
              value: fmtCurrency(data.netProfit),
              changeLabel: '${fmtPct(netChange)} vs prev period',
              isPositive: netChange >= 0,
              icon: Icons.trending_up_rounded,
              iconBg: AppColors.successSoft,
              iconColor: AppColors.success,
            ),
          ],
        );

      case 3: // Branch Comparison
        final branchCount = data.branchStats.length;
        final totalBranchSales = data.branchStats.fold<double>(
          0,
          (s, b) => s + b.totalSales,
        );
        final topBranch = data.branchStats.where((b) => b.isTop).firstOrNull;
        return ReportStatCardsRow(
          cards: [
            ReportStatCard(
              title: 'Active Branches',
              value: '$branchCount',
              icon: Icons.store_rounded,
              iconBg: AppColors.brandSoft,
              iconColor: AppColors.brand,
            ),
            ReportStatCard(
              title: 'Combined Sales',
              value: fmtCurrency(totalBranchSales),
              icon: Icons.attach_money_rounded,
              iconBg: AppColors.successSoft,
              iconColor: AppColors.success,
            ),
            ReportStatCard(
              title: 'Top Branch',
              value: topBranch?.name ?? '—',
              icon: Icons.emoji_events_rounded,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
            ),
            ReportStatCard(
              title: 'Avg. per Branch',
              value: branchCount > 0
                  ? fmtCurrency(totalBranchSales / branchCount)
                  : '—',
              icon: Icons.balance_rounded,
              iconBg: const Color(0xFFF3E8FF),
              iconColor: const Color(0xFF7C3AED),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
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
