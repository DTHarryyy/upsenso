import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/permissions/role_permission_matrix.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/ui/widgets/permission_gate.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/business/domain/entities/branch.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';
import 'package:pos/features/employees/domain/repositories/i_employees_repository.dart';
import 'package:pos/features/employees/presentation/bloc/employee_bloc.dart';
import 'package:pos/features/employees/presentation/bloc/employee_event.dart';
import 'package:pos/features/employees/presentation/bloc/employee_state.dart';
import 'package:pos/features/employees/presentation/dialogs/employee_form_dialog.dart';
import 'package:pos/features/employees/presentation/pages/employee_details_page.dart';
import 'package:pos/features/employees/presentation/widgets/employee_card.dart';
import 'package:pos/features/employees/presentation/widgets/employee_card_skeleton.dart';
import 'package:pos/features/employees/presentation/widgets/employee_filter_bar.dart';

class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EmployeeBloc(sl<IEmployeesRepository>()),
      child: const _EmployeesView(),
    );
  }
}

class _EmployeesView extends StatefulWidget {
  const _EmployeesView();

  @override
  State<_EmployeesView> createState() => _EmployeesViewState();
}

class _EmployeesViewState extends State<_EmployeesView> {
  List<Branch> _branches = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final user = authState.user;
    final businessId = user.businessId ?? '';

    final branchRows = await sl<BranchesDao>().getByBusinessId(businessId);
    if (mounted) {
      setState(() {
        _branches = branchRows
            .map(
              (r) => Branch(
                id: r.id,
                businessId: r.businessId,
                name: r.name,
                location: r.location,
              ),
            )
            .toList();
      });
    }

    // ignore: use_build_context_synchronously
    final branchState = context.read<BranchCubit>().state;

    if (mounted) {
      context.read<EmployeeBloc>().add(
        LoadEmployees(
          businessId: businessId,
          branchId: branchState.selectedBranchId,
          roleName: branchState.roleName,
          userId: user.id,
          userName: user.fullName,
        ),
      );
    }
  }

  List<EmployeeRole>? _allowedRoles() {
    final branchState = context.read<BranchCubit>().state;
    final roleKey = RolePermissionMatrix.normalise(branchState.roleName);
    if (roleKey == RolePermissionMatrix.branchManager) {
      return const [EmployeeRole.cashier, EmployeeRole.inventoryStaff];
    }
    return null;
  }

  String? _lockedBranchId() {
    final branchState = context.read<BranchCubit>().state;
    final roleKey = RolePermissionMatrix.normalise(branchState.roleName);
    if (roleKey == RolePermissionMatrix.branchManager) {
      return branchState.selectedBranchId;
    }
    return null;
  }

  void _showAddDialog() {
    showEmployeeFormDialog(
      context: context,
      branches: _branches,
      allowedRoles: _allowedRoles(),
      lockedBranchId: _lockedBranchId(),
    );
  }

  void _showEditDialog(Employee employee) {
    showEmployeeFormDialog(
      context: context,
      branches: _branches,
      employee: employee,
      allowedRoles: _allowedRoles(),
      lockedBranchId: _lockedBranchId(),
    );
  }

  void _showDetails(Employee employee) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => EmployeeDetailsPage(
          employee: employee,
          branchName: _branches
              .where((b) => b.id == employee.branchId)
              .map((b) => b.name)
              .firstOrNull,
        ),
      ),
    );
  }

  void _confirmArchive(Employee employee) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Archive Employee?',
          style: AppTextStyles.subtitle(
            ctx,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will archive ${employee.fullName}. They will no longer appear in active lists.',
          style: getOutfitStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: getOutfitStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Archive',
              style: getOutfitStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        context.read<EmployeeBloc>().add(ArchiveEmployee(employee.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = sl<PermissionService>().can(
      PermissionKeys.employeesCreate,
    );
    final canEdit = sl<PermissionService>().can(PermissionKeys.employeesEdit);
    final canSuspend = sl<PermissionService>().can(
      PermissionKeys.employeesSuspend,
    );

    return BlocListener<BranchCubit, BranchState>(
      listener: (ctx, _) => _initialize(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // Custom header with subtitle
            const _EmployeesHeader(),

            // Search + filter chips
            EmployeeFilterBar(branches: _branches),

            // Content
            Expanded(
              child: BlocBuilder<EmployeeBloc, EmployeeState>(
                builder: (context, state) {
                  if (state is EmployeeLoading || state is EmployeeInitial) {
                    return const _EmployeeSkeletonList();
                  }
                  if (state is EmployeeError) {
                    return _ErrorView(message: state.message);
                  }

                  final loaded = state is EmployeeLoaded
                      ? state
                      : state is EmployeeOperationInProgress
                      ? state.previous
                      : state is EmployeeOperationSuccess
                      ? state.loaded
                      : state is EmployeeValidationFailure
                      ? state.loaded
                      : null;

                  if (loaded == null) return const SizedBox.shrink();

                  if (loaded.displayEmployees.isEmpty) {
                    return _EmptyState(
                      hasFilters: loaded.hasActiveFilters,
                      onAdd: canCreate ? _showAddDialog : null,
                    );
                  }

                  return _EmployeeList(
                    employees: loaded.displayEmployees,
                    branches: _branches,
                    onTap: _showDetails,
                    onEdit: canEdit ? _showEditDialog : null,
                    onArchive: canEdit ? _confirmArchive : null,
                    onSuspend: canSuspend
                        ? (e) => context.read<EmployeeBloc>().add(
                            SuspendEmployee(e.id),
                          )
                        : null,
                    onReactivate: canSuspend
                        ? (e) => context.read<EmployeeBloc>().add(
                            ReactivateEmployee(e.id),
                          )
                        : null,
                  );
                },
              ),
            ),

            //  Sticky bottom CTA
            PermissionGate(
              permissionKey: PermissionKeys.employeesCreate,
              child: _StickyAddButton(onPressed: _showAddDialog),
            ),
          ],
        ),
      ),
    );
  }
}

// Header

class _EmployeesHeader extends StatelessWidget {
  const _EmployeesHeader();

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(canPop ? 4 : 20, topPad + 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (canPop)
            IconButton(
              icon: const Icon(IconlyLight.arrow_left, size: 22),
              color: AppColors.textPrimary,
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back',
            ),
          if (canPop) const SizedBox(width: 4),
          Expanded(
            child: BlocBuilder<EmployeeBloc, EmployeeState>(
              buildWhen: (p, c) =>
                  (p is EmployeeLoaded) != (c is EmployeeLoaded) ||
                  (p is EmployeeLoaded &&
                      c is EmployeeLoaded &&
                      (p.allEmployees.length != c.allEmployees.length ||
                          p.activeCount != c.activeCount)),
              builder: (context, state) {
                final loaded = state is EmployeeLoaded
                    ? state
                    : state is EmployeeOperationSuccess
                    ? state.loaded
                    : null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Employees',
                      style: AppTextStyles.title(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (loaded != null)
                      Text(
                        '${loaded.allEmployees.length} Total'
                        ' · ${loaded.activeCount} Active'
                        ' · ${loaded.inactiveCount} Inactive',
                        style: getOutfitStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        'Manage your team',
                        style: getOutfitStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Employee List ───────────────────────────────────────────────────────────

class _EmployeeList extends StatelessWidget {
  final List<Employee> employees;
  final List<Branch> branches;
  final ValueChanged<Employee> onTap;
  final ValueChanged<Employee>? onEdit;
  final ValueChanged<Employee>? onArchive;
  final ValueChanged<Employee>? onSuspend;
  final ValueChanged<Employee>? onReactivate;

  const _EmployeeList({
    required this.employees,
    required this.branches,
    required this.onTap,
    this.onEdit,
    this.onArchive,
    this.onSuspend,
    this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = Breakpoints.horizontalPadding(context);

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 16),
      itemCount: employees.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final employee = employees[i];
        final branchName = branches
            .where((b) => b.id == employee.branchId)
            .map((b) => b.name)
            .firstOrNull;

        return EmployeeCard(
          employee: employee,
          branchName: branchName,
          onTap: () => onTap(employee),
          onEdit: onEdit != null ? () => onEdit!(employee) : null,
          onArchive: onArchive != null ? () => onArchive!(employee) : null,
          onSuspend: onSuspend != null && employee.isActive
              ? () => onSuspend!(employee)
              : null,
          onReactivate: onReactivate != null && !employee.isActive
              ? () => onReactivate!(employee)
              : null,
        );
      },
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback? onAdd;

  const _EmptyState({required this.hasFilters, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                IconlyLight.profile,
                size: 36,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilters ? 'No results found' : 'No employees yet',
              style: AppTextStyles.subtitle(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your search or filter criteria.'
                  : 'Add your first employee to start managing\nstaff access and permissions.',
              style: getOutfitStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasFilters && onAdd != null) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: AppFilledButton(
                  label: '+ Add Employee',
                  onPressed: onAdd,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Error View ──────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: getOutfitStyle(fontSize: 14, color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Skeleton List ───────────────────────────────────────────────────────────

class _EmployeeSkeletonList extends StatelessWidget {
  const _EmployeeSkeletonList();

  @override
  Widget build(BuildContext context) {
    final hPad = Breakpoints.horizontalPadding(context);

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) => const EmployeeCardSkeleton(),
    );
  }
}

// ── Sticky Bottom CTA ───────────────────────────────────────────────────────

class _StickyAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _StickyAddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      child: AppFilledButton(label: '+ Add Employee', onPressed: onPressed),
    );
  }
}
