import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/features/expenses/domain/expense_item.dart';
import 'package:pos/features/expenses/presentation/cubit/expenses_cubit.dart';
import 'package:pos/features/expenses/presentation/widgets/expense_detail_sheet.dart';
import 'package:pos/features/expenses/presentation/widgets/expense_empty_state.dart';
import 'package:pos/features/expenses/presentation/widgets/expense_status_badge.dart';

const double _colDate = 100;
const double _colCategory = 110;
const double _colVendor = 150;
const double _colBranch = 120;
const double _colAmount = 110;
const double _colStatus = 105;
const double _colSubmitted = 140;
const double _colActions = 100;

class ExpenseTableView extends StatelessWidget {
  final List<ExpenseItem> items;
  final bool canApprove;

  const ExpenseTableView({
    super.key,
    required this.items,
    required this.canApprove,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const ExpenseEmptyState();

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TableHeader(),
              const Divider(height: 1, color: AppColors.borderSoft),
              ...items.asMap().entries.map((entry) {
                final isLast = entry.key == items.length - 1;
                return Column(
                  children: [
                    _TableRow(item: entry.value, canApprove: canApprove),
                    if (!isLast)
                      const Divider(height: 1, color: AppColors.borderSoft),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _H('Date', width: _colDate),
          _H('Category', width: _colCategory),
          _H('Vendor', width: _colVendor),
          _H('Branch', width: _colBranch),
          _H('Amount', width: _colAmount, align: TextAlign.right),
          _H('Status', width: _colStatus),
          _H('Submitted By', width: _colSubmitted),
          _H('Actions', width: _colActions),
        ],
      ),
    );
  }
}

class _H extends StatelessWidget {
  final String label;
  final double width;
  final TextAlign align;

  const _H(this.label, {required this.width, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label.toUpperCase(),
        textAlign: align,
        style: getOutfitStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final ExpenseItem item;
  final bool canApprove;

  const _TableRow({required this.item, required this.canApprove});

  @override
  Widget build(BuildContext context) {
    final d = item.expenseDate;
    final dateStr =
        '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: _colDate,
            child: Text(
              dateStr,
              style: getOutfitStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: _colCategory,
            child: Text(
              item.category,
              style: getOutfitStyle(fontSize: 13, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: _colVendor,
            child: Text(
              item.vendor,
              style: getOutfitStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: _colBranch,
            child: Text(
              item.branchName ?? 'All',
              style: getOutfitStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: _colAmount,
            child: Text(
              AppFormatters.currency(item.amount),
              textAlign: TextAlign.right,
              style: getOutfitStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: _colStatus, child: ExpenseStatusBadge(item.status)),
          SizedBox(
            width: _colSubmitted,
            child: Text(
              item.submittedByName,
              style: getOutfitStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: _colActions,
            child: _RowActions(item: item, canApprove: canApprove),
          ),
        ],
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  final ExpenseItem item;
  final bool canApprove;

  const _RowActions({required this.item, required this.canApprove});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExpensesCubit>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionBtn(
          icon: Icons.visibility_outlined,
          color: AppColors.brand,
          bg: AppColors.brandSoft,
          tooltip: 'View',
          onTap: () => showExpenseDetail(context, item, canApprove),
        ),
        if (canApprove && item.status == ExpenseStatus.pending) ...[
          _ActionBtn(
            icon: Icons.check_rounded,
            color: AppColors.success,
            bg: AppColors.successSoft,
            tooltip: 'Approve',
            onTap: () => cubit.approveExpense(item.id),
          ),
          _ActionBtn(
            icon: Icons.close_rounded,
            color: AppColors.error,
            bg: AppColors.errorSoft,
            tooltip: 'Reject',
            onTap: () => cubit.rejectExpense(item.id),
          ),
        ],
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
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
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}
