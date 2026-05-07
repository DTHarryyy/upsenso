import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
// import 'package:pos/features/ai_assistant/widgets/floating_ai_assistant_bar.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/dashboard/data/dashboard_data.dart';
import 'package:pos/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pos/features/dashboard/presentation/cubit/dashboard_state.dart';
// import 'package:pos/features/dashboard/presentation/widgets/ai_insights_card.dart';
import 'package:pos/features/dashboard/presentation/widgets/branch_comparison_card.dart';
import 'package:pos/features/dashboard/presentation/widgets/category_performance_chart.dart';
import 'package:pos/features/dashboard/presentation/widgets/low_stock_alerts_card.dart';
import 'package:pos/features/dashboard/presentation/widgets/payment_methods_chart.dart';
import 'package:pos/features/dashboard/presentation/widgets/quick_actions_bar.dart';
import 'package:pos/features/dashboard/presentation/widgets/sales_trend_chart.dart';
import 'package:pos/core/widgets/stat_card.dart';
import 'package:pos/features/dashboard/presentation/widgets/expenses_summary_card.dart';
import 'package:pos/features/dashboard/presentation/widgets/top_selling_items.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onNewSale;

  const DashboardPage({super.key, this.onNewSale});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = DashboardCubit(sl());
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerLoad());
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _triggerLoad() {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final branchId =
          context.read<BranchCubit>().getSelectedBranchIdForFiltering();
      _cubit.startWatching(
        businessId: authState.user.businessId ?? '',
        branchId: branchId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (prev, curr) => curr is AuthAuthenticated,
            listener: (ctx, authState) {
              if (authState is AuthAuthenticated) {
                final branchId =
                    ctx.read<BranchCubit>().getSelectedBranchIdForFiltering();
                _cubit.startWatching(
                  businessId: authState.user.businessId ?? '',
                  branchId: branchId,
                );
              }
            },
          ),
          BlocListener<BranchCubit, BranchState>(
            listenWhen: (prev, curr) =>
                prev.selectedBranchId != curr.selectedBranchId,
            listener: (ctx, branchState) {
              final authState = ctx.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                _cubit.startWatching(
                  businessId: authState.user.businessId ?? '',
                  branchId: branchState.selectedBranchId,
                );
              }
            },
          ),
        ],
        child: BlocBuilder<DashboardCubit, DashboardState>(
          // Only rebuild when data or loading state actually changes.
          buildWhen: (prev, curr) => prev != curr,
          builder: (context, state) {
            final data = state is DashboardLoaded
                ? state.data
                : DashboardData.empty();
            final isLoading = state is DashboardLoading;

            return Scaffold(
              // floatingActionButton: const FloatingAIAssistantBar(),
              body: RefreshIndicator(
                onRefresh: () async => _triggerLoad(), // restarts watcher + loads fresh
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ── Stat Cards ──
                      _StatCardsRow(data: data, isLoading: isLoading),

                      const SizedBox(height: 16),
                      QuickActionsBar(onNewSale: widget.onNewSale),
                      const SizedBox(height: 16),

                      // ── ROW 1: Sales Trend (hero) + Low Stock Alerts (urgent) ──
                      // Low stock is time-sensitive — a manager needs to see it
                      // immediately, not buried at the bottom of the page.
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 800) {
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: SalesTrendChart(data: data),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: LowStockAlertsCard(
                                      items: data.lowStockItems,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Column(
                            children: [
                              SalesTrendChart(data: data),
                              const SizedBox(height: 16),
                              LowStockAlertsCard(items: data.lowStockItems),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // ── ROW 2: Top Selling Items + Payment Methods + Recent Expenses ──
                      // Operational insights: what sells, how customers pay, what costs.
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 800) {
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: TopSellingItems(
                                      items: data.topItems,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: PaymentMethodsChart(
                                      breakdown: data.paymentBreakdown,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ExpensesSummaryCard(
                                      summary: data.expenseSummary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Column(
                            children: [
                              TopSellingItems(items: data.topItems),
                              const SizedBox(height: 16),
                              PaymentMethodsChart(
                                breakdown: data.paymentBreakdown,
                              ),
                              const SizedBox(height: 16),
                              ExpensesSummaryCard(summary: data.expenseSummary),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // ── ROW 3: Category Performance + Branch Comparison ──
                      // Deeper analytics — reviewed less frequently.
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 800) {
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: CategoryPerformanceChart(
                                      stats: data.categoryStats,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: BranchComparisonCard(
                                      stats: data.branchStats,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Column(
                            children: [
                              CategoryPerformanceChart(
                                stats: data.categoryStats,
                              ),
                              const SizedBox(height: 16),
                              BranchComparisonCard(stats: data.branchStats),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // ── ROW 4: AI Insights (full width) ──
                      // Commented out — AI assistant not yet integrated.
                      // const AiInsightsCard(),

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
}


class _StatCardsRow extends StatelessWidget {
  final DashboardData data;
  final bool isLoading;

  const _StatCardsRow({required this.data, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final todaySales = data.todaySales;
    final weekSales = data.weekSales;
    final todayCount = data.todayTransactionCount;
    final avgOrder = data.avgOrderValue;

    final salesChange = _pctChange(todaySales, data.yesterdaySales);
    final weekChange = _pctChange(weekSales, data.lastWeekSales);
    final countDiff = todayCount - data.yesterdayTransactionCount;
    final avgChange = _pctChange(avgOrder, data.yesterdayAvgOrderValue);

    final cards = [
      AppStatCard(
        title: "Today's Sales",
        value: isLoading ? '—' : _fmtCurrency(todaySales),
        changeLabel: isLoading ? null : _changeLabel(salesChange, 'from yesterday'),
        isPositive: salesChange >= 0,
        icon: Icons.attach_money,
        iconBg: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF22C55E),
      ),
      AppStatCard(
        title: 'This Week',
        value: isLoading ? '—' : _fmtCurrency(weekSales),
        changeLabel: isLoading ? null : _changeLabel(weekChange, 'from last week'),
        isPositive: weekChange >= 0,
        icon: Icons.trending_up,
        iconBg: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF22C55E),
      ),
      AppStatCard(
        title: 'Transactions',
        value: isLoading ? '—' : '$todayCount',
        changeLabel: isLoading
            ? null
            : '${countDiff >= 0 ? '+' : ''}$countDiff from yesterday',
        isPositive: countDiff >= 0,
        icon: Icons.shopping_cart_outlined,
        iconBg: const Color(0xFFDBEAFE),
        iconColor: const Color(0xFF3B82F6),
      ),
      AppStatCard(
        title: 'Avg. Order Value',
        value: isLoading ? '—' : _fmtCurrency(avgOrder),
        changeLabel: isLoading ? null : _changeLabel(avgChange, 'from yesterday'),
        isPositive: avgChange >= 0,
        icon: Icons.bar_chart,
        iconBg: const Color(0xFFF3E8FF),
        iconColor: const Color(0xFF7C3AED),
      ),
    ];

    return StatCardsRow(cards: cards);
  }

  double _pctChange(double current, double previous) {
    if (previous == 0) return current > 0 ? 100 : 0;
    return (current - previous) / previous * 100;
  }

  String _changeLabel(double pct, String suffix) {
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}% $suffix';
  }

  String _fmtCurrency(double v) {
    if (v >= 1000000) return '₱${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '₱${(v / 1000).toStringAsFixed(1)}k';
    return '₱${v.toStringAsFixed(2)}';
  }
}
