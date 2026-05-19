import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_dropdown.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/widgets/app_input_decoration.dart';
import 'package:pos/core/widgets/app_section_card.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/features/business/domain/entities/branch.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';
import 'package:pos/features/employees/presentation/bloc/employee_bloc.dart';
import 'package:pos/features/employees/presentation/bloc/employee_event.dart';
import 'package:pos/features/employees/presentation/bloc/employee_state.dart';

/// Routes to a full-page form on mobile, or a centred dialog on wider screens.
///
/// Pass [employee] to edit an existing record, or leave null to add a new one.
Future<void> showEmployeeFormDialog({
  required BuildContext context,
  required List<Branch> branches,
  Employee? employee,
}) {
  final bloc = context.read<EmployeeBloc>();

  if (Breakpoints.isPhone(context)) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: _EmployeeFormPage(branches: branches, employee: employee),
        ),
      ),
    );
  }

  return showDialog<void>(
    context: context,
    barrierColor: AppColors.overlay,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _EmployeeFormDialog(branches: branches, employee: employee),
    ),
  );
}

// ── Mobile: full-page ────────────────────────────────────────────────────────

class _EmployeeFormPage extends StatelessWidget {
  final List<Branch> branches;
  final Employee? employee;

  const _EmployeeFormPage({required this.branches, this.employee});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageBar(
        title: employee != null ? 'Edit Employee' : 'Add Employee',
      ),
      body: _EmployeeFormBody(
        branches: branches,
        employee: employee,
        isPage: true,
      ),
    );
  }
}

// ── Desktop / tablet: centred dialog ─────────────────────────────────────────

class _EmployeeFormDialog extends StatelessWidget {
  final List<Branch> branches;
  final Employee? employee;

  const _EmployeeFormDialog({required this.branches, this.employee});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Breakpoints.maxDialogWidth(context)),
        child: _EmployeeFormBody(
          branches: branches,
          employee: employee,
          isPage: false,
        ),
      ),
    );
  }
}

// ── Shared form body ─────────────────────────────────────────────────────────

class _EmployeeFormBody extends StatefulWidget {
  final List<Branch> branches;
  final Employee? employee;

  /// When true the widget is hosted inside a [Scaffold] with [AppSubPageBar],
  /// so the inline header row and Cancel button are hidden.
  final bool isPage;

  const _EmployeeFormBody({
    required this.branches,
    required this.isPage,
    this.employee,
  });

  @override
  State<_EmployeeFormBody> createState() => _EmployeeFormBodyState();
}

class _EmployeeFormBodyState extends State<_EmployeeFormBody> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  EmployeeRole _role = EmployeeRole.cashier;
  String? _selectedBranchId;
  DateTime _hiredAt = DateTime.now();
  bool _submitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _isEditing => widget.employee != null;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    if (e != null) {
      _nameCtrl.text = e.fullName;
      _emailCtrl.text = e.email;
      _phoneCtrl.text = e.phone ?? '';
      _role = e.role;
      _selectedBranchId = e.branchId;
      _hiredAt = e.hiredAt;
    } else if (widget.branches.isNotEmpty) {
      _selectedBranchId = widget.branches.first.id;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a branch')),
      );
      return;
    }
    setState(() => _submitting = true);

    if (_isEditing) {
      context.read<EmployeeBloc>().add(
        UpdateEmployee(
          id: widget.employee!.id,
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          branchId: _selectedBranchId!,
          role: _role,
        ),
      );
    } else {
      context.read<EmployeeBloc>().add(
        AddEmployee(
          branchId: _selectedBranchId!,
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          role: _role,
          hiredAt: _hiredAt,
          password: _passwordCtrl.text,
        ),
      );
    }

    // Do NOT pop here. The BlocListener below closes the form on success
    // and surfaces errors without closing when validation fails.
  }

  Future<void> _pickHireDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hiredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.brand),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _hiredAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmployeeBloc, EmployeeState>(
      // Only react to state changes that result from our own submission.
      listenWhen: (prev, curr) =>
          _submitting && curr is! EmployeeOperationInProgress,
      listener: (context, state) {
        if (!mounted) return;
        if (state is EmployeeLoaded || state is EmployeeOperationSuccess) {
          Navigator.of(context).pop();
        } else if (state is EmployeeValidationFailure) {
          setState(() => _submitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.firstMessage),
              backgroundColor: Colors.red.shade700,
            ),
          );
        } else if (state is EmployeeError) {
          setState(() => _submitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        widget.isPage ? 24 : 20,
        20,
        widget.isPage ? MediaQuery.paddingOf(context).bottom + 24 : 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Inline header (dialog only) ───────────────────────────
            if (!widget.isPage) ...[
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      IconlyLight.profile,
                      color: AppColors.brand,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isEditing ? 'Edit Employee' : 'Add Employee',
                    style: AppTextStyles.headline(context),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // ── Personal Information ──────────────────────────────────
            AppSectionCard(
              title: 'Personal Information',
              icon: IconlyLight.profile,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: appInputDeco(
                    'e.g. Maria Santos',
                    label: 'Full Name',
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: appInputDeco(
                    'e.g. maria@business.com',
                    label: 'Email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: appInputDeco(
                    'e.g. +63 912 345 6789',
                    label: 'Phone (optional)',
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Login Credentials (create mode only) ──────────────────
            if (!_isEditing) ...[
              AppSectionCard(
                title: 'Login Credentials',
                icon: IconlyLight.lock,
                children: [
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: appInputDeco(
                      'Min. 6 characters',
                      label: 'Password',
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPasswordCtrl,
                    obscureText: _obscureConfirmPassword,
                    decoration: appInputDeco(
                      'Re-enter password',
                      label: 'Confirm Password',
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v != _passwordCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // ── Assignment ────────────────────────────────────────────
            AppSectionCard(
              title: 'Assignment',
              icon: IconlyLight.work,
              children: [
                AppDropdown<String>(
                  value: _selectedBranchId,
                  hint: 'Select branch',
                  items: widget.branches
                      .map((b) => AppDropdownItem(value: b.id, label: b.name))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedBranchId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                AppDropdown<EmployeeRole>(
                  value: _role,
                  items: EmployeeRole.values
                      .map((r) => AppDropdownItem(value: r, label: r.displayName))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _role = v);
                  },
                ),
                const SizedBox(height: 12),
                // Hire date — styled to match TextFormField
                InkWell(
                  onTap: _pickHireDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: appInputDeco(null, label: 'Hire Date').copyWith(
                      suffixIcon: const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          IconlyLight.calendar,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    child: Text(
                      _formatDate(_hiredAt),
                      style: getOutfitStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Actions ───────────────────────────────────────────────
            if (widget.isPage)
              SizedBox(
                width: double.infinity,
                child: AppFilledButton(
                  label: _isEditing ? 'Save Changes' : 'Add Employee',
                  loading: _submitting,
                  onPressed: _submit,
                  icon: _isEditing ? Icons.check : Icons.person_add,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.borderSoft),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: getOutfitStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppFilledButton(
                      label: _isEditing ? 'Save Changes' : 'Add Employee',
                      loading: _submitting,
                      onPressed: _submit,
                      icon: _isEditing ? Icons.check : Icons.person_add,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
  }
}
