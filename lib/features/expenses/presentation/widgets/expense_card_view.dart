import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/utils/formatters.dart';
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
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExpenseCard(item: item, canApprove: canApprove),
            ),
          )
          .toList(),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseItem item;
  final bool canApprove;

  const _ExpenseCard({required this.item, required this.canApprove});

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExpensesCubit>();
    final showActions = canApprove && item.status == ExpenseStatus.pending;

    // Whole card opens the detail sheet — no separate "view" button needed.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showExpenseDetail(context, item, canApprove),
      child: Container(
        padding: const EdgeInsets.all(14),
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
            _Header(item: item),
            const SizedBox(height: 12),
            _MetaRow(
              date: _formatDate(item.expenseDate),
              branch: item.branchName ?? 'All',
              submittedBy: item.submittedByName,
            ),
            if (showActions) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ApprovalButton(
                      icon: IconlyLight.close_square,
                      label: 'Reject',
                      color: AppColors.error,
                      bg: AppColors.errorSoft,
                      onTap: () => cubit.rejectExpense(item.id),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ApprovalButton(
                      icon: IconlyLight.tick_square,
                      label: 'Approve',
                      color: AppColors.success,
                      bg: AppColors.successSoft,
                      onTap: () => cubit.approveExpense(item.id),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ExpenseItem item;
  const _Header({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(IconlyLight.paper, color: AppColors.brand, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.vendor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: getOutfitStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppFormatters.currency(item.amount),
              style: getOutfitStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            ExpenseStatusBadge(item.status),
          ],
        ),
      ],
    );
  }
}

// Date · branch · submitter. Date and branch take their natural width; the
// submitter fills the rest and ellipsizes, so the row never forces gaps.
class _MetaRow extends StatelessWidget {
  final String date;
  final String branch;
  final String submittedBy;

  const _MetaRow({
    required this.date,
    required this.branch,
    required this.submittedBy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Meta(icon: IconlyLight.calendar, label: date),
        const SizedBox(width: 14),
        _Meta(icon: IconlyLight.work, label: branch),
        const SizedBox(width: 14),
        Expanded(
          child: _Meta(icon: IconlyLight.profile, label: submittedBy),
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Meta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: getOutfitStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _ApprovalButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _ApprovalButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: getOutfitStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
