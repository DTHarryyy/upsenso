import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/features/expenses/domain/expense_item.dart';

(Color bg, Color text, String label) expenseStatusStyle(ExpenseStatus s) {
  return switch (s) {
    ExpenseStatus.approved =>
      (AppColors.successSoft, AppColors.success, 'Approved'),
    ExpenseStatus.pending =>
      (AppColors.warningSoft, AppColors.warning, 'Pending'),
    ExpenseStatus.rejected =>
      (AppColors.errorSoft, AppColors.error, 'Rejected'),
    ExpenseStatus.draft =>
      (AppColors.surfaceAlt, AppColors.textSecondary, 'Draft'),
  };
}

class ExpenseStatusBadge extends StatelessWidget {
  final ExpenseStatus status;

  const ExpenseStatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (bg, text, label) = expenseStatusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: getOutfitStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }
}
