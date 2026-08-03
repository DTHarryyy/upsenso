import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_dropdown.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/widgets/app_inline_banner.dart';
import 'package:pos/core/widgets/app_input_decoration.dart';
import 'package:pos/core/widgets/app_sticky_action_bar.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/core/widgets/upgrade_prompt.dart';
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
/// allow all roles (Business Owner behaviour).
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

  final List<EmployeeRole>? allowedRoles;
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

  EmployeeRole _role = EmployeeRole.cashier;
  String? _selectedBranchId;
  bool _submitting = false;

  // Server-side field error shown inline under the email field.
  String? _serverEmailError;
  // Generic form-level error shown in a banner above the action buttons.
  String? _formError;

  bool get _isEditing => widget.employee != null;

  // Which roles (including whether Business Owner is offered at all) is
  // decided entirely by the caller per actor tier — see
  // `employees_page.dart`'s `_allowedRoles()`.
  List<EmployeeRole> get _availableRoles =>
      widget.allowedRoles ?? EmployeeRole.values.toList();

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
    super.dispose();
  }

  // Closes this form and nothing else. A bare `Navigator.pop()` is wrong here:
  // the page's success listener runs first and may already have pushed the
  // temp-password sheet on top, so pop() would dismiss that instead and leave
  // the form stuck open.
  void _closeSelf() {
    final route = ModalRoute.of(context);
    if (route == null) return;
    final navigator = Navigator.of(context);
    if (route.isCurrent) {
      navigator.pop(); // keeps the dismiss animation in the normal case
    } else {
      navigator.removeRoute(route);
    }
  }

  void _submit() {
    // Clear any previous server errors before re-validating.
    setState(() {
      _serverEmailError = null;
      _formError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    // The actor's allowed role set is enforced again in the bloc; passing it
    // here is what lets that business-logic check run (the dropdown alone is
    // only UX, not access control).
    final allowedRoleNames = _availableRoles.map((r) => r.displayName).toList();

    if (_isEditing) {
      context.read<EmployeeBloc>().add(
        UpdateEmployee(
          id: widget.employee!.id,
          fullName: _nameCtrl.text.trim(),
          roleName: _role.displayName,
          branchId: _selectedBranchId,
          allowedRoleNames: allowedRoleNames,
        ),
      );
    } else {
      context.read<EmployeeBloc>().add(
        AddEmployee(
          // Business Owner has no single branch — leaving this empty is what
          // gives them all-branch access, same as the real owner (§4).
          branchId: _role == EmployeeRole.owner ? '' : _selectedBranchId!,
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim().toLowerCase(),
          roleName: _role.displayName,
          allowedRoleNames: allowedRoleNames,
        ),
      );
    }
  }

  Widget _buildSubmitButton() => AppFilledButton(
    label: _isEditing ? 'Save Changes' : 'Add Employee',
    loading: _submitting,
    onPressed: _submitting ? null : _submit,
    icon: _isEditing ? Icons.check : Icons.person_add_outlined,
  );

  Widget _buildScrollContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, widget.isPage ? 20 : 20, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Inline header (dialog only) ───────────────────────────
            if (!widget.isPage) ...[
              _DialogHeader(
                isEditing: _isEditing,
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),
            ],

            // ── Personal Information ──────────────────────────────────
            _FormSectionCard(
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
                    decoration:
                        appInputDeco(
                          'e.g. maria@business.com',
                          label: 'Work Email',
                        ).copyWith(
                          errorText: _serverEmailError,
                          helperText:
                              'A temporary password will be generated and '
                              'emailed to this address',
                          helperStyle: getOutfitStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
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
                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
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

            // ── Assignment ────────────────────────────────────────────
            _FormSectionCard(
              title: 'Assignment',
              icon: IconlyLight.work,
              children: [
                if (_role == EmployeeRole.owner) ...[
                  const AppInlineBanner(
                    message: 'Business Owner has access to all branches.',
                    variant: AppInlineBannerVariant.info,
                  ),
                ] else if (widget.lockedBranchId == null) ...[
                  AppDropdown<String>(
                    value: _selectedBranchId,
                    hint: 'Select branch',
                    borderRadius: 10,
                    showShadow: false,
                    showBorder: true,
                    items: widget.branches
                        .map((b) => AppDropdownItem(value: b.id, label: b.name))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedBranchId = v),
                    validator: (v) =>
                        v == null ? 'Please select a branch' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Role',
                  style: getOutfitStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _RoleSelector(
                  value: _role,
                  availableRoles: _availableRoles,
                  onChanged: (r) => setState(() => _role = r),
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

            // ── Actions (dialog mode only — page uses sticky bar) ─────
            if (!widget.isPage)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      // Stays enabled even mid-submit — a stalled network call
                      // must never trap the user behind a barrier with no exit.
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
                  Expanded(child: _buildSubmitButton()),
                ],
              ),
          ],
        ),
      ),
    );
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
          setState(() => _submitting = false);
          _closeSelf();
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
          // The plan is full, not the form wrong — offer the upgrade on top of
          // the inline message. The form stays open and filled in (§4.3).
          if (state.seatLimitReached) {
            showUpgradePrompt(context, UpgradeMoment.seatCap);
          }
        } else if (state is EmployeeError) {
          setState(() {
            _submitting = false;
            _formError = state.message;
          });
        }
      },
      child: widget.isPage
          ? Column(
              children: [
                Expanded(child: _buildScrollContent()),
                AppStickyActionBar(primary: _buildSubmitButton()),
              ],
            )
          : _buildScrollContent(),
    );
  }
}

// ── Dialog header ─────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onClose;

  const _DialogHeader({required this.isEditing, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
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
          isEditing ? 'Edit Employee' : 'Add Employee',
          style: AppTextStyles.headline(context),
        ),
        const Spacer(),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close, size: 20),
          color: AppColors.textMuted,
        ),
      ],
    );
  }
}

// ── Section card ────────────────────────────────────────────────────────────

/// Icon-badge + title header (matching [AppSectionCard]'s layout) over a flat
/// Settings-page-style container (matching `SettingsSection`'s decoration:
/// see `lib/core/widgets/settings_tile.dart`) — radius 14, hairline border, no
/// shadow. Kept local to this form rather than promoted to `core/widgets/`
/// since nothing else uses this exact combination.
class _FormSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _FormSectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.brand.withAlpha(18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: AppColors.brand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.caption(context).copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// ── Role selector ─────────────────────────────────────────────────────────────

class _RoleSelector extends StatelessWidget {
  final EmployeeRole value;
  final List<EmployeeRole> availableRoles;
  final ValueChanged<EmployeeRole> onChanged;

  const _RoleSelector({
    required this.value,
    required this.availableRoles,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < availableRoles.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _RoleCard(
            role: availableRoles[i],
            selected: value == availableRoles[i],
            onTap: () => onChanged(availableRoles[i]),
          ),
        ],
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final EmployeeRole role;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.borderSoft,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.brand.withAlpha(25)
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                role._icon,
                size: 17,
                color: selected ? AppColors.brand : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    role.displayName,
                    style: getOutfitStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.brand : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role._description,
                    style: getOutfitStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: selected
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.brand,
                      size: 20,
                      key: ValueKey(true),
                    )
                  : const SizedBox(width: 20, key: ValueKey(false)),
            ),
          ],
        ),
      ),
    );
  }
}

extension _EmployeeRoleUI on EmployeeRole {
  IconData get _icon {
    switch (this) {
      case EmployeeRole.owner:
        return IconlyLight.shield_done;
      case EmployeeRole.branchManager:
        return IconlyLight.chart;
      case EmployeeRole.cashier:
        return IconlyLight.bag;
      case EmployeeRole.inventoryStaff:
        return IconlyLight.scan;
    }
  }

  String get _description {
    switch (this) {
      case EmployeeRole.owner:
        return 'Full business access';
      case EmployeeRole.branchManager:
        return 'Branch ops, staff & reports';
      case EmployeeRole.cashier:
        return 'POS, shifts & sales only';
      case EmployeeRole.inventoryStaff:
        return 'Stock control & adjustments';
    }
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
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: getOutfitStyle(fontSize: 13, color: AppColors.expense),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, size: 16, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
