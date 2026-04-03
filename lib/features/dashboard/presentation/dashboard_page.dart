import 'package:flutter/material.dart';
import 'package:pos/features/ai_assistant/widgets/floating_ai_assistant_bar.dart';
import 'package:pos/features/dashboard/presentation/widgets/ai_insights_card.dart';
import 'package:pos/features/dashboard/presentation/widgets/category_performance_chart.dart';
import 'package:pos/features/dashboard/presentation/widgets/payment_methods_chart.dart';
import 'package:pos/features/dashboard/presentation/widgets/quick_actions_bar.dart';
import 'package:pos/features/dashboard/presentation/widgets/sales_trend_chart.dart';
import 'package:pos/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:pos/features/dashboard/presentation/widgets/top_selling_items.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const FloatingAIAssistantBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Stat Cards Row ──
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: "Today's Sales",
                          value: '\$3,842',
                          change: '+12.5% from yesterday',
                          isPositive: true,
                          icon: Icons.attach_money,
                          iconBgColor: const Color(0xFFDCFCE7),
                          iconColor: const Color(0xFF22C55E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'This Week',
                          value: '\$24,606',
                          change: '+8.2% from last week',
                          isPositive: true,
                          icon: Icons.trending_up,
                          iconBgColor: const Color(0xFFDCFCE7),
                          iconColor: const Color(0xFF22C55E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Transactions',
                          value: '156',
                          change: '+23 from yesterday',
                          isPositive: true,
                          icon: Icons.shopping_cart_outlined,
                          iconBgColor: const Color(0xFFDBEAFE),
                          iconColor: const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          title: 'Avg. Order Value',
                          value: '\$24.63',
                          change: '-2.1% from yesterday',
                          isPositive: false,
                          icon: Icons.bar_chart,
                          iconBgColor: const Color(0xFFF3E8FF),
                          iconColor: const Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  );
                }
                // 2x2 grid for smaller screens
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: "Today's Sales",
                            value: '\$3,842',
                            change: '+12.5% from yesterday',
                            isPositive: true,
                            icon: Icons.attach_money,
                            iconBgColor: const Color(0xFFDCFCE7),
                            iconColor: const Color(0xFF22C55E),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'This Week',
                            value: '\$24,606',
                            change: '+8.2% from last week',
                            isPositive: true,
                            icon: Icons.trending_up,
                            iconBgColor: const Color(0xFFDCFCE7),
                            iconColor: const Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Transactions',
                            value: '156',
                            change: '+23 from yesterday',
                            isPositive: true,
                            icon: Icons.shopping_cart_outlined,
                            iconBgColor: const Color(0xFFDBEAFE),
                            iconColor: const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Avg. Order Value',
                            value: '\$24.63',
                            change: '-2.1% from yesterday',
                            isPositive: false,
                            icon: Icons.bar_chart,
                            iconBgColor: const Color(0xFFF3E8FF),
                            iconColor: const Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // ── Quick Actions ──
            const QuickActionsBar(),

            const SizedBox(height: 16),

            // ── Sales Trend + Payment Methods ──
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(flex: 2, child: SalesTrendChart()),
                      const SizedBox(width: 16),
                      const Expanded(flex: 1, child: PaymentMethodsChart()),
                    ],
                  );
                }
                return const Column(
                  children: [
                    SalesTrendChart(),
                    SizedBox(height: 16),
                    PaymentMethodsChart(),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // ── Category Performance + Top Selling + AI Insights ──
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: CategoryPerformanceChart()),
                      SizedBox(width: 16),
                      Expanded(child: TopSellingItems()),
                      SizedBox(width: 16),
                      Expanded(child: AiInsightsCard()),
                    ],
                  );
                }
                return const Column(
                  children: [
                    CategoryPerformanceChart(),
                    SizedBox(height: 16),
                    TopSellingItems(),
                    SizedBox(height: 16),
                    AiInsightsCard(),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}