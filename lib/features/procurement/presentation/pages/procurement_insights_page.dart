import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/app_section_card.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/core/widgets/stat_card.dart';
import 'package:pos/features/procurement/domain/entities/procurement_insights.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order.dart';
import 'package:pos/features/procurement/presentation/cubit/po_cubit.dart';
import 'package:pos/features/procurement/presentation/cubit/po_state.dart';

/// Procurement overview: outstanding-PO aging, spend, and top suppliers.
/// Computed from the POs already streamed into PoCubit (offline-first); lives in
/// the procurement feature so it disappears when the module is disabled.
class ProcurementInsightsPage extends StatelessWidget {
  const ProcurementInsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: Breakpoints.isTablet(context)
          ? null
          : const AppSubPageBar(title: 'Procurement Insights'),
      body: BlocBuilder<PoCubit, PoState>(
        builder: (context, state) {
          final orders = switch (state) {
            PoLoaded(:final orders) => orders,
            PoActionInProgress(:final orders) => orders,
            _ => const <PurchaseOrder>[],
          };
          return _Insights(orders: orders);
        },
      ),
    );
  }
}

class _Insights extends StatelessWidget {
  final List<PurchaseOrder> orders;

  const _Insights({required this.orders});

  @override
  Widget build(BuildContext context) {
    final data = ProcurementInsights.from(orders);
    final outstandingValue = data.outstandingValue;
    final spend = data.receivedSpend;
    final supplierCount = data.supplierCount;
    final topSuppliers = data.topSuppliers;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Breakpoints.maxContentWidth(context)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            StatCardsRow(
              cards: [
                AppStatCard(
                  title: 'Outstanding',
                  value: '${data.outstandingCount}',
                  icon: IconlyBold.bag,
                  iconBg: AppColors.infoSoft,
                  iconColor: AppColors.info,
                ),
                AppStatCard(
                  title: 'Outstanding value',
                  value: AppFormatters.currency(outstandingValue),
                  icon: IconlyBold.wallet,
                  iconBg: AppColors.warningSoft,
                  iconColor: AppColors.warning,
                ),
                AppStatCard(
                  title: 'Received spend',
                  value: AppFormatters.currency(spend),
                  icon: IconlyBold.chart,
                  iconBg: AppColors.successSoft,
                  iconColor: AppColors.success,
                ),
                AppStatCard(
                  title: 'Suppliers',
                  value: '$supplierCount',
                  icon: IconlyBold.work,
                  iconBg: AppColors.brandSoft,
                  iconColor: AppColors.brand,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppSectionCard(
              title: 'Outstanding PO aging',
              icon: IconlyLight.time_circle,
              children: [
                _AgingRow(
                  label: '0–7 days',
                  count: data.aging0Count,
                  value: data.aging0Value,
                ),
                _AgingRow(
                  label: '8–30 days',
                  count: data.aging1Count,
                  value: data.aging1Value,
                ),
                _AgingRow(
                  label: 'Over 30 days',
                  count: data.aging2Count,
                  value: data.aging2Value,
                  warn: true,
                ),
                if (data.outstandingCount == 0)
                  _emptyHint('No outstanding orders'),
              ],
            ),
            const SizedBox(height: 16),
            AppSectionCard(
              title: 'Top suppliers by spend',
              icon: IconlyLight.work,
              children: [
                if (topSuppliers.isEmpty)
                  _emptyHint('No received orders yet')
                else
                  for (final e in topSuppliers.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: getOutfitStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            AppFormatters.currency(e.value),
                            style: getOutfitStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyHint(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      style: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
    ),
  );
}

class _AgingRow extends StatelessWidget {
  final String label;
  final int count;
  final double value;
  final bool warn;

  const _AgingRow({
    required this.label,
    required this.count,
    required this.value,
    this.warn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: getOutfitStyle(
                fontSize: 13,
                color: warn && count > 0 ? AppColors.error : AppColors.textPrimary,
                fontWeight: warn && count > 0 ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            '$count',
            style: getOutfitStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            child: Text(
              AppFormatters.currency(value),
              textAlign: TextAlign.right,
              style: getOutfitStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
