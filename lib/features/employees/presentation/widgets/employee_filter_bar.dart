import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_dropdown.dart';
import 'package:pos/core/widgets/app_search_bar.dart';
import 'package:pos/features/employees/domain/entities/employee.dart';
import 'package:pos/features/employees/presentation/bloc/employee_bloc.dart';
import 'package:pos/features/employees/presentation/bloc/employee_event.dart';
import 'package:pos/features/employees/presentation/bloc/employee_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmployeeFilterBar extends StatelessWidget {
  const EmployeeFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeeBloc, EmployeeState>(
      buildWhen: (p, c) =>
          c is EmployeeLoaded &&
          (p is! EmployeeLoaded ||
              p.roleFilter != c.roleFilter ||
              p.statusFilter != c.statusFilter ||
              p.searchQuery != c.searchQuery),
      builder: (context, state) {
        final loaded = state is EmployeeLoaded ? state : null;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              AppSearchBar(
                hint: 'Search by name, email or code…',
                onChanged: (q) =>
                    context.read<EmployeeBloc>().add(SearchEmployees(q)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AppDropdown<EmployeeRole?>(
                      value: loaded?.roleFilter,
                      hint: 'All Roles',
                      items: [
                        const AppDropdownItem(value: null, label: 'All Roles'),
                        ...EmployeeRole.values.map(
                          (r) => AppDropdownItem(
                            value: r,
                            label: r.displayName,
                          ),
                        ),
                      ],
                      onChanged: (role) {
                        context.read<EmployeeBloc>().add(
                          FilterEmployees(
                            roleFilter: role,
                            statusFilter: loaded?.statusFilter,
                            branchFilter: loaded?.branchFilter,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppDropdown<EmployeeStatus?>(
                      value: loaded?.statusFilter,
                      hint: 'All Status',
                      items: [
                        const AppDropdownItem(
                          value: null,
                          label: 'All Status',
                        ),
                        ...EmployeeStatus.values.map(
                          (s) => AppDropdownItem(
                            value: s,
                            label: s.displayName,
                          ),
                        ),
                      ],
                      onChanged: (status) {
                        context.read<EmployeeBloc>().add(
                          FilterEmployees(
                            roleFilter: loaded?.roleFilter,
                            statusFilter: status,
                            branchFilter: loaded?.branchFilter,
                          ),
                        );
                      },
                    ),
                  ),
                  if (loaded?.hasActiveFilters == true) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => context
                          .read<EmployeeBloc>()
                          .add(const ClearEmployeeFilters()),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.brand,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        'Clear',
                        style: getOutfitStyle(
                          fontSize: 13,
                          color: AppColors.brand,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
