import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/expenses/domain/expense_item.dart';
import 'package:pos/features/expenses/presentation/cubit/expenses_cubit.dart';
import 'package:pos/features/expenses/presentation/widgets/expense_detail_sheet.dart';
import 'package:pos/features/expenses/presentation/widgets/expense_empty_state.dart';
import 'package:pos/features/expenses/presentation/widgets/expense_status_badge.dart';

class ExpenseCardView extends StatelessWidget {
  final List<ExpenseItem> items;
  final bool canApprove;

  const ExpenseCardView({
    super.key,
    required this.items,
    required this.canApprove,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const ExpenseEmptyState();
    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ExpenseCard(item: item, canApprove: canApprove),
              ))
          .toList(),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseItem item;
  final bool canApprove;

  const _ExpenseCard({required this.item, required this.canApprove});

  @override
  Widget build(BuildContext context) {
    final d = item.expenseDate;
    final dateStr =
        '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
    final cubit = context.read<ExpensesCubit>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_outlined,
                    color: AppColors.brand, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.vendor,
                        style: getOutfitStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(item.category,
                        style: getOutfitStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₱${item.amount.toStringAsFixed(2)}',
                      style: getOutfitStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  ExpenseStatusBadge(item.status),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: 12),
          Row(
            children: [
              _Meta(icon: Icons.calendar_today_rounded, label: dateStr),
              const SizedBox(width: 8),
              _Meta(
                  icon: Icons.store_mall_directory_outlined,
                  label: item.branchName ?? 'All'),
              const SizedBox(width: 8),
              _Meta(
                  icon: Icons.person_outline_rounded,
                  label: item.submittedByName),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _CardAction(
                icon: Icons.visibility_outlined,
                color: AppColors.brand,
                bg: AppColors.brandSoft,
                tooltip: 'View',
                onTap: () => showExpenseDetail(context, item, canApprove),
              ),
              if (canApprove && item.status == ExpenseStatus.pending) ...[
                _CardAction(
                  icon: Icons.check_rounded,
                  color: AppColors.success,
                  bg: AppColors.successSoft,
                  tooltip: 'Approve',
                  onTap: () => cubit.approveExpense(item.id),
                ),
                _CardAction(
                  icon: Icons.close_rounded,
                  color: AppColors.error,
                  bg: AppColors.errorSoft,
                  tooltip: 'Reject',
                  onTap: () => cubit.rejectExpense(item.id),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Meta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                style: getOutfitStyle(
                    fontSize: 11, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String tooltip;
  final VoidCallback onTap;

  const _CardAction({
    required this.icon,
    required this.color,
    required this.bg,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.all(7),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}
