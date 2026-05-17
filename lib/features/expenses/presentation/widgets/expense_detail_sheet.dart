import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/features/expenses/domain/expense_item.dart';
import 'package:pos/features/expenses/presentation/cubit/expenses_cubit.dart';
import 'package:pos/features/expenses/presentation/widgets/expense_status_badge.dart';

void showExpenseDetail(
  BuildContext context,
  ExpenseItem item,
  bool canApprove,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<ExpensesCubit>(),
      child: _ExpenseDetailSheet(item: item, canApprove: canApprove),
    ),
  );
}

class _ExpenseDetailSheet extends StatelessWidget {
  final ExpenseItem item;
  final bool canApprove;

  const _ExpenseDetailSheet({required this.item, required this.canApprove});

  @override
  Widget build(BuildContext context) {
    final (statusBg, statusText, statusLabel) = expenseStatusStyle(item.status);
    final d = item.expenseDate;
    final dateStr =
        '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
    final cubit = context.read<ExpensesCubit>();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSoft,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brand, AppColors.brandDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      IconlyLight.paper,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.id,
                          style: getOutfitStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.vendor,
                          style: getOutfitStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.category,
                          style: getOutfitStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppFormatters.currency(item.amount),
                        style: getOutfitStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          statusLabel,
                          style: getOutfitStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _DetailCard(
                    children: [
                      _DetailRow(
                        icon: IconlyLight.calendar,
                        label: 'Date',
                        value: dateStr,
                      ),
                      const _DetailDivider(),
                      _DetailRow(
                        icon: IconlyLight.category,
                        label: 'Category',
                        value: item.category,
                      ),
                      const _DetailDivider(),
                      _DetailRow(
                        icon: IconlyLight.work,
                        label: 'Branch',
                        value: item.branchName ?? 'All Branches',
                      ),
                      const _DetailDivider(),
                      _DetailRow(
                        icon: IconlyLight.profile,
                        label: 'Submitted By',
                        value: item.submittedByName,
                      ),
                      if (item.approvedByName != null) ...[
                        const _DetailDivider(),
                        _DetailRow(
                          icon: IconlyBold.tick_square,
                          label: 'Approved By',
                          value: item.approvedByName!,
                        ),
                      ],
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const _DetailDivider(),
                        _DetailRow(
                          icon: IconlyLight.document,
                          label: 'Note',
                          value: item.note!,
                        ),
                      ],
                      const _DetailDivider(),
                      _DetailRow(
                        icon: Icons.tag_rounded,
                        label: 'Reference ID',
                        value: item.id,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DetailCard(
                    children: [
                      _AmountRow(label: 'Subtotal', value: item.amount),
                      const _DetailDivider(),
                      const _AmountRow(label: 'Tax (0%)', value: 0.0),
                      const _DetailDivider(),
                      _AmountRow(
                        label: 'Total',
                        value: item.amount,
                        isTotal: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (canApprove && item.status == ExpenseStatus.pending) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              cubit.rejectExpense(item.id);
                              Navigator.pop(context);
                            },
                            icon: const Icon(IconlyLight.close_square, size: 16),
                            label: Text(
                              'Reject',
                              style: getOutfitStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: () {
                              cubit.approveExpense(item.id);
                              Navigator.pop(context);
                            },
                            icon: const Icon(IconlyLight.tick_square, size: 16),
                            label: Text(
                              'Approve',
                              style: getOutfitStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textInverse,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.borderSoft),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: getOutfitStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: AppColors.brand),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: getOutfitStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;
  const _AmountRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: getOutfitStyle(
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
              color: isTotal ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
          const Spacer(),
          Text(
            AppFormatters.currency(value),
            style: getOutfitStyle(
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isTotal ? AppColors.brand : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      color: AppColors.borderSoft,
      indent: 16,
      endIndent: 16,
    );
  }
}
