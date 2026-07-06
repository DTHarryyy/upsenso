import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/widgets/app_dropdown.dart';
import 'package:pos/core/widgets/app_search_bar.dart';
import 'package:pos/features/business/domain/entities/branch.dart';
import 'package:pos/features/employees/presentation/bloc/employee_bloc.dart';
import 'package:pos/features/employees/presentation/bloc/employee_event.dart';
import 'package:pos/features/employees/presentation/bloc/employee_state.dart';

const _kRoles = [
  'Branch Manager',
  'Cashier',
  'Inventory Staff',
  'Business Owner',
];

String _statusValue(bool? isActive) => switch (isActive) {
  true => 'active',
  false => 'inactive',
  null => '',
};

bool? _statusFromValue(String? value) => switch (value) {
  'active' => true,
  'inactive' => false,
  _ => null,
};

class EmployeeFilterBar extends StatefulWidget {
  final List<Branch> branches;

  const EmployeeFilterBar({super.key, required this.branches});

  @override
  State<EmployeeFilterBar> createState() => _EmployeeFilterBarState();
}

class _EmployeeFilterBarState extends State<EmployeeFilterBar> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  EmployeeLoaded? _resolveLoaded(EmployeeState state) {
    if (state is EmployeeLoaded) return state;
    if (state is EmployeeOperationInProgress) return state.previous;
    if (state is EmployeeOperationSuccess) return state.loaded;
    if (state is EmployeeValidationFailure) return state.loaded;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final showBranchFilter = widget.branches.length >= 2;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSearchBar(
            controller: _searchController,
            hint: 'Search employees…',
            onChanged: (q) =>
                context.read<EmployeeBloc>().add(SearchEmployees(q)),
          ),
          const SizedBox(height: 10),

          // Role / Status / Branch dropdown filters
          BlocBuilder<EmployeeBloc, EmployeeState>(
            buildWhen: (p, c) {
              final pf = _resolveLoaded(p);
              final cf = _resolveLoaded(c);
              return pf?.roleFilter != cf?.roleFilter ||
                  pf?.isActiveFilter != cf?.isActiveFilter ||
                  pf?.branchFilter != cf?.branchFilter;
            },
            builder: (context, state) {
              final loaded = _resolveLoaded(state);
              return Row(
                children: [
                  Expanded(
                    child: AppDropdown<String>(
                      value: loaded?.roleFilter,
                      hint: 'All Roles',
                      dense: true,
                      items: [
                        const AppDropdownItem(value: '', label: 'All Roles'),
                        for (final role in _kRoles)
                          AppDropdownItem(value: role, label: role),
                      ],
                      onChanged: (v) => context.read<EmployeeBloc>().add(
                        SetRoleFilter((v == null || v.isEmpty) ? null : v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppDropdown<String>(
                      value: _statusValue(loaded?.isActiveFilter),
                      hint: 'All Status',
                      dense: true,
                      items: const [
                        AppDropdownItem(value: '', label: 'All Status'),
                        AppDropdownItem(value: 'active', label: 'Active'),
                        AppDropdownItem(value: 'inactive', label: 'Inactive'),
                      ],
                      onChanged: (v) => context.read<EmployeeBloc>().add(
                        SetStatusFilter(_statusFromValue(v)),
                      ),
                    ),
                  ),
                  if (showBranchFilter) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppDropdown<String>(
                        value: loaded?.branchFilter,
                        hint: 'All Branches',
                        dense: true,
                        items: [
                          const AppDropdownItem(
                            value: '',
                            label: 'All Branches',
                          ),
                          for (final branch in widget.branches)
                            AppDropdownItem(
                              value: branch.id,
                              label: branch.name,
                            ),
                        ],
                        onChanged: (v) => context.read<EmployeeBloc>().add(
                          SetBranchFilter((v == null || v.isEmpty) ? null : v),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
