import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/ui/widgets/permission_gate.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
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

    // Load branches for form dialogs
    final branchRows = await sl<BranchesDao>().getByBusinessId(businessId);
    if (mounted) {
      setState(() {
        _branches = branchRows
            .map(
              (r) => Branch(
                id: r.id,
                businessId: r.businessId,
                name: r.name,
                address: r.address,
                phone: r.phone,
                isActive: r.isActive,
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

  void _showAddDialog() {
    showEmployeeFormDialog(context: context, branches: _branches);
  }

  void _showEditDialog(Employee employee) {
    showEmployeeFormDialog(
      context: context,
      branches: _branches,
      employee: employee,
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
    return BlocListener<BranchCubit, BranchState>(
      listener: (ctx, _) => _initialize(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppSubPageBar(
          title: 'Employees',
          actions: [
            PermissionGate(
              permissionKey: PermissionKeys.employeesCreate,
              child: IconButton(
                icon: const Icon(IconlyLight.plus, color: AppColors.brand),
                onPressed: _showAddDialog,
                tooltip: 'Add Employee',
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            const EmployeeFilterBar(),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<EmployeeBloc, EmployeeState>(
                builder: (context, state) {
                  if (state is EmployeeLoading || state is EmployeeInitial) {
                    return const _EmployeeSkeletonGrid();
                  }
                  if (state is EmployeeError) {
                    return _ErrorView(message: state.message);
                  }

                  final loaded = state is EmployeeLoaded
                      ? state
                      : state is EmployeeOperationInProgress
                      ? state.previous
                      : state is EmployeeValidationFailure
                      ? state.loaded
                      : null;

                  if (loaded == null) return const SizedBox.shrink();

                  return Column(
                    children: [
                      _StatsRow(loaded: loaded),
                      Expanded(
                        child: loaded.displayEmployees.isEmpty
                            ? _EmptyState(
                                hasFilters: loaded.hasActiveFilters,
                                onAdd:
                                    sl<PermissionService>().can(
                                      PermissionKeys.employeesCreate,
                                    )
                                    ? _showAddDialog
                                    : null,
                              )
                            : _EmployeeList(
                                employees: loaded.displayEmployees,
                                branches: _branches,
                                onTap: _showDetails,
                                onEdit:
                                    sl<PermissionService>().can(
                                      PermissionKeys.employeesEdit,
                                    )
                                    ? _showEditDialog
                                    : null,
                                onArchive:
                                    sl<PermissionService>().can(
                                      PermissionKeys.employeesEdit,
                                    )
                                    ? _confirmArchive
                                    : null,
                                onSuspend:
                                    sl<PermissionService>().can(
                                      PermissionKeys.employeesSuspend,
                                    )
                                    ? (e) => context.read<EmployeeBloc>().add(
                                        SuspendEmployee(e.id),
                                      )
                                    : null,
                                onReactivate:
                                    sl<PermissionService>().can(
                                      PermissionKeys.employeesSuspend,
                                    )
                                    ? (e) => context.read<EmployeeBloc>().add(
                                        ReactivateEmployee(e.id),
                                      )
                                    : null,
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: PermissionGate(
          permissionKey: PermissionKeys.employeesCreate,
          child: FloatingActionButton.extended(
            onPressed: _showAddDialog,
            backgroundColor: AppColors.brand,
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: Text(
              'Add Employee',
              style: getOutfitStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stats Row ──────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final EmployeeLoaded loaded;
  const _StatsRow({required this.loaded});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _StatChip(
            label: 'Active',
            count: loaded.activeCount,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Suspended',
            count: loaded.suspendedCount,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Archived',
            count: loaded.archivedCount,
            color: AppColors.textMuted,
          ),
          const Spacer(),
          Text(
            '${loaded.displayEmployees.length} shown',
            style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: getOutfitStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Employee List ──────────────────────────────────────────────────────────

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
    Breakpoints.isTablet(context);
    final padding = EdgeInsets.symmetric(
      horizontal: Breakpoints.horizontalPadding(context),
      vertical: 8,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int columns;
        if (width >= 1440) {
          columns = 5;
        } else if (width >= 1024) {
          columns = 4;
        } else if (width >= 800) {
          columns = 3;
        } else if (width >= 600) {
          columns = 2;
        } else {
          columns = 1;
        }
        const spacing = 12.0;
        final rowCount = (employees.length / columns).ceil();

        return SingleChildScrollView(
          padding: padding,
          child: Column(
            children: List.generate(rowCount, (rowIndex) {
              final start = rowIndex * columns;
              final end = (start + columns).clamp(0, employees.length);
              final rowItems = employees.sublist(start, end);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: rowIndex < rowCount - 1 ? spacing : 0,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < columns; i++) ...[
                        if (i > 0) const SizedBox(width: spacing),
                        Expanded(
                          child: i < rowItems.length
                              ? _buildCard(rowItems[i])
                              : const SizedBox(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildCard(Employee employee) {
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
      onSuspend: onSuspend != null && employee.status == EmployeeStatus.active
          ? () => onSuspend!(employee)
          : null,
      onReactivate:
          onReactivate != null && employee.status != EmployeeStatus.active
          ? () => onReactivate!(employee)
          : null,
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback? onAdd;

  const _EmptyState({required this.hasFilters, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                IconlyLight.profile,
                size: 32,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters
                  ? 'No employees match your filters'
                  : 'No employees yet',
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
                  : 'Add your first employee to get started.',
              style: getOutfitStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasFilters && onAdd != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 180,
                child: AppFilledButton(
                  label: 'Add Employee',
                  icon: Icons.person_add,
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

// ── Error View ─────────────────────────────────────────────────────────────

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

// ── Skeleton Grid ──────────────────────────────────────────────────────────

class _EmployeeSkeletonGrid extends StatelessWidget {
  const _EmployeeSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.symmetric(
      horizontal: Breakpoints.horizontalPadding(context),
      vertical: 8,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int columns;
        if (width >= 1440) {
          columns = 5;
        } else if (width >= 1024) {
          columns = 4;
        } else if (width >= 800) {
          columns = 3;
        } else if (width >= 600) {
          columns = 2;
        } else {
          columns = 1;
        }
        const spacing = 12.0;
        const itemCount = 8;
        final rowCount = (itemCount / columns).ceil();

        return SingleChildScrollView(
          padding: padding,
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: List.generate(rowCount, (rowIndex) {
              final start = rowIndex * columns;
              final end = (start + columns).clamp(0, itemCount);
              final cellCount = end - start;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: rowIndex < rowCount - 1 ? spacing : 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < columns; i++) ...[
                      if (i > 0) const SizedBox(width: spacing),
                      Expanded(
                        child: i < cellCount
                            ? const EmployeeCardSkeleton()
                            : const SizedBox(),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
