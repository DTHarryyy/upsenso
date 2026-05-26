import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/features/sales/domain/entities/sale_transaction.dart';
import 'package:pos/features/sales/domain/repositories/i_sales_repository.dart';
import 'package:pos/features/sales/presentation/cubit/sales_cubit.dart';
import 'package:pos/features/sales/presentation/cubit/sales_state.dart';

// ---------------------------------------------------------------------------
// Entry point — provides [SalesCubit] and bridges BranchCubit changes.
// ---------------------------------------------------------------------------

class SalesHistory extends StatefulWidget {
  const SalesHistory({super.key});

  @override
  State<SalesHistory> createState() => _SalesHistoryState();
}

class _SalesHistoryState extends State<SalesHistory> {
  late final SalesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SalesCubit(sl<ISalesRepository>());
    // Defer so BranchCubit is fully available in the widget tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cubit.startWatching(
        branchId: context.read<BranchCubit>().state.selectedBranchId,
      );
    });
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  // ── Legacy formatting shims (kept for internal widgets below) ──
  // All formatting now delegates to AppFormatters.

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<BranchCubit, BranchState>(
        listener: (context, branchState) =>
            _cubit.startWatching(branchId: branchState.selectedBranchId),
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppSubPageBar(title: 'Sales History'),
          body: BlocBuilder<SalesCubit, SalesState>(
            builder: (context, state) => _buildBody(context, state),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SalesState state) {
    if (state is SalesInitial || state is SalesLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      );
    }

    if (state is SalesError) {
      return Center(child: Text(state.message));
    }

    if (state is! SalesLoaded) return const SizedBox.shrink();

    if (state.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(IconlyLight.paper, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: AppTextStyles.subtitle(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed sales will appear here',
              style: AppTextStyles.body(
                context,
              ).copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    // Group transactions by date
    final grouped = <String, List<SaleTransaction>>{};
    for (final tx in state.transactions) {
      grouped
          .putIfAbsent(AppFormatters.shortDate(tx.createdAt), () => [])
          .add(tx);
    }
    final dateKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: dateKeys.length,
      itemBuilder: (context, groupIdx) {
        final dateLabel = dateKeys[groupIdx];
        final txList = grouped[dateLabel]!;
        final dailyTotal = txList.fold(0.0, (s, t) => s + t.totalAmount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (groupIdx > 0) const SizedBox(height: 16),
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateLabel,
                    style: AppTextStyles.subtitle(
                      context,
                    ).copyWith(color: AppColors.textPrimary),
                  ),
                  Text(
                    AppFormatters.currency(dailyTotal),
                    style: AppTextStyles.subtitle(context).copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Transaction cards for this date
            ...txList.map((tx) => _buildTransactionCard(context, state, tx)),
          ],
        );
      },
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    SalesLoaded state,
    SaleTransaction tx,
  ) {
    final isExpanded = state.expandedTxId == tx.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _cubit.toggleExpand(tx.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isExpanded
                  ? AppColors.brand.withValues(alpha: 0.3)
                  : AppColors.borderSoft,
            ),
            boxShadow: isExpanded
                ? [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main row
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _paymentColor(
                          tx.paymentMethod,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _paymentIcon(tx.paymentMethod),
                        size: 20,
                        color: _paymentColor(tx.paymentMethod),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.customerName?.isNotEmpty == true
                                ? tx.customerName!
                                : 'Walk-in Customer',
                            style: AppTextStyles.body(context).copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${AppFormatters.time12h(tx.createdAt)}  •  ${tx.itemCount} item${tx.itemCount != 1 ? 's' : ''}  •  ${AppFormatters.capitalise(tx.paymentMethod)}',
                            style: AppTextStyles.caption(
                              context,
                            ).copyWith(color: AppColors.textMuted),
                          ),
                          Builder(
                            builder: (context) {
                              final branchCubit = context.read<BranchCubit>();
                              if (!branchCubit.state.canSwitchBranches) {
                                return const SizedBox.shrink();
                              }
                              final branchName = branchCubit.branchNameForId(
                                tx.branchId,
                              );
                              if (branchName == null) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Icon(
                                      IconlyLight.location,
                                      size: 11,
                                      color: AppColors.brand,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      branchName,
                                      style: AppTextStyles.caption(context)
                                          .copyWith(
                                            color: AppColors.brand,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          if (tx.cashierName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    IconlyLight.profile,
                                    size: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      tx.cashierName!,
                                      style: AppTextStyles.caption(context)
                                          .copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Amount
                    Text(
                      AppFormatters.currency(tx.totalAmount),
                      style: AppTextStyles.money(
                        context,
                      ).copyWith(color: AppColors.accent),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        IconlyLight.arrow_down_2,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Expanded detail
              if (isExpanded) _buildDetail(context, state, tx),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(
    BuildContext context,
    SalesLoaded state,
    SaleTransaction tx,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: AppColors.borderSoft),
        // Line items
        if (state.isLoadingItems)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brand,
                ),
              ),
            ),
          )
        else if (state.expandedItems != null && state.expandedItems!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Column(
              children: state.expandedItems!.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.variantName != 'Default'
                                  ? '${item.productName} (${item.variantName})'
                                  : item.productName,
                              style: AppTextStyles.body(
                                context,
                              ).copyWith(color: AppColors.textPrimary),
                            ),
                            Text(
                              '${AppFormatters.quantity(item.qty)} × ${AppFormatters.currency(item.unitPrice)}',
                              style: AppTextStyles.caption(
                                context,
                              ).copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        AppFormatters.currency(item.lineTotal),
                        style: AppTextStyles.body(context).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        // Summary footer
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
          ),
          child: Column(
            children: [
              _summaryRow(
                context,
                'Subtotal',
                AppFormatters.currency(tx.subtotal),
              ),
              if (tx.taxAmount > 0)
                _summaryRow(
                  context,
                  'Tax',
                  AppFormatters.currency(tx.taxAmount),
                ),
              if (tx.discountAmount > 0)
                _summaryRow(
                  context,
                  'Discount',
                  '-${AppFormatters.currency(tx.discountAmount)}',
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: AppTextStyles.subtitle(context).copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    AppFormatters.currency(tx.totalAmount),
                    style: AppTextStyles.money(
                      context,
                    ).copyWith(color: AppColors.accent),
                  ),
                ],
              ),
              if (tx.amountReceived != null) ...[
                const SizedBox(height: 6),
                _summaryRow(
                  context,
                  'Received',
                  AppFormatters.currency(tx.amountReceived!),
                ),
                _summaryRow(
                  context,
                  'Change',
                  AppFormatters.currency(tx.changeDue ?? 0),
                ),
              ],
              if (tx.cashierName != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppColors.borderSoft),
                ),
                Row(
                  children: [
                    Icon(
                      IconlyLight.profile,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Sold by',
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tx.cashierName!,
                        textAlign: TextAlign.end,
                        style: AppTextStyles.caption(context).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Style helpers ──

  IconData _paymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return IconlyLight.buy;
      case 'gcash':
      case 'ewallet':
        return IconlyLight.call;
      default:
        return IconlyLight.wallet;
    }
  }

  Color _paymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return AppColors.brand;
      case 'gcash':
      case 'ewallet':
        return AppColors.info;
      default:
        return AppColors.accent;
    }
  }
}
