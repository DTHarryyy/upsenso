import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/permissions/data/permission_remote_ds.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/core/widgets/app_toast.dart';
import 'package:pos/core/widgets/user_avatar.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Permission catalogue ──────────────────────────────────────────────────────

class _PermGroup {
  final String label;
  final String description;
  final IconData icon;
  final List<_PermEntry> permissions;
  const _PermGroup({
    required this.label,
    required this.description,
    required this.icon,
    required this.permissions,
  });
}

class _PermEntry {
  final String code;
  final String label;
  final String description;
  const _PermEntry(this.code, this.label, this.description);
}

const _kGroups = <_PermGroup>[
  _PermGroup(
    label: 'Point of Sale',
    description: 'POS terminal, shifts, sales, discounts and refunds',
    icon: IconlyLight.buy,
    permissions: [
      _PermEntry(
        'pos.use',
        'Use POS Terminal',
        'Open the cashier screen and process sales',
      ),
      _PermEntry(
        'pos.open_shift',
        'Open Shift',
        'Start a new shift and open the cash drawer',
      ),
      _PermEntry(
        'pos.close_shift',
        'Close Shift',
        'End the current shift and reconcile the drawer',
      ),
      _PermEntry(
        'pos.apply_discount',
        'Apply Discounts',
        'Apply percentage or fixed discounts at checkout',
      ),
      _PermEntry(
        'pos.hold_sale',
        'Hold Sales',
        'Suspend a sale to resume later and open the Held Sales screen',
      ),
      _PermEntry(
        'pos.void_sale',
        'Void a Sale',
        'Cancel a completed transaction',
      ),
      _PermEntry(
        'pos.approve_void',
        'Approve Void Requests',
        'Approve cashier void requests',
      ),
      _PermEntry(
        'pos.refund_sale',
        'Process Refunds',
        'Issue refunds against previous sales',
      ),
      _PermEntry(
        'pos.view_own_sales',
        'View Own Sales',
        'See only their own transactions',
      ),
      _PermEntry(
        'pos.view_all_sales',
        'View All Sales',
        'See all transactions across the branch',
      ),
    ],
  ),
  _PermGroup(
    label: 'Products',
    description: 'Product catalogue, pricing and categories',
    icon: IconlyLight.bag,
    permissions: [
      _PermEntry(
        'products.view',
        'View Products',
        'Browse the product catalogue',
      ),
      _PermEntry(
        'products.create',
        'Add Products',
        'Add new products to the catalogue',
      ),
      _PermEntry(
        'products.edit',
        'Edit Products',
        'Modify product details and descriptions',
      ),
      _PermEntry(
        'products.delete',
        'Delete Products',
        'Permanently remove products',
      ),
      _PermEntry(
        'products.manage_prices',
        'Manage Prices',
        'Update product pricing and price tiers',
      ),
      _PermEntry(
        'products.manage_categories',
        'Manage Categories',
        'Create and edit product categories',
      ),
    ],
  ),
  _PermGroup(
    label: 'Inventory',
    description: 'Stock levels, adjustments and supplier records',
    icon: IconlyLight.bag_2,
    permissions: [
      _PermEntry(
        'inventory.view',
        'View Inventory',
        'Browse stock levels and records',
      ),
      _PermEntry(
        'inventory.adjust',
        'Adjust Stock',
        'Make manual stock adjustments',
      ),
      _PermEntry(
        'inventory.view_levels',
        'View Stock Levels',
        'See quantities and reorder thresholds',
      ),
      _PermEntry(
        'inventory.manage_suppliers',
        'Manage Suppliers',
        'Add, edit, and remove supplier records',
      ),
    ],
  ),
  _PermGroup(
    label: 'Expenses',
    description: 'Expense records, submissions and approvals',
    icon: IconlyLight.wallet,
    permissions: [
      _PermEntry(
        'expenses.view',
        'View Expenses',
        'Browse business expense records',
      ),
      _PermEntry(
        'expenses.create',
        'Record Expenses',
        'Submit new business expenses',
      ),
      _PermEntry(
        'expenses.approve',
        'Approve Expenses',
        'Approve or reject pending expense submissions',
      ),
      _PermEntry(
        'expenses.delete',
        'Delete Expenses',
        'Remove expense records permanently',
      ),
    ],
  ),
  _PermGroup(
    label: 'Reports',
    description: 'Analytics, performance reports and exports',
    icon: IconlyLight.chart,
    permissions: [
      _PermEntry(
        'reports.view_own',
        'View Own Reports',
        'Access personal performance and sales reports',
      ),
      _PermEntry(
        'reports.view_branch',
        'View Branch Reports',
        'Access branch-wide analytics and summaries',
      ),
      _PermEntry(
        'reports.view_all',
        'View All Reports',
        'Access reports across every branch',
      ),
      _PermEntry(
        'reports.export',
        'Export Reports',
        'Download reports as CSV or PDF',
      ),
    ],
  ),
  _PermGroup(
    label: 'Employees',
    description: 'Employee accounts, roles and access settings',
    icon: IconlyLight.profile,
    permissions: [
      _PermEntry(
        'employees.view',
        'View Employees',
        'Browse the employee directory',
      ),
      _PermEntry(
        'employees.create',
        'Add Employees',
        'Create new employee accounts',
      ),
      _PermEntry(
        'employees.edit',
        'Edit Employees',
        'Update employee profile details',
      ),
      _PermEntry(
        'employees.suspend',
        'Suspend Employees',
        'Temporarily deactivate an employee account',
      ),
      _PermEntry(
        'employees.assign_role',
        'Assign Roles & Access',
        'Change the role and access settings for an employee',
      ),
    ],
  ),
  _PermGroup(
    label: 'Settings',
    description: 'Business, branch and receipt configuration',
    icon: IconlyLight.setting,
    permissions: [
      _PermEntry(
        'settings.view',
        'View Settings',
        'Browse system configuration',
      ),
      _PermEntry(
        'settings.edit_receipt',
        'Edit Receipt Settings',
        'Customise receipt layout and footer text',
      ),
      _PermEntry(
        'settings.edit_business',
        'Edit Business Settings',
        'Update business name, logo, and contact info',
      ),
      _PermEntry(
        'settings.edit_branch',
        'Edit Branch Settings',
        'Manage branch-specific configuration',
      ),
    ],
  ),
  _PermGroup(
    label: 'Audit & Suppliers',
    description: 'Audit log access and supplier directory',
    icon: IconlyLight.document,
    permissions: [
      _PermEntry(
        'audit_logs.view',
        'View Audit Logs',
        'Review system activity and change history',
      ),
      _PermEntry(
        'suppliers.view',
        'View Suppliers',
        'Browse the supplier directory',
      ),
      _PermEntry(
        'suppliers.manage',
        'Manage Suppliers',
        'Add, edit, and remove supplier records',
      ),
    ],
  ),
];

// ── Cubit state ───────────────────────────────────────────────────────────────

sealed class EmployeePermissionsState {}

class EmployeePermissionsLoading extends EmployeePermissionsState {}

class EmployeePermissionsError extends EmployeePermissionsState {
  final String message;
  EmployeePermissionsError(this.message);
}

class EmployeePermissionsLoaded extends EmployeePermissionsState {
  final Map<String, bool> saved;

  /// null = role default (no explicit override)
  final Map<String, bool?> draft;
  final bool isSaving;
  final bool justSaved;

  EmployeePermissionsLoaded({
    required this.saved,
    Map<String, bool?>? draft,
    this.isSaving = false,
    this.justSaved = false,
  }) : draft = draft ?? {};

  bool? effectiveOverride(String code) {
    if (draft.containsKey(code)) return draft[code];
    return saved[code];
  }

  bool get hasDraft => draft.isNotEmpty;
  int get draftCount => draft.length;

  int get totalCustomCount {
    final codes = {...saved.keys, ...draft.keys};
    return codes.where((c) => effectiveOverride(c) != null).length;
  }

  EmployeePermissionsLoaded copyWith({
    Map<String, bool>? saved,
    Map<String, bool?>? draft,
    bool? isSaving,
    bool? justSaved,
  }) => EmployeePermissionsLoaded(
    saved: saved ?? this.saved,
    draft: draft ?? this.draft,
    isSaving: isSaving ?? this.isSaving,
    justSaved: justSaved ?? false,
  );
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class EmployeePermissionsCubit extends Cubit<EmployeePermissionsState> {
  final Employee employee;

  EmployeePermissionsCubit(this.employee) : super(EmployeePermissionsLoading());

  Future<void> load() async {
    try {
      final overrides = await sl<PermissionRemoteDs>()
          .fetchUserPermissionOverrides(employee.id);
      emit(EmployeePermissionsLoaded(saved: overrides));
    } catch (e, st) {
      debugPrint('[EmployeePermissions] Error in load: $e\n$st');
      emit(EmployeePermissionsError('Failed to load access settings.'));
    }
  }

  void stageDraft(String code, bool? value) {
    final s = state;
    if (s is! EmployeePermissionsLoaded) return;
    final newDraft = Map<String, bool?>.of(s.draft);
    if (value == s.saved[code]) {
      newDraft.remove(code);
    } else {
      newDraft[code] = value;
    }
    emit(s.copyWith(draft: newDraft));
  }

  void stageGroupBulk(List<String> codes, bool? value) {
    final s = state;
    if (s is! EmployeePermissionsLoaded) return;
    final newDraft = Map<String, bool?>.of(s.draft);
    for (final code in codes) {
      if (value == s.saved[code]) {
        newDraft.remove(code);
      } else {
        newDraft[code] = value;
      }
    }
    emit(s.copyWith(draft: newDraft));
  }

  void stageGroupReset(List<String> codes) {
    final s = state;
    if (s is! EmployeePermissionsLoaded) return;
    final newDraft = Map<String, bool?>.of(s.draft);
    for (final code in codes) {
      if (s.saved.containsKey(code)) {
        newDraft[code] = null;
      } else {
        newDraft.remove(code);
      }
    }
    emit(s.copyWith(draft: newDraft));
  }

  void discardDraft() {
    final s = state;
    if (s is! EmployeePermissionsLoaded) return;
    emit(s.copyWith(draft: {}));
  }

  Future<void> saveAll() async {
    final s = state;
    if (s is! EmployeePermissionsLoaded || !s.hasDraft) return;
    emit(s.copyWith(isSaving: true));
    try {
      final remote = sl<PermissionRemoteDs>();
      final audit = sl<AuditLogService>();
      final newSaved = Map<String, bool>.of(s.saved);
      for (final entry in s.draft.entries) {
        if (entry.value == null) {
          await remote.removeUserPermissionOverride(employee.id, entry.key);
          newSaved.remove(entry.key);
          unawaited(
            audit.log(
              actionType: AuditLogActionType.permissionOverrideRemoved,
              entityType: 'employee',
              entityId: employee.id,
              entityName: employee.fullName,
              description:
                  'Removed permission override for "${entry.key}" on ${employee.fullName} — reverted to role default',
              metadata: {'permission_code': entry.key},
            ),
          );
        } else {
          await remote.setUserPermissionOverride(
            employee.id,
            entry.key,
            entry.value!,
          );
          newSaved[entry.key] = entry.value!;
          unawaited(
            audit.log(
              actionType: AuditLogActionType.permissionOverrideSet,
              entityType: 'employee',
              entityId: employee.id,
              entityName: employee.fullName,
              description:
                  '${entry.value! ? 'Granted' : 'Denied'} permission "${entry.key}" for ${employee.fullName}',
              metadata: {
                'permission_code': entry.key,
                'granted': entry.value!,
              },
            ),
          );
        }
      }
      final authUserId = Supabase.instance.client.auth.currentUser?.id;
      if (authUserId != null) {
        await sl<PermissionService>().syncPermissions(authUserId);
      }
      emit(EmployeePermissionsLoaded(saved: newSaved, justSaved: true));
    } catch (e, st) {
      debugPrint('[EmployeePermissions] Error in saveAll: $e\n$st');
      final current = state;
      if (current is EmployeePermissionsLoaded) {
        emit(current.copyWith(isSaving: false));
      }
      rethrow;
    }
  }
}

// ── Page entry point ──────────────────────────────────────────────────────────

class EmployeePermissionsPage extends StatelessWidget {
  final Employee employee;
  const EmployeePermissionsPage({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    if (!sl<PermissionService>().can(PermissionKeys.employeesAssignRole)) {
      return _AccessDeniedPage();
    }

    final isSelf =
        employee.authUserId != null &&
        employee.authUserId == Supabase.instance.client.auth.currentUser?.id;

    return BlocProvider(
      create: (_) => EmployeePermissionsCubit(employee)..load(),
      child: _PermissionsShell(employee: employee, isSelf: isSelf),
    );
  }
}

// ── Shell ─────────────────────────────────────────────────────────────────────

class _PermissionsShell extends StatefulWidget {
  final Employee employee;
  final bool isSelf;
  const _PermissionsShell({required this.employee, required this.isSelf});

  @override
  State<_PermissionsShell> createState() => _PermissionsShellState();
}

class _PermissionsShellState extends State<_PermissionsShell> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_PermGroup> get _filtered {
    if (_query.isEmpty) return _kGroups;
    final q = _query.toLowerCase();
    return _kGroups
        .map((g) {
          final perms = g.permissions
              .where(
                (p) =>
                    p.label.toLowerCase().contains(q) ||
                    p.description.toLowerCase().contains(q) ||
                    p.code.contains(q),
              )
              .toList();
          if (perms.isEmpty) return null;
          return _PermGroup(
            label: g.label,
            description: g.description,
            icon: g.icon,
            permissions: perms,
          );
        })
        .whereType<_PermGroup>()
        .toList();
  }

  Future<void> _save(BuildContext context) async {
    try {
      await context.read<EmployeePermissionsCubit>().saveAll();
    } catch (_) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        'Failed to save',
        subtitle: 'Please try again.',
        variant: AppToastVariant.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EmployeePermissionsCubit, EmployeePermissionsState>(
      listenWhen: (_, s) => s is EmployeePermissionsLoaded && s.justSaved,
      listener: (ctx, _) => AppToast.show(ctx, 'Access settings saved.'),
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context, state),
          body: switch (state) {
            EmployeePermissionsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            EmployeePermissionsError(:final message) => _ErrorBody(
              message: message,
              onRetry: () => context.read<EmployeePermissionsCubit>().load(),
            ),
            EmployeePermissionsLoaded() => _buildBody(context, state),
          },
          bottomNavigationBar:
              state is EmployeePermissionsLoaded && state.hasDraft
              ? _SaveBar(
                  isSaving: state.isSaving,
                  onSave: () => _save(context),
                  onDiscard: () =>
                      context.read<EmployeePermissionsCubit>().discardDraft(),
                )
              : null,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    EmployeePermissionsState state,
  ) {
    return AppSubPageBar(
      title: 'Access Settings',
      actions: state is EmployeePermissionsLoaded && state.hasDraft
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${state.draftCount} unsaved',
                      style: getOutfitStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ]
          : null,
    );
  }

  Widget _buildBody(BuildContext context, EmployeePermissionsLoaded state) {
    final groups = _filtered;
    final totalPerms = _kGroups.fold(0, (s, g) => s + g.permissions.length);
    final grantCount = _kGroups
        .expand((g) => g.permissions)
        .where((p) => state.effectiveOverride(p.code) == true)
        .length;
    final denyCount = _kGroups
        .expand((g) => g.permissions)
        .where((p) => state.effectiveOverride(p.code) == false)
        .length;

    return Column(
      children: [
        // Sticky top block
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              // Role context bar
              _RoleBar(
                employee: widget.employee,
                isSelf: widget.isSelf,
                total: totalPerms,
                granted: grantCount,
                denied: denyCount,
              ),
              const Divider(height: 1, color: AppColors.borderSoft),
              // Search + filter row
              _SearchBar(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
              ),
              const Divider(height: 1, color: AppColors.borderSoft),
            ],
          ),
        ),
        //Scrollable permission groups
        Expanded(
          child: groups.isEmpty
              ? _EmptySearch(query: _query)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  itemCount: groups.length,
                  separatorBuilder: (context, i) => const SizedBox.shrink(),
                  itemBuilder: (ctx, i) =>
                      _PermissionGroup(group: groups[i], state: state),
                ),
        ),
      ],
    );
  }
}

// Role context bar

class _RoleBar extends StatelessWidget {
  final Employee employee;
  final bool isSelf;
  final int total;
  final int granted;
  final int denied;

  const _RoleBar({
    required this.employee,
    required this.isSelf,
    required this.total,
    required this.granted,
    required this.denied,
  });

  @override
  Widget build(BuildContext context) {
    final role = displayRoleName(employee.roleName) ?? 'Unknown Role';
    final defaultCount = total - granted - denied;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(name: employee.fullName, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          employee.fullName,
                          style: getOutfitStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          _Chip(
                            label: 'You',
                            color: AppColors.brand,
                            bg: AppColors.brandSoft,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _Chip(
                          label: role,
                          color: AppColors.textSecondary,
                          bg: AppColors.surfaceAlt,
                        ),
                        if (granted > 0 || denied > 0) ...[
                          const SizedBox(width: 6),
                          _Chip(
                            label: 'Custom access',
                            color: AppColors.warning,
                            bg: AppColors.warningSoft,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isSelf) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are editing your own access. Changes take effect on your next action.',
                      style: getOutfitStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Stat row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatPill(
                value: granted,
                label: 'Allowed',
                color: AppColors.success,
                bg: AppColors.successSoft,
              ),
              _StatPill(
                value: denied,
                label: 'Blocked',
                color: AppColors.error,
                bg: AppColors.errorSoft,
              ),
              _StatPill(
                value: defaultCount,
                label: 'Default',
                color: AppColors.textMuted,
                bg: AppColors.surfaceAlt,
              ),
              Text(
                '$total permissions',
                style: getOutfitStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Chip({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      label,
      style: getOutfitStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );
}

class _StatPill extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final Color bg;
  const _StatPill({
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: getOutfitStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: getOutfitStyle(fontSize: 11, color: color)),
      ],
    ),
  );
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: getOutfitStyle(fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search permissions…',
          hintStyle: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
          prefixIcon: const Icon(
            IconlyLight.search,
            size: 18,
            color: AppColors.textMuted,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceAlt,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── Permission group ──────────────────────────────────────────────────────────

class _PermissionGroup extends StatefulWidget {
  final _PermGroup group;
  final EmployeePermissionsLoaded state;
  const _PermissionGroup({required this.group, required this.state});

  @override
  State<_PermissionGroup> createState() => _PermissionGroupState();
}

class _PermissionGroupState extends State<_PermissionGroup>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _expandCurve;
  late Animation<double> _fadeCurve;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _expandCurve = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _fadeCurve = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      reverseCurve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  List<String> get _codes =>
      widget.group.permissions.map((p) => p.code).toList();

  int get _grantCount => widget.group.permissions
      .where((p) => widget.state.effectiveOverride(p.code) == true)
      .length;

  int get _denyCount => widget.group.permissions
      .where((p) => widget.state.effectiveOverride(p.code) == false)
      .length;

  @override
  Widget build(BuildContext context) {
    final grants = _grantCount;
    final denies = _denyCount;
    final hasCustom = grants > 0 || denies > 0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Column(
        children: [
          // ── Header row ──────────────────────────────────────────────────
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.brand.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.group.icon,
                      size: 16,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.group.label,
                              style: getOutfitStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${widget.group.permissions.length}',
                                style: getOutfitStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (hasCustom)
                          Row(
                            children: [
                              if (grants > 0)
                                _MiniTag(
                                  '$grants allowed',
                                  AppColors.success,
                                  AppColors.successSoft,
                                ),
                              if (grants > 0 && denies > 0)
                                const SizedBox(width: 5),
                              if (denies > 0)
                                _MiniTag(
                                  '$denies blocked',
                                  AppColors.error,
                                  AppColors.errorSoft,
                                ),
                            ],
                          )
                        else
                          Text(
                            widget.group.description,
                            style: getOutfitStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Chevron
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_expandCurve),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded content ────────────────────────────────────────────
          SizeTransition(
            sizeFactor: _expandCurve,
            axisAlignment: -1,
            child: FadeTransition(
              opacity: _fadeCurve,
              child: Column(
              children: [
                // Bulk action bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Apply to all:',
                        style: getOutfitStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _BulkBtn(
                        label: 'Allow All',
                        icon: Icons.check_rounded,
                        color: AppColors.success,
                        bg: AppColors.successSoft,
                        onTap: () => context
                            .read<EmployeePermissionsCubit>()
                            .stageGroupBulk(_codes, true),
                      ),
                      const SizedBox(width: 6),
                      _BulkBtn(
                        label: 'Block All',
                        icon: Icons.block_rounded,
                        color: AppColors.error,
                        bg: AppColors.errorSoft,
                        onTap: () => context
                            .read<EmployeePermissionsCubit>()
                            .stageGroupBulk(_codes, false),
                      ),
                      const SizedBox(width: 6),
                      _BulkBtn(
                        label: 'Reset',
                        icon: Icons.refresh_rounded,
                        color: AppColors.textSecondary,
                        bg: AppColors.surface,
                        onTap: () => context
                            .read<EmployeePermissionsCubit>()
                            .stageGroupReset(_codes),
                      ),
                    ],
                  ),
                ),
                // Column headers
                Container(
                  color: AppColors.surfaceAlt,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Permission',
                          style: getOutfitStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 210,
                        child: Text(
                          'Access Level',
                          style: getOutfitStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderSoft),
                // Permission rows
                ...widget.group.permissions.map(
                  (p) => _PermRow(
                    entry: p,
                    value: widget.state.effectiveOverride(p.code),
                  ),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _MiniTag(this.label, this.color, this.bg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: getOutfitStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );
}

// ── Bulk button ───────────────────────────────────────────────────────────────

class _BulkBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _BulkBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: getOutfitStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Permission row ────────────────────────────────────────────────────────────

class _PermRow extends StatelessWidget {
  final _PermEntry entry;
  final bool? value;
  const _PermRow({
    required this.entry,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isAllowed = value == true;
    final isBlocked = value == false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: isAllowed
            ? AppColors.success.withAlpha(10)
            : isBlocked
            ? AppColors.error.withAlpha(10)
            : AppColors.surface,
        border: Border(
          bottom: const BorderSide(color: AppColors.borderSoft),
          left: BorderSide(
            color: isAllowed
                ? AppColors.success
                : isBlocked
                ? AppColors.error
                : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: getOutfitStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    entry.description,
                    style: getOutfitStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _RadioSelector(
              value: value,
              onChanged: (v) => context
                  .read<EmployeePermissionsCubit>()
                  .stageDraft(entry.code, v),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Radio selector ────────────────────────────────────────────────────────────

class _RadioSelector extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?> onChanged;
  const _RadioSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RadioOption(
            label: 'Default',
            selected: value == null,
            selectedColor: AppColors.brand,
            selectedBg: AppColors.brandSoft,
            isFirst: true,
            onTap: () => onChanged(null),
          ),
          Container(width: 1, height: 28, color: AppColors.borderSoft),
          _RadioOption(
            label: 'Allow',
            selected: value == true,
            selectedColor: AppColors.success,
            selectedBg: AppColors.successSoft,
            onTap: () => onChanged(value == true ? null : true),
          ),
          Container(width: 1, height: 28, color: AppColors.borderSoft),
          _RadioOption(
            label: 'Block',
            selected: value == false,
            selectedColor: AppColors.error,
            selectedBg: AppColors.errorSoft,
            isLast: true,
            onTap: () => onChanged(value == false ? null : false),
          ),
        ],
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final Color selectedBg;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _RadioOption({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.selectedBg,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: isFirst ? const Radius.circular(7) : Radius.zero,
            bottomLeft: isFirst ? const Radius.circular(7) : Radius.zero,
            topRight: isLast ? const Radius.circular(7) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(7) : Radius.zero,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Radio dot
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? selectedColor : AppColors.textMuted,
                  width: 1.5,
                ),
                color: selected ? selectedColor : Colors.transparent,
              ),
              child: selected
                  ? const Center(
                      child: Icon(Icons.circle, size: 5, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: getOutfitStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? selectedColor : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Save bar ──────────────────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  const _SaveBar({
    required this.isSaving,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
        boxShadow: [
          BoxShadow(
            color: Color(0x12101828),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isSaving ? null : onDiscard,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.borderSoft),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: getOutfitStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Discard Changes'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 15),
              label: Text(isSaving ? 'Saving…' : 'Save Changes'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: getOutfitStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Access denied page ────────────────────────────────────────────────────────

class _AccessDeniedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageBar(title: 'Access Settings'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.errorSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  IconlyLight.shield_fail,
                  size: 24,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Access Restricted',
                style: getOutfitStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You need the "Assign Roles & Access" permission to manage employee access settings.',
                style: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty search ──────────────────────────────────────────────────────────────

class _EmptySearch extends StatelessWidget {
  final String query;
  const _EmptySearch({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              IconlyLight.search,
              size: 36,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No results for "$query"',
              style: getOutfitStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different keyword or browse the sections below.',
              style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error body ────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(IconlyLight.danger, size: 36, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              style: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
