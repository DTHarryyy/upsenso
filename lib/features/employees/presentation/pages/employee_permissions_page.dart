import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/permissions/data/permission_remote_ds.dart';
import 'package:pos/core/widgets/app_search_bar.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/core/widgets/user_avatar.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';

// ── Permission catalogue ────────────────────────────────────────────────────

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
  final String description;
  const _PermEntry(this.code, this.label, this.description);
}

const _kGroups = <_PermGroup>[
  _PermGroup(
    label: 'POS',
    icon: IconlyLight.buy,
    permissions: [
      _PermEntry('pos.use', 'Use POS Terminal',
          'Access and operate the point-of-sale terminal'),
      _PermEntry('pos.open_shift', 'Open Shift',
          'Start a new shift and open the cash drawer'),
      _PermEntry('pos.close_shift', 'Close Shift',
          'End the current shift and reconcile the drawer'),
      _PermEntry('pos.apply_discount', 'Apply Discount',
          'Apply percentage or fixed discounts during checkout'),
      _PermEntry(
          'pos.void_sale', 'Void Sale', 'Cancel a completed transaction'),
      _PermEntry('pos.refund_sale', 'Process Refund',
          'Issue refunds against previous sales'),
      _PermEntry('pos.view_own_sales', 'View Own Sales',
          'View transactions made by this employee'),
      _PermEntry('pos.view_all_sales', 'View All Sales',
          'View all transactions across the branch'),
    ],
  ),
  _PermGroup(
    label: 'Products',
    icon: IconlyLight.bag,
    permissions: [
      _PermEntry(
          'products.view', 'View Products', 'Browse the product catalogue'),
      _PermEntry('products.create', 'Create Products',
          'Add new products to the catalogue'),
      _PermEntry('products.edit', 'Edit Products',
          'Modify existing product details and pricing'),
      _PermEntry('products.delete', 'Delete Products',
          'Remove products from the catalogue'),
      _PermEntry('products.manage_prices', 'Manage Prices',
          'Update product pricing and price tiers'),
      _PermEntry('products.manage_categories', 'Manage Categories',
          'Create and edit product categories'),
    ],
  ),
  _PermGroup(
    label: 'Inventory',
    icon: IconlyLight.bag_2,
    permissions: [
      _PermEntry('inventory.view', 'View Inventory',
          'Browse stock levels and inventory records'),
      _PermEntry('inventory.adjust', 'Adjust Stock',
          'Make manual stock adjustments with a reason'),
      _PermEntry('inventory.view_levels', 'View Stock Levels',
          'See current quantities and reorder thresholds'),
      _PermEntry('inventory.manage_suppliers', 'Manage Suppliers',
          'Add, edit, and remove supplier records'),
    ],
  ),
  _PermGroup(
    label: 'Expenses',
    icon: IconlyLight.wallet,
    permissions: [
      _PermEntry(
          'expenses.view', 'View Expenses', 'Browse business expense records'),
      _PermEntry('expenses.create', 'Create Expenses',
          'Record new business expenses'),
      _PermEntry('expenses.approve', 'Approve Expenses',
          'Approve or reject pending expense submissions'),
      _PermEntry('expenses.delete', 'Delete Expenses',
          'Remove expense records from the system'),
    ],
  ),
  _PermGroup(
    label: 'Reports',
    icon: IconlyLight.chart,
    permissions: [
      _PermEntry('reports.view_own', 'View Own Reports',
          'Access personal performance and sales reports'),
      _PermEntry('reports.view_branch', 'View Branch Reports',
          'Access branch-wide analytics and summaries'),
      _PermEntry('reports.view_all', 'View All Reports',
          'Access all reports across every branch'),
      _PermEntry('reports.export', 'Export Reports',
          'Download reports as CSV or PDF'),
    ],
  ),
  _PermGroup(
    label: 'Employees',
    icon: IconlyLight.profile,
    permissions: [
      _PermEntry('employees.view', 'View Employees',
          'Browse the employee directory'),
      _PermEntry('employees.create', 'Create Employees',
          'Add new employees to the system'),
      _PermEntry(
          'employees.edit', 'Edit Employees', 'Update employee profiles'),
      _PermEntry('employees.suspend', 'Suspend Employees',
          'Temporarily deactivate employee accounts'),
      _PermEntry('employees.assign_role', 'Assign Roles',
          'Change the role assigned to an employee'),
    ],
  ),
  _PermGroup(
    label: 'Settings',
    icon: IconlyLight.setting,
    permissions: [
      _PermEntry(
          'settings.view', 'View Settings', 'Browse system configuration'),
      _PermEntry('settings.edit_receipt', 'Edit Receipt Settings',
          'Customise receipt layout and footer text'),
      _PermEntry('settings.edit_business', 'Edit Business Settings',
          'Update business name, logo, and contact info'),
      _PermEntry('settings.edit_branch', 'Edit Branch Settings',
          'Manage branch-specific configuration'),
    ],
  ),
  _PermGroup(
    label: 'Audit & Suppliers',
    icon: IconlyLight.document,
    permissions: [
      _PermEntry('audit_logs.view', 'View Audit Logs',
          'Review system activity and change history'),
      _PermEntry(
          'suppliers.view', 'View Suppliers', 'Browse the supplier directory'),
      _PermEntry('suppliers.manage', 'Manage Suppliers',
          'Add, edit, and remove supplier records'),
    ],
  ),
];

// ── Cubit state ─────────────────────────────────────────────────────────────

sealed class EmployeePermissionsState {}

class EmployeePermissionsLoading extends EmployeePermissionsState {}

class EmployeePermissionsError extends EmployeePermissionsState {
  final String message;
  EmployeePermissionsError(this.message);
}

class EmployeePermissionsLoaded extends EmployeePermissionsState {
  /// Saved overrides fetched from the server.
  final Map<String, bool> saved;

  /// Local draft edits staged before the user hits Save.
  /// null value means "remove this override" (revert to inherited).
  final Map<String, bool?> draft;

  final bool isSaving;

  EmployeePermissionsLoaded({
    required this.saved,
    Map<String, bool?>? draft,
    this.isSaving = false,
  }) : draft = draft ?? {};

  /// Effective value: draft wins over saved; null = inherited.
  bool? effectiveOverride(String code) {
    if (draft.containsKey(code)) return draft[code];
    return saved[code];
  }

  bool get hasDraft => draft.isNotEmpty;
  int get draftCount => draft.length;

  int get totalOverrideCount {
    final codes = {...saved.keys, ...draft.keys};
    return codes.where((c) => effectiveOverride(c) != null).length;
  }

  EmployeePermissionsLoaded copyWith({
    Map<String, bool>? saved,
    Map<String, bool?>? draft,
    bool? isSaving,
  }) =>
      EmployeePermissionsLoaded(
        saved: saved ?? this.saved,
        draft: draft ?? this.draft,
        isSaving: isSaving ?? this.isSaving,
      );
}

// ── Cubit ────────────────────────────────────────────────────────────────────

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
      emit(EmployeePermissionsError('Failed to load permission overrides.'));
    }
  }

  void stageDraft(String code, bool? value) {
    final s = state;
    if (s is! EmployeePermissionsLoaded) return;

    final newDraft = Map<String, bool?>.of(s.draft);

    // No change vs saved → drop from draft
    final savedValue = s.saved[code];
    if (value == savedValue) {
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
      final newSaved = Map<String, bool>.of(s.saved);

      for (final entry in s.draft.entries) {
        if (entry.value == null) {
          await remote.removeUserPermissionOverride(employee.id, entry.key);
          newSaved.remove(entry.key);
        } else {
          await remote.setUserPermissionOverride(
              employee.id, entry.key, entry.value!);
          newSaved[entry.key] = entry.value!;
        }
      }

      emit(EmployeePermissionsLoaded(saved: newSaved));
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

// ── Page entry point ─────────────────────────────────────────────────────────

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

// ── Main view ────────────────────────────────────────────────────────────────

class _EmployeePermissionsView extends StatefulWidget {
  final Employee employee;
  const _EmployeePermissionsView({required this.employee});

  @override
  State<_EmployeePermissionsView> createState() =>
      _EmployeePermissionsViewState();
}

class _EmployeePermissionsViewState extends State<_EmployeePermissionsView> {
  String _query = '';

  List<_PermGroup> get _filteredGroups {
    if (_query.isEmpty) return _kGroups;
    final q = _query.toLowerCase();
    return _kGroups
        .map((g) {
          final perms = g.permissions
              .where((p) =>
                  p.label.toLowerCase().contains(q) ||
                  p.description.toLowerCase().contains(q) ||
                  p.code.toLowerCase().contains(q))
              .toList();
          if (perms.isEmpty) return null;
          return _PermGroup(label: g.label, icon: g.icon, permissions: perms);
        })
        .whereType<_PermGroup>()
        .toList();
  }

  Future<void> _save(BuildContext context) async {
    try {
      await context.read<EmployeePermissionsCubit>().saveAll();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save changes. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeePermissionsCubit, EmployeePermissionsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppSubPageBar(title: 'Permission Overrides'),
          body: switch (state) {
            EmployeePermissionsLoading() =>
              const Center(child: CircularProgressIndicator()),
            EmployeePermissionsError(:final message) => _ErrorBody(
                message: message,
                onRetry: () =>
                    context.read<EmployeePermissionsCubit>().load(),
              ),
            EmployeePermissionsLoaded() => _LoadedBody(
                employee: widget.employee,
                state: state,
                query: _query,
                filteredGroups: _filteredGroups,
                onQueryChanged: (q) => setState(() => _query = q),
                onSave: () => _save(context),
                onDiscard: () =>
                    context.read<EmployeePermissionsCubit>().discardDraft(),
              ),
          },
        );
      },
    );
  }
}

// ── Loaded body ───────────────────────────────────────────────────────────────

class _LoadedBody extends StatelessWidget {
  final Employee employee;
  final EmployeePermissionsLoaded state;
  final String query;
  final List<_PermGroup> filteredGroups;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  const _LoadedBody({
    required this.employee,
    required this.state,
    required this.query,
    required this.filteredGroups,
    required this.onQueryChanged,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    _EmployeeHeader(employee: employee, state: state),
                    const SizedBox(height: 12),
                    _SummaryBar(state: state),
                    const SizedBox(height: 16),
                    AppSearchBar(
                      hint: 'Search permissions...',
                      onChanged: onQueryChanged,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            if (filteredGroups.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptySearch(query: query),
              )
            else ...[
              for (final group in filteredGroups)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _CategorySection(group: group, state: state),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ],
        ),
        if (state.hasDraft)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SaveBar(
              draftCount: state.draftCount,
              isSaving: state.isSaving,
              onSave: onSave,
              onDiscard: onDiscard,
            ),
          ),
      ],
    );
  }
}

// ── Employee header ───────────────────────────────────────────────────────────

class _EmployeeHeader extends StatelessWidget {
  final Employee employee;
  final EmployeePermissionsLoaded state;

  const _EmployeeHeader({required this.employee, required this.state});

  @override
  Widget build(BuildContext context) {
    final overrideCount = state.totalOverrideCount;
    final role = displayRoleName(employee.roleName) ?? 'Unknown Role';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07101828),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          UserAvatar(name: employee.fullName, radius: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.fullName,
                  style: getOutfitStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: getOutfitStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (overrideCount > 0)
            _OverrideBadge(count: overrideCount)
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'No Overrides',
                style: getOutfitStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OverrideBadge extends StatelessWidget {
  final int count;
  const _OverrideBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count Override${count == 1 ? '' : 's'}',
        style: getOutfitStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.warning,
        ),
      ),
    );
  }
}

// ── Summary bar ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final EmployeePermissionsLoaded state;
  const _SummaryBar({required this.state});

  static int get _totalPerms =>
      _kGroups.fold(0, (sum, g) => sum + g.permissions.length);

  @override
  Widget build(BuildContext context) {
    final grantCount = _kGroups
        .expand((g) => g.permissions)
        .where((p) => state.effectiveOverride(p.code) == true)
        .length;
    final denyCount = _kGroups
        .expand((g) => g.permissions)
        .where((p) => state.effectiveOverride(p.code) == false)
        .length;
    final inherited = _totalPerms - grantCount - denyCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          _SummaryItem(
              label: 'Inherited', value: inherited, color: AppColors.textMuted),
          _SummaryDivider(),
          _SummaryItem(
              label: 'Granted', value: grantCount, color: AppColors.success),
          _SummaryDivider(),
          _SummaryItem(
              label: 'Denied', value: denyCount, color: AppColors.error),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _SummaryItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: getOutfitStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: getOutfitStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.borderSoft);
  }
}

// ── Category section ──────────────────────────────────────────────────────────

class _CategorySection extends StatefulWidget {
  final _PermGroup group;
  final EmployeePermissionsLoaded state;

  const _CategorySection({required this.group, required this.state});

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _chevronCtrl;

  @override
  void initState() {
    super.initState();
    _chevronCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _chevronCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _chevronCtrl.forward() : _chevronCtrl.reverse();
  }

  int get _overrideCount => widget.group.permissions
      .where((p) => widget.state.effectiveOverride(p.code) != null)
      .length;

  List<String> get _codes =>
      widget.group.permissions.map((p) => p.code).toList();

  @override
  Widget build(BuildContext context) {
    final overrides = _overrideCount;
    final total = widget.group.permissions.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06101828),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.brand.withAlpha(18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.group.icon,
                        size: 18, color: AppColors.brand),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group.label,
                          style: getOutfitStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          overrides > 0
                              ? '$total Permissions • $overrides Override${overrides == 1 ? '' : 's'}'
                              : '$total Permissions • No Overrides',
                          style: getOutfitStyle(
                            fontSize: 12,
                            color: overrides > 0
                                ? AppColors.warning
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_expanded) ...[
                    _BulkMenu(
                      onGrant: () => context
                          .read<EmployeePermissionsCubit>()
                          .stageGroupBulk(_codes, true),
                      onDeny: () => context
                          .read<EmployeePermissionsCubit>()
                          .stageGroupBulk(_codes, false),
                      onReset: () => context
                          .read<EmployeePermissionsCubit>()
                          .stageGroupReset(_codes),
                    ),
                    const SizedBox(width: 8),
                  ],
                  RotationTransition(
                    turns:
                        Tween(begin: 0.0, end: 0.5).animate(_chevronCtrl),
                    child: const Icon(
                      IconlyLight.arrow_down_2,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _PermissionList(
              permissions: widget.group.permissions,
              state: widget.state,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bulk action menu ──────────────────────────────────────────────────────────

class _BulkMenu extends StatelessWidget {
  final VoidCallback onGrant;
  final VoidCallback onDeny;
  final VoidCallback onReset;

  const _BulkMenu({
    required this.onGrant,
    required this.onDeny,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_BulkAction>(
      onSelected: (action) => switch (action) {
        _BulkAction.grant => onGrant(),
        _BulkAction.deny => onDeny(),
        _BulkAction.reset => onReset(),
      },
      itemBuilder: (_) => [
        _menuItem(_BulkAction.grant, 'Grant All', IconlyLight.shield_done,
            AppColors.success),
        _menuItem(_BulkAction.deny, 'Deny All', IconlyLight.shield_fail,
            AppColors.error),
        _menuItem(_BulkAction.reset, 'Reset All', IconlyLight.close_square,
            AppColors.textMuted),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bulk',
              style: getOutfitStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(IconlyLight.arrow_down_2,
                size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<_BulkAction> _menuItem(
      _BulkAction action, String label, IconData icon, Color color) {
    return PopupMenuItem(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: getOutfitStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

enum _BulkAction { grant, deny, reset }

// ── Permission list ───────────────────────────────────────────────────────────

class _PermissionList extends StatelessWidget {
  final List<_PermEntry> permissions;
  final EmployeePermissionsLoaded state;

  const _PermissionList({required this.permissions, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(height: 1, color: AppColors.borderSoft),
        for (int i = 0; i < permissions.length; i++) ...[
          _PermissionRow(
            entry: permissions[i],
            effectiveValue: state.effectiveOverride(permissions[i].code),
            isDraft: state.draft.containsKey(permissions[i].code),
          ),
          if (i < permissions.length - 1)
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: AppColors.borderSoft,
            ),
        ],
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Permission row ────────────────────────────────────────────────────────────

class _PermissionRow extends StatelessWidget {
  final _PermEntry entry;
  final bool? effectiveValue;
  final bool isDraft;

  const _PermissionRow({
    required this.entry,
    required this.effectiveValue,
    required this.isDraft,
  });

  Color get _stripColor {
    if (effectiveValue == true) return AppColors.success;
    if (effectiveValue == false) return AppColors.error;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: effectiveValue == true
          ? AppColors.successSoft.withAlpha(60)
          : effectiveValue == false
              ? AppColors.errorSoft.withAlpha(60)
              : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: effectiveValue != null ? _stripColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.label,
                          style: getOutfitStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isDraft) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.description,
                    style:
                        getOutfitStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _StateSelector(
              value: effectiveValue,
              onChanged: (v) =>
                  context.read<EmployeePermissionsCubit>().stageDraft(
                        entry.code,
                        v,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 3-state selector ──────────────────────────────────────────────────────────

class _StateSelector extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?> onChanged;

  const _StateSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StateBtn(
            label: 'Inherited',
            isSelected: value == null,
            selectedColor: AppColors.brand,
            onTap: () => onChanged(null),
            isFirst: true,
          ),
          _VDivider(),
          _StateBtn(
            label: 'Grant',
            isSelected: value == true,
            selectedColor: AppColors.success,
            onTap: () => onChanged(value == true ? null : true),
          ),
          _VDivider(),
          _StateBtn(
            label: 'Deny',
            isSelected: value == false,
            selectedColor: AppColors.error,
            onTap: () => onChanged(value == false ? null : false),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _StateBtn extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _StateBtn({
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: isFirst ? const Radius.circular(7) : Radius.zero,
            bottomLeft: isFirst ? const Radius.circular(7) : Radius.zero,
            topRight: isLast ? const Radius.circular(7) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(7) : Radius.zero,
          ),
        ),
        child: Text(
          label,
          style: getOutfitStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 20, color: AppColors.borderSoft);
}

// ── Sticky save bar ───────────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  final int draftCount;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  const _SaveBar({
    required this.draftCount,
    required this.isSaving,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.borderSoft)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14101828),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$draftCount Unsaved Change${draftCount == 1 ? '' : 's'}',
              style: getOutfitStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: isSaving ? null : onDiscard,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              textStyle: getOutfitStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: const Text('Discard'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: isSaving ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              textStyle: getOutfitStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Changes'),
          ),
        ],
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
            const Icon(IconlyLight.search, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'No permissions found',
              style: getOutfitStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No results for "$query"',
              style: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
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
            const Icon(IconlyLight.danger, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              style: getOutfitStyle(fontSize: 14, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
