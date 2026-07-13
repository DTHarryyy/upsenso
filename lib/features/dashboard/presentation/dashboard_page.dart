import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/breakpoint.dart';
// import 'package:pos/features/ai_assistant/widgets/floating_ai_assistant_bar.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/dashboard/data/dashboard_data.dart';
import 'package:pos/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:pos/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:pos/features/dashboard/presentation/widgets/branch_comparison_card.dart';
import 'package:pos/features/dashboard/presentation/widgets/category_performance_chart.dart';
import 'package:pos/features/dashboard/presentation/widgets/expenses_summary_card.dart';
import 'package:pos/features/dashboard/presentation/widgets/low_stock_alerts_card.dart';
import 'package:pos/features/dashboard/presentation/widgets/payment_methods_chart.dart';
import 'package:pos/features/dashboard/presentation/widgets/sales_trend_chart.dart';
import 'package:pos/core/widgets/stat_card.dart';
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
      final branchId = context
          .read<BranchCubit>()
          .getSelectedBranchIdForFiltering();
      _loadFor(authState, branchId);
    }
  }

  /// Loads the dashboard data for the given session + branch.
  void _loadFor(AuthAuthenticated authState, String? branchId) {
    final businessId = authState.user.businessId ?? '';
    _cubit.startWatching(businessId: businessId, branchId: branchId);
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
                final branchId = ctx
                    .read<BranchCubit>()
                    .getSelectedBranchIdForFiltering();
                _loadFor(authState, branchId);
              }
            },
          ),
          BlocListener<BranchCubit, BranchState>(
            listenWhen: (prev, curr) =>
                prev.selectedBranchId != curr.selectedBranchId,
            listener: (ctx, branchState) {
              final authState = ctx.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                _loadFor(authState, branchState.selectedBranchId);
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
            final isPhone = Breakpoints.isPhone(context);
            final pad = isPhone ? 12.0 : 16.0;
            return Scaffold(
              // floatingActionButton: const FloatingAIAssistantBar(),
              body: (state is DashboardInitial || state is DashboardLoading)
                  ? const _DashboardSkeleton()
                  : RefreshIndicator(
                      onRefresh: () async => _triggerLoad(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(pad),
                        child: Column(
                          children: [
                            // Stat Cards KPIs NGANI
                            _StatCardsRow(data: data, isLoading: isLoading),

                            SizedBox(height: pad),

                            // Sales Trend and Top Selling Items
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth > 800) {
                                  return IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: SalesTrendChart(data: data),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 2,
                                          child: TopSellingItems(
                                            items: data.topItems,
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
                                    TopSellingItems(items: data.topItems),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            // ── Row 2: Low Stock | Category Performance | Expenses ──
                            // Low Stock and Expenses are hidden for cashier /
                            // inventory staff; Category Performance is always shown.
                            Builder(
                              builder: (ctx) {
                                final isRestricted = !sl<PermissionService>()
                                    .can(PermissionKeys.navExpenses);

                                if (isRestricted) {
                                  // Restricted roles: Category Performance full-width.
                                  return CategoryPerformanceChart(
                                    stats: data.categoryStats,
                                  );
                                }

                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth > 800) {
                                      return IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: LowStockAlertsCard(
                                                items: data.lowStockItems,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: CategoryPerformanceChart(
                                                stats: data.categoryStats,
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
                                        LowStockAlertsCard(
                                          items: data.lowStockItems,
                                        ),
                                        const SizedBox(height: 16),
                                        CategoryPerformanceChart(
                                          stats: data.categoryStats,
                                        ),
                                        const SizedBox(height: 16),
                                        ExpensesSummaryCard(
                                          summary: data.expenseSummary,
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            // ── Row 3: Branch Comparison | Payment Methods ──
                            // Branch Comparison is hidden for cashier / inventory staff.
                            Builder(
                              builder: (ctx) {
                                final isRestricted = !sl<PermissionService>()
                                    .can(PermissionKeys.navExpenses);

                                if (isRestricted) {
                                  // Restricted roles: Payment Methods full-width.
                                  return PaymentMethodsChart(
                                    breakdown: data.paymentBreakdown,
                                  );
                                }

                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth > 800) {
                                      return IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: BranchComparisonCard(
                                                stats: data.branchStats,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: PaymentMethodsChart(
                                                breakdown:
                                                    data.paymentBreakdown,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return Column(
                                      children: [
                                        BranchComparisonCard(
                                          stats: data.branchStats,
                                        ),
                                        const SizedBox(height: 16),
                                        PaymentMethodsChart(
                                          breakdown: data.paymentBreakdown,
                                        ),
                                      ],
                                    );
                                  },
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
        changeLabel: isLoading ? null : _changeLabel(salesChange),
        changePeriod: isLoading ? null : 'from yesterday',
        isPositive: salesChange >= 0,
        icon: IconlyBold.wallet,
        iconBg: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF22C55E),
      ),
      AppStatCard(
        title: 'This Week',
        value: isLoading ? '—' : _fmtCurrency(weekSales),
        changeLabel: isLoading ? null : _changeLabel(weekChange),
        changePeriod: isLoading ? null : 'from last week',
        isPositive: weekChange >= 0,
        icon: IconlyBold.activity,
        iconBg: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF22C55E),
      ),
      AppStatCard(
        title: 'Transactions',
        value: isLoading ? '—' : '$todayCount',
        changeLabel: isLoading
            ? null
            : '${countDiff >= 0 ? '+' : ''}$countDiff',
        changePeriod: isLoading ? null : 'from yesterday',
        isPositive: countDiff >= 0,
        icon: IconlyLight.buy,
        iconBg: const Color(0xFFDBEAFE),
        iconColor: const Color(0xFF3B82F6),
      ),
      AppStatCard(
        title: 'Avg. Order Value',
        value: isLoading ? '—' : _fmtCurrency(avgOrder),
        changeLabel: isLoading ? null : _changeLabel(avgChange),
        changePeriod: isLoading ? null : 'from yesterday',
        isPositive: avgChange >= 0,
        icon: IconlyBold.chart,
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

  String _changeLabel(double pct) {
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }

  String _fmtCurrency(double v) {
    if (v >= 1000000) return '₱${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '₱${(v / 1000).toStringAsFixed(1)}k';
    return '₱${v.toStringAsFixed(2)}';
  }
}

// Dashboard skeleton loader

class _DashboardSkeleton extends StatefulWidget {
  const _DashboardSkeleton();

  @override
  State<_DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<_DashboardSkeleton>
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

        // White card shell matching AppCard
        Widget skCard(Widget child) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: child,
        );

        // Stat card skeleton — left text column + right badge, matching
        // AppStatCard's title / value / trend stack with the icon floated right.
        Widget statCard() => skCard(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box(width: 80, height: 12, radius: 5),
                    const SizedBox(height: 6),
                    box(width: 100, height: 24, radius: 6),
                    const SizedBox(height: 6),
                    box(width: 110, height: 12, radius: 5),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              box(width: 36, height: 36, radius: 10),
            ],
          ),
        );

        // Generic chart / list card skeleton
        Widget chartCard(double bodyHeight) => skCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  box(width: 130, height: 14),
                  box(width: 56, height: 12, radius: 6),
                ],
              ),
              const SizedBox(height: 16),
              box(height: bodyHeight, radius: 8),
            ],
          ),
        );
        final pad = Breakpoints.isPhone(context) ? 12.0 : 16.0;
        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Column(
            children: [
              // ── Stat cards ── matches StatCardsRow's responsive grid.
              LayoutBuilder(
                builder: (_, c) {
                  final perRow = kpiColumnCount(c.maxWidth, 4);
                  final cards = List.generate(4, (_) => statCard());
                  final rows = <Widget>[];
                  for (var i = 0; i < cards.length; i += perRow) {
                    if (i > 0) rows.add(const SizedBox(height: 12));
                    final slice = cards.sublist(
                      i,
                      (i + perRow).clamp(0, cards.length),
                    );
                    rows.add(
                      Row(
                        children:
                            slice
                                .map((w) => Expanded(child: w))
                                .expand((w) => [w, const SizedBox(width: 12)])
                                .toList()
                              ..removeLast(),
                      ),
                    );
                  }
                  return Column(children: rows);
                },
              ),

              SizedBox(height: pad),

              // Row 1: Sales trend + Low stock
              LayoutBuilder(
                builder: (_, c) {
                  if (c.maxWidth > 800) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 3, child: chartCard(220)),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: chartCard(220)),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      chartCard(200),
                      const SizedBox(height: 16),
                      chartCard(180),
                    ],
                  );
                },
              ),

              SizedBox(height: pad),

              // ── Row 2: Top selling + Payment methods + Expenses ──
              LayoutBuilder(
                builder: (_, c) {
                  if (c.maxWidth > 800) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: chartCard(180)),
                          const SizedBox(width: 16),
                          Expanded(child: chartCard(180)),
                          const SizedBox(width: 16),
                          Expanded(child: chartCard(180)),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      chartCard(180),
                      const SizedBox(height: 16),
                      chartCard(180),
                      const SizedBox(height: 16),
                      chartCard(180),
                    ],
                  );
                },
              ),

              SizedBox(height: pad),

              // ── Row 3: Category performance + Branch comparison ──
              LayoutBuilder(
                builder: (_, c) {
                  if (c.maxWidth > 800) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 3, child: chartCard(220)),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: chartCard(220)),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      chartCard(200),
                      SizedBox(height: pad),
                      chartCard(180),
                    ],
                  );
                },
              ),

              SizedBox(height: pad),
            ],
          ),
        );
      },
    );
  }
}
