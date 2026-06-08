import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/permissions/data/permission_remote_ds.dart';
import 'package:pos/core/widgets/app_section_card.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';

// ── Permission groups ──────────────────────────────────────────────────────

class _PermGroup {
  final String label;
  final IconData icon;
  final List<_PermEntry> permissions;
  const _PermGroup({
    required this.label,
    required this.icon,
    required this.permissions,
  });
}

class _PermEntry {
  final String code;
  final String label;
  const _PermEntry(this.code, this.label);
}

const _kGroups = <_PermGroup>[
  _PermGroup(
    label: 'POS',
    icon: IconlyLight.buy,
    permissions: [
      _PermEntry('pos.use', 'Use POS terminal'),
      _PermEntry('pos.open_shift', 'Open shift'),
      _PermEntry('pos.close_shift', 'Close shift'),
      _PermEntry('pos.apply_discount', 'Apply discount'),
      _PermEntry('pos.void_sale', 'Void sale'),
      _PermEntry('pos.refund_sale', 'Refund sale'),
      _PermEntry('pos.view_own_sales', 'View own sales'),
      _PermEntry('pos.view_all_sales', 'View all sales'),
    ],
  ),
  _PermGroup(
    label: 'Products',
    icon: IconlyLight.bag,
    permissions: [
      _PermEntry('products.view', 'View products'),
      _PermEntry('products.create', 'Create products'),
      _PermEntry('products.edit', 'Edit products'),
      _PermEntry('products.delete', 'Delete products'),
      _PermEntry('products.manage_prices', 'Manage prices'),
      _PermEntry('products.manage_categories', 'Manage categories'),
    ],
  ),
  _PermGroup(
    label: 'Inventory',
    icon: IconlyLight.bag_2,
    permissions: [
      _PermEntry('inventory.view', 'View inventory'),
      _PermEntry('inventory.adjust', 'Adjust stock'),
      _PermEntry('inventory.view_levels', 'View stock levels'),
      _PermEntry('inventory.manage_suppliers', 'Manage suppliers'),
    ],
  ),
  _PermGroup(
    label: 'Expenses',
    icon: IconlyLight.wallet,
    permissions: [
      _PermEntry('expenses.view', 'View expenses'),
      _PermEntry('expenses.create', 'Create expenses'),
      _PermEntry('expenses.approve', 'Approve expenses'),
      _PermEntry('expenses.delete', 'Delete expenses'),
    ],
  ),
  _PermGroup(
    label: 'Reports',
    icon: IconlyLight.chart,
    permissions: [
      _PermEntry('reports.view_own', 'View own reports'),
      _PermEntry('reports.view_branch', 'View branch reports'),
      _PermEntry('reports.view_all', 'View all reports'),
      _PermEntry('reports.export', 'Export reports'),
    ],
  ),
  _PermGroup(
    label: 'Employees',
    icon: IconlyLight.profile,
    permissions: [
      _PermEntry('employees.view', 'View employees'),
      _PermEntry('employees.create', 'Create employees'),
      _PermEntry('employees.edit', 'Edit employees'),
      _PermEntry('employees.suspend', 'Suspend employees'),
      _PermEntry('employees.assign_role', 'Assign roles'),
    ],
  ),
  _PermGroup(
    label: 'Settings',
    icon: IconlyLight.setting,
    permissions: [
      _PermEntry('settings.view', 'View settings'),
      _PermEntry('settings.edit_receipt', 'Edit receipt settings'),
      _PermEntry('settings.edit_business', 'Edit business settings'),
      _PermEntry('settings.edit_branch', 'Edit branch settings'),
    ],
  ),
  _PermGroup(
    label: 'Audit & Suppliers',
    icon: IconlyLight.document,
    permissions: [
      _PermEntry('audit_logs.view', 'View audit logs'),
      _PermEntry('suppliers.view', 'View suppliers'),
      _PermEntry('suppliers.manage', 'Manage suppliers'),
    ],
  ),
];

// ── Override value: null = role default, true = grant, false = deny ─────────

// ── Cubit state ────────────────────────────────────────────────────────────

sealed class EmployeePermissionsState {}

class EmployeePermissionsLoading extends EmployeePermissionsState {}

class EmployeePermissionsError extends EmployeePermissionsState {
  final String message;
  EmployeePermissionsError(this.message);
}

class EmployeePermissionsLoaded extends EmployeePermissionsState {
  /// `true` = explicit grant, `false` = explicit deny.
  /// A missing key means no override (role default).
  final Map<String, bool> overrides;
  final Set<String> saving;

  EmployeePermissionsLoaded({required this.overrides, Set<String>? saving})
      : saving = saving ?? const {};

  EmployeePermissionsLoaded copyWith({
    Map<String, bool>? overrides,
    Set<String>? saving,
  }) => EmployeePermissionsLoaded(
    overrides: overrides ?? this.overrides,
    saving: saving ?? this.saving,
  );
}

// ── Cubit ──────────────────────────────────────────────────────────────────

class EmployeePermissionsCubit extends Cubit<EmployeePermissionsState> {
  final Employee employee;

  EmployeePermissionsCubit(this.employee)
      : super(EmployeePermissionsLoading());

  Future<void> load() async {
    try {
      final overrides = await sl<PermissionRemoteDs>()
          .fetchUserPermissionOverrides(employee.id);
      emit(EmployeePermissionsLoaded(overrides: overrides));
    } catch (e) {
      emit(EmployeePermissionsError('Failed to load permission overrides.'));
    }
  }

  /// Sets an explicit override ([granted] = true/false) or removes it ([granted] = null).
  Future<void> setOverride(String permissionCode, bool? granted) async {
    final current = state;
    if (current is! EmployeePermissionsLoaded) return;
    if (current.saving.contains(permissionCode)) return;

    // Optimistic update
    final newOverrides = Map<String, bool>.of(current.overrides);
    if (granted == null) {
      newOverrides.remove(permissionCode);
    } else {
      newOverrides[permissionCode] = granted;
    }

    emit(current.copyWith(
      overrides: newOverrides,
      saving: {...current.saving, permissionCode},
    ));

    try {
      final remote = sl<PermissionRemoteDs>();
      if (granted == null) {
        await remote.removeUserPermissionOverride(employee.id, permissionCode);
      } else {
        await remote.setUserPermissionOverride(
          employee.id,
          permissionCode,
          granted,
        );
      }
    } catch (_) {
      // Roll back
      final s = state;
      if (s is EmployeePermissionsLoaded) {
        final rollback = Map<String, bool>.of(s.overrides);
        if (current.overrides.containsKey(permissionCode)) {
          rollback[permissionCode] = current.overrides[permissionCode]!;
        } else {
          rollback.remove(permissionCode);
        }
        emit(s.copyWith(overrides: rollback));
      }
    } finally {
      final s = state;
      if (s is EmployeePermissionsLoaded) {
        final newSaving = Set<String>.of(s.saving)..remove(permissionCode);
        emit(s.copyWith(saving: newSaving));
      }
    }
  }
}

// ── Page ───────────────────────────────────────────────────────────────────

class EmployeePermissionsPage extends StatelessWidget {
  final Employee employee;

  const EmployeePermissionsPage({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EmployeePermissionsCubit(employee)..load(),
      child: _EmployeePermissionsView(employee: employee),
    );
  }
}

class _EmployeePermissionsView extends StatelessWidget {
  final Employee employee;
  const _EmployeePermissionsView({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageBar(title: 'Permission Overrides'),
      body: BlocBuilder<EmployeePermissionsCubit, EmployeePermissionsState>(
        builder: (context, state) {
          if (state is EmployeePermissionsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EmployeePermissionsError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(IconlyLight.danger, size: 40, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: getOutfitStyle(
                        fontSize: 14, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () =>
                        context.read<EmployeePermissionsCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final loaded = state as EmployeePermissionsLoaded;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Employee header chip
              _EmployeeChip(employee: employee),
              const SizedBox(height: 12),

              // Legend
              _Legend(),
              const SizedBox(height: 20),

              // Permission groups
              for (final group in _kGroups) ...[
                AppSectionCard(
                  title: group.label,
                  icon: group.icon,
                  children: [
                    for (int i = 0; i < group.permissions.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 20,
                          thickness: 1,
                          color: AppColors.borderSoft,
                        ),
                      _PermissionRow(
                        entry: group.permissions[i],
                        overrideValue: loaded.overrides[group.permissions[i].code],
                        saving: loaded.saving
                            .contains(group.permissions[i].code),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

// ── Employee chip ──────────────────────────────────────────────────────────

class _EmployeeChip extends StatelessWidget {
  final Employee employee;
  const _EmployeeChip({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Icon(IconlyLight.profile, size: 18, color: AppColors.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.fullName,
                  style: getOutfitStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (employee.roleName != null)
                  Text(
                    employee.roleName!,
                    style: getOutfitStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Overrides only',
              style: getOutfitStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Legend ─────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LegendDot(color: AppColors.textMuted, label: 'Role default'),
        const SizedBox(width: 16),
        _LegendDot(color: AppColors.success, label: 'Grant'),
        const SizedBox(width: 16),
        _LegendDot(color: AppColors.error, label: 'Deny'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

// ── Permission row ─────────────────────────────────────────────────────────

class _PermissionRow extends StatelessWidget {
  final _PermEntry entry;
  final bool? overrideValue; // null = default, true = grant, false = deny
  final bool saving;

  const _PermissionRow({
    required this.entry,
    required this.overrideValue,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            entry.label,
            style: getOutfitStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        saving
            ? const SizedBox(
                width: 90,
                height: 24,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : _OverrideSegment(
                value: overrideValue,
                onChanged: (v) =>
                    context.read<EmployeePermissionsCubit>().setOverride(
                          entry.code,
                          v,
                        ),
              ),
      ],
    );
  }
}

// ── 3-state segmented control ──────────────────────────────────────────────

class _OverrideSegment extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?> onChanged;

  const _OverrideSegment({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Seg(
          label: 'Deny',
          active: value == false,
          activeColor: AppColors.error,
          onTap: () => onChanged(value == false ? null : false),
        ),
        const SizedBox(width: 4),
        _Seg(
          label: 'Default',
          active: value == null,
          activeColor: AppColors.textMuted,
          onTap: () => onChanged(null),
        ),
        const SizedBox(width: 4),
        _Seg(
          label: 'Grant',
          active: value == true,
          activeColor: AppColors.success,
          onTap: () => onChanged(value == true ? null : true),
        ),
      ],
    );
  }
}

class _Seg extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _Seg({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: active ? activeColor.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: active ? activeColor : AppColors.borderSoft,
          ),
        ),
        child: Text(
          label,
          style: getOutfitStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? activeColor : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
