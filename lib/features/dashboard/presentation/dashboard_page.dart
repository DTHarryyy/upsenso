import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/features/ai_assistant/widgets/floating_ai_assistant_bar.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/dashboard/data/dashboard_data.dart';
import 'package:pos/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pos/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:pos/features/dashboard/presentation/widgets/ai_insights_card.dart';
import 'package:pos/features/dashboard/presentation/widgets/branch_comparison_card.dart';
import 'package:pos/features/dashboard/presentation/widgets/category_performance_chart.dart';
import 'package:pos/features/dashboard/presentation/widgets/fraud_alerts_card.dart';
import 'package:pos/features/dashboard/presentation/widgets/low_stock_alerts_card.dart';
import 'package:pos/features/dashboard/presentation/widgets/payment_methods_chart.dart';
import 'package:pos/features/dashboard/presentation/widgets/quick_actions_bar.dart';
import 'package:pos/features/dashboard/presentation/widgets/sales_trend_chart.dart';
import 'package:pos/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:pos/features/dashboard/presentation/widgets/top_selling_items.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

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
          builder: (context, state) {
            final data = state is DashboardLoaded
                ? state.data
                : DashboardData.empty();
            final isLoading = state is DashboardLoading;

            return Scaffold(
              floatingActionButton: const FloatingAIAssistantBar(),
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
                      const QuickActionsBar(),
                      const SizedBox(height: 16),

                      // ── Sales Trend + Payment Methods ──
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 800) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    flex: 2,
                                    child: SalesTrendChart(data: data)),
                                const SizedBox(width: 16),
                                Expanded(
                                    flex: 1,
                                    child: PaymentMethodsChart(
                                        breakdown: data.paymentBreakdown)),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              SalesTrendChart(data: data),
                              const SizedBox(height: 16),
                              PaymentMethodsChart(
                                  breakdown: data.paymentBreakdown),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // ── Category + Top Selling + AI Insights ──
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 800) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: CategoryPerformanceChart(
                                        stats: data.categoryStats)),
                                const SizedBox(width: 16),
                                Expanded(
                                    child:
                                        TopSellingItems(items: data.topItems)),
                                const SizedBox(width: 16),
                                const Expanded(child: AiInsightsCard()),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              CategoryPerformanceChart(stats: data.categoryStats),
                              const SizedBox(height: 16),
                              TopSellingItems(items: data.topItems),
                              const SizedBox(height: 16),
                              const AiInsightsCard(),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // ── Low Stock + Fraud Alerts + Branch Comparison ──
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 800) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: LowStockAlertsCard(
                                        items: data.lowStockItems)),
                                const SizedBox(width: 16),
                                const Expanded(child: FraudAlertsCard()),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: BranchComparisonCard(
                                        stats: data.branchStats)),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              LowStockAlertsCard(items: data.lowStockItems),
                              const SizedBox(height: 16),
                              const FraudAlertsCard(),
                              const SizedBox(height: 16),
                              BranchComparisonCard(stats: data.branchStats),
                            ],
                          );
                        },
                      ),

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

// ── Stat Cards helper ──────────────────────────────────────────────────────

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
      StatCard(
        title: "Today's Sales",
        value: isLoading ? '—' : _fmtCurrency(todaySales),
        change: isLoading ? '' : _changeLabel(salesChange, 'from yesterday'),
        isPositive: salesChange >= 0,
        icon: Icons.attach_money,
        iconBgColor: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF22C55E),
      ),
      StatCard(
        title: 'This Week',
        value: isLoading ? '—' : _fmtCurrency(weekSales),
        change: isLoading ? '' : _changeLabel(weekChange, 'from last week'),
        isPositive: weekChange >= 0,
        icon: Icons.trending_up,
        iconBgColor: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF22C55E),
      ),
      StatCard(
        title: 'Transactions',
        value: isLoading ? '—' : '$todayCount',
        change: isLoading
            ? ''
            : '${countDiff >= 0 ? '+' : ''}$countDiff from yesterday',
        isPositive: countDiff >= 0,
        icon: Icons.shopping_cart_outlined,
        iconBgColor: const Color(0xFFDBEAFE),
        iconColor: const Color(0xFF3B82F6),
      ),
      StatCard(
        title: 'Avg. Order Value',
        value: isLoading ? '—' : _fmtCurrency(avgOrder),
        change: isLoading ? '' : _changeLabel(avgChange, 'from yesterday'),
        isPositive: avgChange >= 0,
        icon: Icons.bar_chart,
        iconBgColor: const Color(0xFFF3E8FF),
        iconColor: const Color(0xFF7C3AED),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            children: cards
                .map((c) => Expanded(child: c))
                .expand((w) => [w, const SizedBox(width: 12)])
                .toList()
              ..removeLast(),
          );
        }
        return Column(
          children: [
            Row(children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ]),
          ],
        );
      },
    );
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
