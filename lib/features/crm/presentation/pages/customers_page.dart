import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/widgets/app_bottom_sheet_scaffold.dart';
import 'package:pos/core/widgets/app_empty_state.dart';
import 'package:pos/core/widgets/app_filter_chip.dart';
import 'package:pos/core/widgets/app_modal.dart';
import 'package:pos/core/widgets/app_search_bar.dart';
import 'package:pos/core/widgets/app_skeleton.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/core/widgets/stat_card.dart';
import 'package:pos/features/crm/domain/entities/customer.dart';
import 'package:pos/features/crm/presentation/cubit/customer_cubit.dart';
import 'package:pos/features/crm/presentation/cubit/customer_state.dart';
import 'package:pos/features/crm/presentation/widgets/customer_card.dart';
import 'package:pos/features/crm/presentation/widgets/customer_form_sheet.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  bool get _canManage =>
      sl<PermissionService>().can(PermissionKeys.crmManage);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerCubit, CustomerState>(
      listenWhen: (_, current) => current is CustomerError,
      listener: (context, state) {
        if (state is CustomerError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: Breakpoints.isTablet(context)
              ? null
              : const AppSubPageBar(title: 'Customers'),
          floatingActionButton: _canManage
              ? FloatingActionButton(
                  onPressed: () => _showForm(context),
                  backgroundColor: AppColors.brand,
                  tooltip: 'Add customer',
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                )
              : null,
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CustomerState state) {
    if (state is CustomerLoading || state is CustomerInitial) {
      return const AppSkeletonList(itemCount: 8);
    }

    final CustomerLoaded loaded;
    if (state is CustomerLoaded) {
      loaded = state;
    } else if (state is CustomerActionInProgress) {
      return const AppSkeletonList(itemCount: 8);
    } else {
      return const SizedBox.shrink();
    }

    if (loaded.customers.isEmpty) {
      return AppEmptyState(
        icon: IconlyLight.profile,
        title: 'No customers yet',
        message: 'Add customers to track their purchase history and reach them.',
        actionLabel: _canManage ? 'Add Customer' : null,
        onAction: _canManage ? () => _showForm(context) : null,
      );
    }

    final items = loaded.items;
    return Column(
      children: [
        _KpiStrip(kpis: loaded.kpis),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: AppSearchBar(
            hint: 'Search name, phone, email…',
            onChanged: (q) => context.read<CustomerCubit>().search(q),
          ),
        ),
        _FilterRow(
          current: loaded.filter,
          counts: loaded.filterCounts,
          onChanged: (f) => context.read<CustomerCubit>().setFilter(f),
        ),
        Expanded(
          child: items.isEmpty
              ? _NoResults(
                  onClear: () {
                    context.read<CustomerCubit>()
                      ..search('')
                      ..setFilter(CustomerFilter.all);
                  },
                )
              : _buildResults(context, items),
        ),
      ],
    );
  }

  // Single column on phones, a responsive card grid on wider screens.
  Widget _buildResults(BuildContext context, List<Customer> items) {
    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: () async => context.read<CustomerCubit>().watch(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = _columnsForWidth(constraints.maxWidth);
          if (cols == 1) {
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _customerCard(context, items[i]),
            );
          }
          const gap = 12.0;
          const hPad = 16.0;
          final itemWidth =
              (constraints.maxWidth - hPad * 2 - gap * (cols - 1)) / cols;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(hPad, 12, hPad, 96),
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final item in items)
                  SizedBox(
                    width: itemWidth,
                    child: _customerCard(context, item),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _columnsForWidth(double width) {
    if (width >= 1100) return 4;
    if (width >= 760) return 3;
    if (width >= 540) return 2;
    return 1;
  }

  Widget _customerCard(BuildContext context, Customer customer) {
    return CustomerCard(
      customer: customer,
      onTap: () => context.push(AppRoutes.customerDetail, extra: customer),
      onMenu: () => _showActions(context, customer),
    );
  }

  // ── Sheets & dialogs ────────────────────────────────────────────────────────

  void _showForm(BuildContext context, {Customer? customer}) {
    final cubit = context.read<CustomerCubit>();
    showAppModal<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: CustomerFormSheet(customer: customer),
      ),
    );
  }

  void _showActions(BuildContext context, Customer customer) {
    final cubit = context.read<CustomerCubit>();
    showAppModal<void>(
      context: context,
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: _CustomerActionsSheet(
          customer: customer,
          canManage: _canManage,
          onEdit: () {
            Navigator.pop(sheetContext);
            _showForm(context, customer: customer);
          },
        ),
      ),
    );
  }
}

/// Portfolio summary — reuses the shared [AppStatCard]/[StatCardsRow] so
/// Customers reads the same as Suppliers, Reports, and Dashboard.
class _KpiStrip extends StatelessWidget {
  final ({int total, int active}) kpis;

  const _KpiStrip({required this.kpis});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: StatCardsRow(
        cards: [
          AppStatCard(
            title: 'Customers',
            value: '${kpis.total}',
            icon: IconlyBold.profile,
            iconBg: AppColors.brandSoft,
            iconColor: AppColors.brand,
          ),
          AppStatCard(
            title: 'Active',
            value: '${kpis.active}',
            icon: IconlyBold.tick_square,
            iconBg: AppColors.successSoft,
            iconColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final CustomerFilter current;
  final Map<CustomerFilter, int> counts;
  final ValueChanged<CustomerFilter> onChanged;

  const _FilterRow({
    required this.current,
    required this.counts,
    required this.onChanged,
  });

  static const _labels = {
    CustomerFilter.all: 'All',
    CustomerFilter.active: 'Active',
    CustomerFilter.inactive: 'Inactive',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          for (final f in CustomerFilter.values) ...[
            AppFilterChip(
              label: _labels[f]!,
              isSelected: current == f,
              badgeCount: counts[f],
              onTap: () => onChanged(f),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final VoidCallback onClear;

  const _NoResults({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(IconlyLight.search, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'No customers match',
              style: getOutfitStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search or clear your filters.',
              textAlign: TextAlign.center,
              style: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onClear,
              child: Text(
                'Clear filters',
                style: getOutfitStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick actions for a customer — surfaced from the card so calling, emailing,
/// editing, and archiving are one tap away.
class _CustomerActionsSheet extends StatelessWidget {
  final Customer customer;
  final bool canManage;
  final VoidCallback onEdit;

  const _CustomerActionsSheet({
    required this.customer,
    required this.canManage,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final phone = customer.phone;
    final email = customer.email;

    return AppBottomSheetScaffold(
      title: customer.name,
      child: SingleChildScrollView(
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (phone != null && phone.isNotEmpty)
                _ActionTile(
                  icon: IconlyLight.call,
                  label: 'Call $phone',
                  onTap: () {
                    Navigator.pop(context);
                    _launch(context, 'tel:$phone');
                  },
                ),
              if (email != null && email.isNotEmpty)
                _ActionTile(
                  icon: IconlyLight.message,
                  label: 'Email $email',
                  onTap: () {
                    Navigator.pop(context);
                    _launch(context, 'mailto:$email');
                  },
                ),
              if (canManage)
                _ActionTile(
                  icon: IconlyLight.edit,
                  label: 'Edit customer',
                  onTap: onEdit,
                ),
              if (canManage)
                _ActionTile(
                  icon: IconlyLight.delete,
                  label: 'Archive customer',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmArchive(context);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launch(BuildContext context, String uri) async {
    try {
      final ok = await launchUrl(Uri.parse(uri));
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No app available to handle that.')),
        );
      }
    } catch (e, st) {
      debugPrint('[CustomersPage] Error launching $uri: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open that link.')),
        );
      }
    }
  }

  void _confirmArchive(BuildContext context) {
    final cubit = context.read<CustomerCubit>();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Customer'),
        content: Text(
          'Archive "${customer.name}"? They will be hidden from the directory '
          'but kept for historical sales.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              cubit.archiveCustomer(customer.id);
            },
            child: Text(
              'Archive',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: getOutfitStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: c,
        ),
      ),
      onTap: onTap,
    );
  }
}
