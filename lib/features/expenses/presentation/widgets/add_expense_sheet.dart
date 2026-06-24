import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/errors/app_error_mapper.dart';
import 'package:pos/core/widgets/app_date_range_picker.dart';
import 'package:pos/core/widgets/app_dropdown.dart';
import 'package:pos/core/widgets/app_toast.dart';
import 'package:pos/core/widgets/app_field_label.dart';
import 'package:pos/core/widgets/app_input_decoration.dart';
import 'package:pos/core/widgets/branch_sale_dialog.dart';
import 'package:pos/features/expenses/presentation/cubit/expenses_cubit.dart';

const List<String> kExpenseCategories = [
  'Supplies',
  'Utilities',
  'Maintenance',
  'Salaries',
  'Rent',
  'Marketing',
  'Transportation',
  'Other',
];

void showAddExpenseSheet(
  BuildContext context, {
  bool canApprove = false,
}) {
  final isWide = Breakpoints.isTablet(context);

  if (isWide) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<ExpensesCubit>()),
          BlocProvider.value(value: context.read<BranchCubit>()),
        ],
        child: _AddExpenseDialog(canApprove: canApprove),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<ExpensesCubit>()),
          BlocProvider.value(value: context.read<BranchCubit>()),
        ],
        child: _AddExpenseSheet(canApprove: canApprove),
      ),
    );
  }
}

/// Tells the user what submitting will do, derived from their permission:
/// auto-approved when they can approve, otherwise routed to a manager. This
/// replaces the old manual status picker.
class _ApprovalHint extends StatelessWidget {
  final bool canApprove;
  const _ApprovalHint({required this.canApprove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            canApprove ? Icons.check_circle_outline : Icons.schedule_outlined,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              canApprove
                  ? 'You can approve — this will be saved as approved.'
                  : 'This will be sent to a manager for approval.',
              style:
                  getOutfitStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  final bool canApprove;
  const _AddExpenseSheet({required this.canApprove});

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _vendorCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _category;
  DateTime _expenseDate = DateTime.now();
  bool _submitting = false;

  @override
  void dispose() {
    _vendorCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final branchState = context.read<BranchCubit>().state;
      String? branchId = branchState.selectedBranchId;
      String? branchName = branchState.selectedBranch;

      if (branchId == null) {
        final selection = await showBranchSaleDialog(context);
        if (!mounted) return;
        if (selection == null) {
          setState(() => _submitting = false);
          return;
        }
        branchId = selection.id;
        branchName = selection.name;
      }

      await context.read<ExpensesCubit>().addExpense(
            category: _category!,
            vendor: _vendorCtrl.text.trim(),
            amount: double.parse(_amountCtrl.text.trim()),
            branchId: branchId,
            branchName: branchName,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            expenseDate: _expenseDate,
          );

      if (mounted) Navigator.pop(context);
    } catch (e, st) {
      debugPrint('[AddExpenseSheet] Error in submit: $e\n$st');
      setState(() => _submitting = false);
      if (mounted) {
        AppToast.show(
          context,
          'Failed to add expense',
          subtitle: AppErrorMapper.message(e),
          variant: AppToastVariant.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSoft,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
                child: Row(
                  children: [
                    const Spacer(),
                    Text(
                      'Add Expense',
                      style: getOutfitStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppFieldLabel('Category *'),
                    AppDropdown<String>(
                      value: _category,
                      hint: 'Select category',
                      items: kExpenseCategories
                          .map((c) => AppDropdownItem(value: c, label: c))
                          .toList(),
                      onChanged: (v) => setState(() => _category = v),
                      validator: (v) =>
                          v == null ? 'Please select a category' : null,
                    ),
                    const SizedBox(height: 14),

                    AppFieldLabel('Vendor / Supplier *'),
                    TextFormField(
                      controller: _vendorCtrl,
                      decoration: appInputDeco('e.g. Office Mart'),
                      style: getOutfitStyle(
                          fontSize: 14, color: AppColors.textPrimary),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Vendor is required'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    AppFieldLabel('Amount *'),
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration:
                          appInputDeco('0.00').copyWith(prefixText: '₱ '),
                      style: getOutfitStyle(
                          fontSize: 14, color: AppColors.textPrimary),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Amount is required';
                        }
                        final parsed = double.tryParse(v.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    AppFieldLabel('Expense Date *'),
                    AppDateRangePicker(
                      value:
                          DateTimeRange(start: _expenseDate, end: _expenseDate),
                      onChanged: (range) {
                        if (range != null) {
                          setState(() => _expenseDate = range.start);
                        }
                      },
                      placeholder: 'Select date',
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    ),
                    const SizedBox(height: 14),

                    AppFieldLabel('Note (optional)'),
                    TextFormField(
                      controller: _noteCtrl,
                      maxLines: 3,
                      decoration: appInputDeco('Add any additional details...'),
                      style: getOutfitStyle(
                          fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    _ApprovalHint(canApprove: widget.canApprove),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                widget.canApprove
                                    ? 'Add & Approve'
                                    : 'Submit for Approval',
                                style: getOutfitStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wide-screen dialog ─────────────────────────────────────────────────────

class _AddExpenseDialog extends StatefulWidget {
  final bool canApprove;
  const _AddExpenseDialog({required this.canApprove});

  @override
  State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<_AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _vendorCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _category;
  DateTime _expenseDate = DateTime.now();
  bool _submitting = false;

  @override
  void dispose() {
    _vendorCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final branchState = context.read<BranchCubit>().state;
      String? branchId = branchState.selectedBranchId;
      String? branchName = branchState.selectedBranch;

      if (branchId == null) {
        final selection = await showBranchSaleDialog(context);
        if (!mounted) return;
        if (selection == null) {
          setState(() => _submitting = false);
          return;
        }
        branchId = selection.id;
        branchName = selection.name;
      }

      await context.read<ExpensesCubit>().addExpense(
            category: _category!,
            vendor: _vendorCtrl.text.trim(),
            amount: double.parse(_amountCtrl.text.trim()),
            branchId: branchId,
            branchName: branchName,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            expenseDate: _expenseDate,
          );

      if (mounted) Navigator.pop(context);
    } catch (e, st) {
      debugPrint('[AddExpenseSheet] Error in submit: $e\n$st');
      setState(() => _submitting = false);
      if (mounted) {
        AppToast.show(
          context,
          'Failed to add expense',
          subtitle: AppErrorMapper.message(e),
          variant: AppToastVariant.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long_rounded,
                          size: 18, color: AppColors.brand),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add Expense',
                      style: getOutfitStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.borderSoft),

              // Form
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category
                        AppFieldLabel('Category *'),
                        AppDropdown<String>(
                          value: _category,
                          hint: 'Select category',
                          items: kExpenseCategories
                              .map((c) => AppDropdownItem(value: c, label: c))
                              .toList(),
                          onChanged: (v) => setState(() => _category = v),
                          validator: (v) =>
                              v == null ? 'Please select a category' : null,
                        ),
                        const SizedBox(height: 14),

                        // Row 2: Vendor + Amount
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel('Vendor / Supplier *'),
                                  TextFormField(
                                    controller: _vendorCtrl,
                                    decoration: appInputDeco('e.g. Office Mart'),
                                    style: getOutfitStyle(
                                        fontSize: 14,
                                        color: AppColors.textPrimary),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Vendor is required'
                                            : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppFieldLabel('Amount *'),
                                  TextFormField(
                                    controller: _amountCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*')),
                                    ],
                                    decoration: appInputDeco('0.00')
                                        .copyWith(prefixText: '₱ '),
                                    style: getOutfitStyle(
                                        fontSize: 14,
                                        color: AppColors.textPrimary),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      final parsed = double.tryParse(v.trim());
                                      if (parsed == null || parsed <= 0) {
                                        return 'Invalid amount';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Expense Date (full width)
                        AppFieldLabel('Expense Date *'),
                        AppDateRangePicker(
                          value: DateTimeRange(
                              start: _expenseDate, end: _expenseDate),
                          onChanged: (range) {
                            if (range != null) {
                              setState(() => _expenseDate = range.start);
                            }
                          },
                          placeholder: 'Select date',
                          lastDate:
                              DateTime.now().add(const Duration(days: 1)),
                        ),
                        const SizedBox(height: 14),

                        // Note (full width)
                        AppFieldLabel('Note (optional)'),
                        TextFormField(
                          controller: _noteCtrl,
                          maxLines: 3,
                          decoration:
                              appInputDeco('Add any additional details...'),
                          style: getOutfitStyle(
                              fontSize: 14, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        _ApprovalHint(canApprove: widget.canApprove),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer actions
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: AppColors.borderSoft)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _submitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.borderSoft),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel',
                          style: getOutfitStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                widget.canApprove
                                    ? 'Add & Approve'
                                    : 'Submit for Approval',
                                style: getOutfitStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
