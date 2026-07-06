import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/core/widgets/app_view_toggle.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/expenses/domain/repositories/i_expenses_repository.dart';
import 'package:pos/features/expenses/presentation/cubit/expenses_cubit.dart';
import 'package:pos/features/expenses/presentation/cubit/expenses_state.dart';
import 'package:pos/features/expenses/presentation/widgets/add_expense_sheet.dart';
import 'package:pos/features/expenses/presentation/widgets/expense_card_view.dart';
import 'package:pos/features/expenses/presentation/widgets/expense_filter_bar.dart';
import 'package:pos/features/expenses/presentation/widgets/expense_stats_row.dart';
import 'package:pos/features/expenses/presentation/widgets/expense_table_view.dart';

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final initialViewMode = Breakpoints.isPhone(context)
        ? ExpensesViewMode.cards
        : ExpensesViewMode.table;
    return BlocProvider(
      create: (_) => ExpensesCubit(
        sl<IExpensesRepository>(),
        initialViewMode: initialViewMode,
      ),
      child: const _ExpensesView(),
    );
  }
}

class _ExpensesView extends StatefulWidget {
  const _ExpensesView();

  @override
  State<_ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<_ExpensesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startWatching());
  }

  void _startWatching() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final user = authState.user;
    final branchState = context.read<BranchCubit>().state;

    context.read<ExpensesCubit>().startWatching(
      businessId: user.businessId ?? '',
      branchId: branchState.selectedBranchId,
      roleName: branchState.roleName,
      userId: user.id,
      userName: user.fullName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BranchCubit, BranchState>(
      listener: (ctx, s) => _startWatching(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: Breakpoints.isPhone(context)
            ? AppSubPageBar(title: 'Expenses')
            : null,
        floatingActionButton: const _AddFab(),
        body: BlocBuilder<ExpensesCubit, ExpensesState>(
          builder: (context, state) {
            if (state is ExpensesLoading || state is ExpensesInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              );
            }
            if (state is ExpensesError) {
              return _ErrorView(message: state.message);
            }
            if (state is ExpensesLoaded) {
              return _LoadedBody(state: state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _AddFab extends StatelessWidget {
  const _AddFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => showAddExpenseSheet(
        context,
        canApprove: context.read<ExpensesCubit>().canApprove,
      ),
      backgroundColor: AppColors.brand,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        'Add Expense',
        style: getOutfitStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  final ExpensesLoaded state;
  const _LoadedBody({required this.state});

  static const _categories = kExpenseCategories;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExpensesCubit>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        ExpenseStatsRow(
          totalApproved: state.totalApproved,
          totalPending: state.totalPending,
          expenseCount: state.allItems.length,
          pendingCount: state.pendingCount,
        ),
        const SizedBox(height: 16),
        ExpenseFilterBar(
          viewMode: state.viewMode == ExpensesViewMode.table
              ? AppViewMode.table
              : AppViewMode.cards,
          onViewModeChanged: (mode) => cubit.setViewMode(
            mode == AppViewMode.table
                ? ExpensesViewMode.table
                : ExpensesViewMode.cards,
          ),
          onSearchChanged: cubit.setSearchQuery,
          dateRange: state.dateRange,
          onDateRangeChanged: cubit.setDateRange,
          categoryFilter: state.categoryFilter,
          categories: _categories,
          onCategoryChanged: cubit.setCategoryFilter,
          statusFilter: state.statusFilter,
          onStatusChanged: cubit.setStatusFilter,
          pendingCount: state.pendingCount,
        ),
        const SizedBox(height: 12),
        if (state.viewMode == ExpensesViewMode.table)
          ExpenseTableView(
            items: state.displayItems,
            canApprove: state.canApprove,
          )
        else
          ExpenseCardView(
            items: state.displayItems,
            canApprove: state.canApprove,
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(IconlyLight.danger, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              style: getOutfitStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
