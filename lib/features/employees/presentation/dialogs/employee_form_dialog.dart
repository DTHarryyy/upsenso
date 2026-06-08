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
///
/// [allowedRoles] restricts which roles appear in the role picker. Omit to
/// allow all roles (Super Admin / Owner behaviour).
///
/// [lockedBranchId] forces a specific branch and hides the branch picker.
Future<void> showEmployeeFormDialog({
  required BuildContext context,
  required List<Branch> branches,
  Employee? employee,
  List<EmployeeRole>? allowedRoles,
  String? lockedBranchId,
}) {
  final bloc = context.read<EmployeeBloc>();

  if (Breakpoints.isPhone(context)) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: _EmployeeFormPage(
            branches: branches,
            employee: employee,
            allowedRoles: allowedRoles,
            lockedBranchId: lockedBranchId,
          ),
        ),
      ),
    );
  }

  return showDialog<void>(
    context: context,
    barrierColor: AppColors.overlay,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _EmployeeFormDialog(
        branches: branches,
        employee: employee,
        allowedRoles: allowedRoles,
        lockedBranchId: lockedBranchId,
      ),
    ),
  );
}

// ── Mobile: full-page ────────────────────────────────────────────────────────

class _EmployeeFormPage extends StatelessWidget {
  final List<Branch> branches;
  final Employee? employee;
  final List<EmployeeRole>? allowedRoles;
  final String? lockedBranchId;

  const _EmployeeFormPage({
    required this.branches,
    this.employee,
    this.allowedRoles,
    this.lockedBranchId,
  });

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
        allowedRoles: allowedRoles,
        lockedBranchId: lockedBranchId,
      ),
    );
  }
}

// ── Desktop / tablet: centred dialog ─────────────────────────────────────────

class _EmployeeFormDialog extends StatelessWidget {
  final List<Branch> branches;
  final Employee? employee;
  final List<EmployeeRole>? allowedRoles;
  final String? lockedBranchId;

  const _EmployeeFormDialog({
    required this.branches,
    this.employee,
    this.allowedRoles,
    this.lockedBranchId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Breakpoints.maxDialogWidth(context),
        ),
        child: _EmployeeFormBody(
          branches: branches,
          employee: employee,
          isPage: false,
          allowedRoles: allowedRoles,
          lockedBranchId: lockedBranchId,
        ),
      ),
    );
  }
}

// ── Shared form body ─────────────────────────────────────────────────────────

class _EmployeeFormBody extends StatefulWidget {
  final List<Branch> branches;
  final Employee? employee;

  /// When true the widget is hosted inside a [Scaffold] with [AppSubPageBar].
  final bool isPage;

  /// Restricts which roles are available in the role picker.
  /// Null means all roles are shown.
  final List<EmployeeRole>? allowedRoles;

  /// When set, the branch picker is hidden and this branch ID is always used.
  final String? lockedBranchId;

  const _EmployeeFormBody({
    required this.branches,
    required this.isPage,
    this.employee,
    this.allowedRoles,
    this.lockedBranchId,
  });

  @override
  State<_EmployeeFormBody> createState() => _EmployeeFormBodyState();
}

class _EmployeeFormBodyState extends State<_EmployeeFormBody> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  EmployeeRole _role = EmployeeRole.cashier;
  String? _selectedBranchId;
  bool _submitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Server-side field error shown inline under the email field.
  String? _serverEmailError;
  // Generic form-level error shown in a banner above the action buttons.
  String? _formError;

  bool get _isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();
    if (widget.lockedBranchId != null) {
      _selectedBranchId = widget.lockedBranchId;
    }
    final e = widget.employee;
    if (e != null) {
      _nameCtrl.text = e.fullName;
      final allowed = widget.allowedRoles;
      final derivedRole = EmployeeRoleX.fromRoleName(e.roleName);
      _role = (allowed == null || allowed.contains(derivedRole))
          ? derivedRole
          : allowed.first;
      if (widget.lockedBranchId == null) {
        _selectedBranchId = e.branchId;
      }
    } else if (widget.lockedBranchId == null && widget.branches.isNotEmpty) {
      _selectedBranchId = widget.branches.first.id;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    // Clear any previous server errors before re-validating.
    setState(() {
      _serverEmailError = null;
      _formError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    if (_isEditing) {
      context.read<EmployeeBloc>().add(
        UpdateEmployee(
          id: widget.employee!.id,
          fullName: _nameCtrl.text.trim(),
          branchId: _selectedBranchId,
        ),
      );
    } else {
      context.read<EmployeeBloc>().add(
        AddEmployee(
          branchId: _selectedBranchId!,
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          roleName: _role.displayName,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmployeeBloc, EmployeeState>(
      listenWhen: (prev, curr) =>
          _submitting &&
          (curr is EmployeeOperationSuccess ||
              curr is EmployeeError ||
              curr is EmployeeValidationFailure),
      listener: (context, state) {
        if (!mounted) return;
        if (state is EmployeeOperationSuccess) {
          Navigator.of(context).pop();
        } else if (state is EmployeeValidationFailure) {
          setState(() {
            _submitting = false;
            _serverEmailError = state.fieldErrors['email'];
            final otherErrors = state.fieldErrors.entries
                .where((e) => e.key != 'email')
                .map((e) => e.value)
                .join(' • ');
            _formError = otherErrors.isNotEmpty ? otherErrors : null;
          });
        } else if (state is EmployeeError) {
          setState(() {
            _submitting = false;
            _formError = state.message;
          });
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
                  if (!_isEditing) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: appInputDeco(
                        'e.g. maria@business.com',
                        label: 'Email',
                      ).copyWith(
                        errorText: _serverEmailError,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        if (_serverEmailError != null) {
                          setState(() => _serverEmailError = null);
                        }
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final emailRegex =
                            RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ],
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
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
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
                        if (v != _passwordCtrl.text) {
                          return 'Passwords do not match';
                        }
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
                  if (widget.lockedBranchId == null) ...[
                    AppDropdown<String>(
                      value: _selectedBranchId,
                      hint: 'Select branch',
                      items: widget.branches
                          .map(
                            (b) =>
                                AppDropdownItem(value: b.id, label: b.name),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedBranchId = v),
                      validator: (v) =>
                          v == null ? 'Please select a branch' : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  AppDropdown<EmployeeRole>(
                    value: _role,
                    items: (widget.allowedRoles ?? EmployeeRole.values)
                        .map(
                          (r) => AppDropdownItem(
                            value: r,
                            label: r.displayName,
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _role = v);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Form-level error banner ───────────────────────────────
              if (_formError != null) ...[
                _FormErrorBanner(
                  message: _formError!,
                  onDismiss: () => setState(() => _formError = null),
                ),
                const SizedBox(height: 14),
              ],

              // ── Actions ───────────────────────────────────────────────
              if (widget.isPage)
                SizedBox(
                  width: double.infinity,
                  child: AppFilledButton(
                    label: _isEditing ? 'Save Changes' : 'Add Employee',
                    loading: _submitting,
                    onPressed: _submitting ? null : _submit,
                    icon: _isEditing ? Icons.check : Icons.person_add,
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _submitting ? null : () => Navigator.of(context).pop(),
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
                        onPressed: _submitting ? null : _submit,
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

// ── Form-level error banner ───────────────────────────────────────────────────

class _FormErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _FormErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: getOutfitStyle(
                fontSize: 13,
                color: const Color(0xFF991B1B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(
              Icons.close,
              size: 16,
              color: Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}
