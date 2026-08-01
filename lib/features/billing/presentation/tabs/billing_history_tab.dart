import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/permissions/plan_display.dart';
import 'package:pos/core/widgets/app_empty_state.dart';
import 'package:pos/core/widgets/app_section_card.dart';
import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/presentation/cubit/billing_cubit.dart';
import 'package:pos/features/billing/presentation/cubit/billing_state.dart';
import 'package:pos/features/billing/presentation/billing_formats.dart';

/// Payment/invoice history from `billing_payments`.
///
/// Online-only (no local Drift mirror) — an offline visit gets its own
/// explanation rather than reading as "you've never paid us," and a genuinely
/// empty Free account gets a nudge toward the Plans tab instead of a dead end.
class BillingHistoryTab extends StatelessWidget {
  final VoidCallback onSeePlans;

  const BillingHistoryTab({super.key, required this.onSeePlans});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillingCubit, BillingState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<BillingCubit>().refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (state.offline)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: AppEmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'Needs a connection',
                    message: 'Payment history needs a connection.',
                  ),
                )
              else if (state.payments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No payments yet',
                    message: state.planCode == 'free'
                        ? 'You\'re on the Free plan — see what a paid tier unlocks.'
                        : null,
                    actionLabel: state.planCode == 'free' ? 'See plans' : null,
                    onAction: state.planCode == 'free' ? onSeePlans : null,
                  ),
                )
              else
                _invoicesCard(state),
            ],
          ),
        );
      },
    );
  }

  Widget _invoicesCard(BillingState s) {
    return AppSectionCard(
      title: 'Payment history',
      icon: Icons.receipt_long_outlined,
      children: [
        for (final p in s.payments)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_invoiceLabel(p),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text(
                        '${formatBillingDate(p.createdAt)}'
                        '${p.isTest ? '  ·  test' : ''}',
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text('₱${p.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(width: 10),
                _payStatusDot(p.status),
              ],
            ),
          ),
      ],
    );
  }

  Widget _payStatusDot(String status) {
    final color = status == 'paid'
        ? AppColors.success
        : status == 'failed'
            ? AppColors.error
            : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  String _invoiceLabel(BillingPayment p) => p.kind == 'addon'
      // Historical add-on purchases still render even though add-ons are gone.
      ? 'Add-on: ${p.addonCode ?? ''}'
      : 'Plan: ${planLabelOf(p.planCode ?? 'free')}';
}
