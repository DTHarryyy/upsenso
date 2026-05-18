import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/app_data_table.dart';
import 'package:pos/core/widgets/table_action_button.dart';
import 'package:pos/features/expenses/domain/expense_item.dart';
import 'package:pos/features/expenses/presentation/cubit/expenses_cubit.dart';
import 'package:pos/features/expenses/presentation/widgets/expense_detail_sheet.dart';
import 'package:pos/features/expenses/presentation/widgets/expense_empty_state.dart';
import 'package:pos/features/expenses/presentation/widgets/expense_status_badge.dart';

const _kColumns = [
  AppTableColumn(label: 'Date', flex: 3),
  AppTableColumn(label: 'Category', flex: 3),
  AppTableColumn(label: 'Vendor', flex: 3),
  AppTableColumn(label: 'Branch', flex: 2),
  AppTableColumn(label: 'Amount / Status', flex: 5),
  AppTableColumn(label: 'Submitted By', flex: 3),
  AppTableColumn(label: 'Actions', flex: 2),
];

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
    return AppDataTable(
      columns: _kColumns,
      rowCount: items.length,
      columnGap: 12,
      emptyState: const ExpenseEmptyState(),
      rowCellsBuilder: (ctx, i) => _buildCells(ctx, items[i]),
    );
  }

  List<Widget> _buildCells(BuildContext context, ExpenseItem item) {
    final d = item.expenseDate;
    final dateStr =
        '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
    final cubit = context.read<ExpensesCubit>();

    return [
      // Date
      Text(
        dateStr,
        style: getOutfitStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      // Category
      Text(
        item.category,
        style: getOutfitStyle(fontSize: 13, color: AppColors.textPrimary),
        overflow: TextOverflow.ellipsis,
      ),
      // Vendor
      Text(
        item.vendor,
        style: getOutfitStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      // Branch
      Text(
        item.branchName ?? 'All',
        style: getOutfitStyle(fontSize: 13, color: AppColors.textSecondary),
        overflow: TextOverflow.ellipsis,
      ),
      // Amount + Status inline
      Row(
        children: [
          Text(
            AppFormatters.currency(item.amount),
            style: getOutfitStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          ExpenseStatusBadge(item.status),
        ],
      ),
      // Submitted By
      Text(
        item.submittedByName,
        style: getOutfitStyle(fontSize: 13, color: AppColors.textSecondary),
        overflow: TextOverflow.ellipsis,
      ),
      // Actions
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TableActionButton(
            icon: IconlyLight.show,
            color: AppColors.brand,
            background: AppColors.brandSoft,
            tooltip: 'View',
            onTap: () => showExpenseDetail(context, item, canApprove),
          ),
          if (canApprove && item.status == ExpenseStatus.pending) ...[
            TableActionButton(
              icon: IconlyLight.tick_square,
              color: AppColors.success,
              background: AppColors.successSoft,
              tooltip: 'Approve',
              onTap: () => cubit.approveExpense(item.id),
            ),
            TableActionButton(
              icon: IconlyLight.close_square,
              color: AppColors.error,
              background: AppColors.errorSoft,
              tooltip: 'Reject',
              onTap: () => cubit.rejectExpense(item.id),
            ),
          ],
        ],
      ),
    ];
  }
}
