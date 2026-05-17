import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
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
import 'package:pos/features/reports/export/report_excel_exporter.dart';
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
  bool _exportingPdf = false;
  bool _exportingExcel = false;

  static const _tabs = [
    ReportTab(icon: IconlyLight.chart, label: 'Sales Report'),
    ReportTab(icon: IconlyLight.category, label: 'Inventory Health'),
    ReportTab(icon: IconlyLight.wallet, label: 'Profit Summary'),
    ReportTab(icon: IconlyLight.work, label: 'Branch Comparison'),
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
    _cubit.startWatching(
      businessId: authState.user.businessId ?? '',
      branchId: context.read<BranchCubit>().getSelectedBranchIdForFiltering(),
      period: _period,
    );
  }

  void _onPeriodChanged(ReportPeriod p) {
    setState(() => _period = p);
    _cubit.changePeriod(p);
  }

  // ── Export handlers ──────────────────────────────────────────────────────────

  Future<void> _onExportPdf(
    BuildContext ctx,
    ReportsData data,
    String businessName,
    String branchLabel,
  ) async {
    if (_exportingPdf || _exportingExcel) return;
    setState(() => _exportingPdf = true);
    try {
      await ReportPdfExporter.export(
        data: data,
        period: _period,
        businessName: businessName,
        branchLabel: branchLabel,
      );
      if (mounted) {
        StatusSnack.show(
          context,
          type: StatusType.success,
          title: 'PDF Ready',
          message: 'Choose where to save from the share sheet.',
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (mounted) {
        StatusSnack.show(
          context,
          type: StatusType.error,
          title: 'Export Failed',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _onExportExcel(
    BuildContext ctx,
    ReportsData data,
    String businessName,
    String branchLabel,
  ) async {
    if (_exportingPdf || _exportingExcel) return;
    setState(() => _exportingExcel = true);
    try {
      final result = await ReportExcelExporter.export(
        data: data,
        period: _period,
        businessName: businessName,
        branchLabel: branchLabel,
      );
      if (mounted) {
        final msg = kIsWeb
            ? 'Download started.'
            : 'Saved: ${result.split('/').last}';
        StatusSnack.show(
          context,
          type: StatusType.success,
          title: 'Excel Exported',
          message: msg,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (mounted) {
        StatusSnack.show(
          context,
          type: StatusType.error,
          title: 'Export Failed',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingExcel = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

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

            final authState = ctx.read<AuthBloc>().state;
            final businessName = authState is AuthAuthenticated
                ? (authState.user.businessName ?? '')
                : '';
            final branchLabel =
                ctx.read<BranchCubit>().state.selectedBranch ?? 'All Branches';

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
                      // ① Report header
                      _ReportHeaderCard(
                        businessName: businessName,
                        branchLabel: branchLabel,
                        period: _period,
                      ),
                      const SizedBox(height: 16),
                      // ② KPI summary cards
                      _buildPageSummaryCards(data),
                      const SizedBox(height: 16),
                      // ③ Filter row: period picker + export dropdown
                      _buildFilterRow(ctx, data, businessName, branchLabel),
                      const SizedBox(height: 12),
                      // ④ Tab chips
                      ReportNavChipBar(
                        tabs: _tabs,
                        selectedIndex: _selectedTab,
                        onTabSelected: (i) => setState(() => _selectedTab = i),
                      ),
                      const SizedBox(height: 20),
                      // ⑤ Tab content
                      if (isLoading)
                        const _ReportsTabSkeleton()
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

  Widget _buildFilterRow(
    BuildContext ctx,
    ReportsData data,
    String businessName,
    String branchLabel,
  ) {
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
                    icon: IconlyLight.calendar,
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) _onPeriodChanged(v);
            },
          ),
        ),
        const SizedBox(width: 8),
        _ExportDropdown(
          isExportingPdf: _exportingPdf,
          isExportingExcel: _exportingExcel,
          onExportPdf: () => _onExportPdf(ctx, data, businessName, branchLabel),
          onExportExcel: () =>
              _onExportExcel(ctx, data, businessName, branchLabel),
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
      case 0:
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
              icon: IconlyBold.wallet,
              iconBg: AppColors.brandSoft,
              iconColor: AppColors.brand,
            ),
            ReportStatCard(
              title: 'Transactions',
              value: '${data.totalTransactions}',
              changeLabel:
                  '${txnChange >= 0 ? '+' : ''}$txnChange vs prev period',
              isPositive: txnChange >= 0,
              icon: IconlyBold.chart,
              iconBg: const Color(0xFFF3E8FF),
              iconColor: const Color(0xFF7C3AED),
            ),
            ReportStatCard(
              title: 'Avg. Ticket',
              value: fmtCurrency(data.avgTicket),
              changeLabel: '${fmtPct(avgChange)} vs prev period',
              isPositive: avgChange >= 0,
              icon: IconlyBold.activity,
              iconBg: AppColors.successSoft,
              iconColor: AppColors.success,
            ),
            ReportStatCard(
              title: 'Items Sold',
              value: '${data.itemsSold}',
              changeLabel:
                  '${itemsChange >= 0 ? '+' : ''}$itemsChange vs prev period',
              isPositive: itemsChange >= 0,
              icon: IconlyLight.category,
              iconBg: AppColors.warningSoft,
              iconColor: AppColors.warning,
            ),
          ],
        );

      case 1:
        return ReportStatCardsRow(
          cards: [
            ReportStatCard(
              title: 'Low Stock',
              value: '${data.lowStockCount}',
              icon: IconlyLight.category,
              iconBg: AppColors.errorSoft,
              iconColor: AppColors.error,
            ),
            ReportStatCard(
              title: 'Fast Movers',
              value: '${data.fastMoversCount}',
              icon: IconlyBold.activity,
              iconBg: AppColors.successSoft,
              iconColor: AppColors.success,
            ),
            ReportStatCard(
              title: 'Dead Stock',
              value: '${data.deadStockCount}',
              icon: IconlyLight.time_circle,
              iconBg: AppColors.warningSoft,
              iconColor: AppColors.warning,
            ),
            ReportStatCard(
              title: 'Total SKUs',
              value: '${data.totalSKUs}',
              icon: IconlyLight.scan,
              iconBg: AppColors.brandSoft,
              iconColor: AppColors.brand,
            ),
          ],
        );

      case 2:
        final netChange = pctChange(data.netProfit, data.prevNetProfit);
        return ReportStatCardsRow(
          cards: [
            ReportStatCard(
              title: 'Gross Revenue',
              value: fmtCurrency(data.grossRevenue),
              icon: IconlyBold.wallet,
              iconBg: AppColors.brandSoft,
              iconColor: AppColors.brand,
            ),
            ReportStatCard(
              title: 'Cost of Goods',
              value: fmtCurrency(data.costOfGoods),
              icon: IconlyLight.category,
              iconBg: AppColors.errorSoft,
              iconColor: AppColors.error,
            ),
            ReportStatCard(
              title: 'Operating Expenses',
              value: '₱0',
              icon: IconlyLight.paper,
              iconBg: AppColors.warningSoft,
              iconColor: AppColors.warning,
            ),
            ReportStatCard(
              title: 'Net Profit',
              value: fmtCurrency(data.netProfit),
              changeLabel: '${fmtPct(netChange)} vs prev period',
              isPositive: netChange >= 0,
              icon: IconlyBold.activity,
              iconBg: AppColors.successSoft,
              iconColor: AppColors.success,
            ),
          ],
        );

      case 3:
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
              icon: IconlyBold.work,
              iconBg: AppColors.brandSoft,
              iconColor: AppColors.brand,
            ),
            ReportStatCard(
              title: 'Combined Sales',
              value: fmtCurrency(totalBranchSales),
              icon: IconlyBold.wallet,
              iconBg: AppColors.successSoft,
              iconColor: AppColors.success,
            ),
            ReportStatCard(
              title: 'Top Branch',
              value: topBranch?.name ?? '—',
              icon: IconlyBold.ticket_star,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
            ),
            ReportStatCard(
              title: 'Avg. per Branch',
              value: branchCount > 0
                  ? fmtCurrency(totalBranchSales / branchCount)
                  : '—',
              icon: IconlyLight.swap,
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

// ─── Report header card ───────────────────────────────────────────────────────

class _ReportHeaderCard extends StatelessWidget {
  final String businessName;
  final String branchLabel;
  final ReportPeriod period;

  const _ReportHeaderCard({
    required this.businessName,
    required this.branchLabel,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final stamp =
        '${now.day}/${now.month}/${now.year}  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              IconlyLight.chart,
              color: AppColors.brand,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName.isNotEmpty
                      ? businessName
                      : 'Reports & Analytics',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _Chip(IconlyLight.calendar, period.label),
                    const SizedBox(width: 10),
                    _Chip(IconlyLight.work, branchLabel),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Generated',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
              Text(
                stamp,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

// ─── Export dropdown ──────────────────────────────────────────────────────────

enum _ExportType { pdf, excel }

class _ExportDropdown extends StatelessWidget {
  final bool isExportingPdf;
  final bool isExportingExcel;
  final VoidCallback onExportPdf;
  final VoidCallback onExportExcel;

  const _ExportDropdown({
    required this.isExportingPdf,
    required this.isExportingExcel,
    required this.onExportPdf,
    required this.onExportExcel,
  });

  @override
  Widget build(BuildContext context) {
    final busy = isExportingPdf || isExportingExcel;
    final label = isExportingPdf
        ? 'Exporting PDF…'
        : isExportingExcel
        ? 'Exporting…'
        : 'Export';

    return PopupMenuButton<_ExportType>(
      enabled: !busy,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white,
      onSelected: (t) {
        if (t == _ExportType.pdf) onExportPdf();
        if (t == _ExportType.excel) onExportExcel();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _ExportType.pdf,
          child: Row(
            children: [
              Icon(
                IconlyLight.document,
                size: 15,
                color: AppColors.error,
              ),
              const SizedBox(width: 10),
              const Text(
                'Export as PDF',
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: _ExportType.excel,
          child: Row(
            children: [
              Icon(
                IconlyLight.chart,
                size: 15,
                color: AppColors.success,
              ),
              const SizedBox(width: 10),
              const Text(
                'Export as Excel (.xlsx)',
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
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
            if (busy)
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
                IconlyLight.download,
                size: 15,
                color: AppColors.textSecondary,
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            if (!busy) ...[
              const SizedBox(width: 2),
              const Icon(
                IconlyLight.arrow_down_2,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

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
              IconlyLight.danger,
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

// ── Reports tab skeleton loader ───────────────────────────────────────────────

class _ReportsTabSkeleton extends StatefulWidget {
  const _ReportsTabSkeleton();

  @override
  State<_ReportsTabSkeleton> createState() => _ReportsTabSkeletonState();
}

class _ReportsTabSkeletonState extends State<_ReportsTabSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final shimmerPos = -0.3 + 1.6 * _ctrl.value;

        Widget box({double? width, double height = 14, double radius = 8}) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                colors: const [
                  Color(0xFFE2E8F0),
                  Color(0xFFECF0F6),
                  Color(0xFFF5F8FC),
                  Color(0xFFECF0F6),
                  Color(0xFFE2E8F0),
                ],
                stops: [
                  (shimmerPos - 0.4).clamp(0.0, 1.0),
                  (shimmerPos - 0.2).clamp(0.0, 1.0),
                  shimmerPos.clamp(0.0, 1.0),
                  (shimmerPos + 0.2).clamp(0.0, 1.0),
                  (shimmerPos + 0.4).clamp(0.0, 1.0),
                ],
              ),
            ),
          );
        }

        Widget skCard(Widget child) => Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: child,
        );

        Widget dataRow() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              box(width: 32, height: 32, radius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box(height: 13),
                    const SizedBox(height: 4),
                    box(width: 100, height: 11, radius: 5),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              box(width: 64, height: 13, radius: 5),
            ],
          ),
        );

        return Column(
          children: [
            skCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      box(width: 140, height: 14),
                      box(width: 60, height: 12, radius: 6),
                    ],
                  ),
                  const SizedBox(height: 16),
                  box(height: 200, radius: 8),
                ],
              ),
            ),
            skCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  box(width: 120, height: 14),
                  const SizedBox(height: 4),
                  const Divider(color: Color(0xFFE2E8F0)),
                  ...List.generate(5, (_) => dataRow()),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
