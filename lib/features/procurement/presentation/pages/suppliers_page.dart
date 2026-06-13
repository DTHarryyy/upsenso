import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/app_empty_state.dart';
import 'package:pos/core/widgets/app_filter_chip.dart';
import 'package:pos/core/widgets/app_search_bar.dart';
import 'package:pos/core/widgets/app_skeleton.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/features/procurement/domain/entities/supplier.dart';
import 'package:pos/features/procurement/presentation/cubit/supplier_cubit.dart';
import 'package:pos/features/procurement/presentation/cubit/supplier_state.dart';
import 'package:pos/features/procurement/presentation/widgets/supplier_card.dart';
import 'package:pos/features/procurement/presentation/widgets/supplier_form_sheet.dart';

class SuppliersPage extends StatelessWidget {
  const SuppliersPage({super.key});

  bool get _canManage =>
      sl<PermissionService>().can(PermissionKeys.procurementManage);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SupplierCubit, SupplierState>(
      listenWhen: (_, current) => current is SupplierError,
      listener: (context, state) {
        if (state is SupplierError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final loaded = state is SupplierLoaded ? state : null;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppSubPageBar(
            title: 'Suppliers',
            actions: [
              if (loaded != null && loaded.suppliers.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.swap_vert_rounded),
                  tooltip: 'Sort',
                  onPressed: () => _showSortSheet(context, loaded.sort),
                ),
            ],
          ),
          floatingActionButton: _canManage
              ? FloatingActionButton(
                  onPressed: () => _showForm(context),
                  backgroundColor: AppColors.brand,
                  tooltip: 'Add supplier',
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                )
              : null,
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SupplierState state) {
    if (state is SupplierLoading || state is SupplierInitial) {
      return const AppSkeletonList(itemCount: 8);
    }

    final SupplierLoaded loaded;
    if (state is SupplierLoaded) {
      loaded = state;
    } else if (state is SupplierActionInProgress) {
      return const AppSkeletonList(itemCount: 8);
    } else {
      return const SizedBox.shrink();
    }

    // Brand-new business — no suppliers at all.
    if (loaded.suppliers.isEmpty) {
      return AppEmptyState(
        icon: IconlyLight.work,
        title: 'No suppliers yet',
        message: 'Add suppliers to order stock and track purchasing history.',
        actionLabel: _canManage ? 'Add Supplier' : null,
        onAction: _canManage ? () => _showForm(context) : null,
      );
    }

    final items = loaded.items;
    return Column(
      children: [
        _KpiStrip(kpis: loaded.kpis),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: AppSearchBar(
            hint: 'Search name, contact, phone…',
            onChanged: (q) => context.read<SupplierCubit>().search(q),
          ),
        ),
        _FilterRow(
          current: loaded.filter,
          counts: loaded.filterCounts,
          onChanged: (f) => context.read<SupplierCubit>().setFilter(f),
        ),
        Expanded(
          child: items.isEmpty
              ? _NoResults(
                  onClear: () {
                    context.read<SupplierCubit>()
                      ..search('')
                      ..setFilter(SupplierFilter.all);
                  },
                )
              : RefreshIndicator(
                  color: AppColors.brand,
                  onRefresh: () async => context.read<SupplierCubit>().watch(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return SupplierCard(
                        item: item,
                        onTap: () => context.push(
                          AppRoutes.supplierDetail,
                          extra: item.supplier,
                        ),
                        onMenu: () =>
                            _showActions(context, item.supplier),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ── Sheets & dialogs ────────────────────────────────────────────────────────

  void _showForm(BuildContext context, {Supplier? supplier}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<SupplierCubit>(),
        child: SupplierFormSheet(supplier: supplier),
      ),
    );
  }

  void _showSortSheet(BuildContext context, SupplierSort current) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(
        current: current,
        onSelected: (s) {
          context.read<SupplierCubit>().setSort(s);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showActions(BuildContext context, Supplier supplier) {
    final cubit = context.read<SupplierCubit>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _SupplierActionsSheet(
          supplier: supplier,
          canCreatePo:
              sl<PermissionService>().can(PermissionKeys.procurementCreatePo),
          canManage: _canManage,
          onEdit: () {
            Navigator.pop(context);
            _showForm(context, supplier: supplier);
          },
        ),
      ),
    );
  }
}

/// Portfolio summary chips — fills the top of the page with at-a-glance health.
class _KpiStrip extends StatelessWidget {
  final ({int total, int active, double openValue, int reorder}) kpis;

  const _KpiStrip({required this.kpis});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        children: [
          _KpiChip(
            label: 'Suppliers',
            value: '${kpis.total}',
            color: AppColors.brand,
          ),
          _KpiChip(
            label: 'Active',
            value: '${kpis.active}',
            color: AppColors.success,
          ),
          _KpiChip(
            label: 'Open value',
            value: AppFormatters.currency(kpis.openValue),
            color: AppColors.info,
          ),
          _KpiChip(
            label: 'Reorder',
            value: '${kpis.reorder}',
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: getOutfitStyle(
              fontSize: 16,
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

class _FilterRow extends StatelessWidget {
  final SupplierFilter current;
  final Map<SupplierFilter, int> counts;
  final ValueChanged<SupplierFilter> onChanged;

  const _FilterRow({
    required this.current,
    required this.counts,
    required this.onChanged,
  });

  static const _labels = {
    SupplierFilter.all: 'All',
    SupplierFilter.active: 'Active',
    SupplierFilter.inactive: 'Inactive',
    SupplierFilter.recentlyUsed: 'Recently used',
    SupplierFilter.openOrders: 'Open orders',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          for (final f in SupplierFilter.values) ...[
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
              'No suppliers match',
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

class _SortSheet extends StatelessWidget {
  final SupplierSort current;
  final ValueChanged<SupplierSort> onSelected;

  const _SortSheet({required this.current, required this.onSelected});

  static const _labels = {
    SupplierSort.nameAsc: 'Name (A–Z)',
    SupplierSort.recentOrder: 'Recently ordered',
    SupplierSort.spend: 'Highest spend',
    SupplierSort.openValue: 'Open value',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sort by',
                  style: getOutfitStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            for (final s in SupplierSort.values)
              ListTile(
                title: Text(
                  _labels[s]!,
                  style: getOutfitStyle(
                    fontSize: 14,
                    fontWeight: s == current ? FontWeight.w700 : FontWeight.w500,
                    color: s == current
                        ? AppColors.brand
                        : AppColors.textPrimary,
                  ),
                ),
                trailing: s == current
                    ? const Icon(Icons.check, color: AppColors.brand, size: 20)
                    : null,
                onTap: () => onSelected(s),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Quick actions for a supplier — surfaced from the card so the common
/// procurement moves are one tap away without opening the profile.
class _SupplierActionsSheet extends StatelessWidget {
  final Supplier supplier;
  final bool canCreatePo;
  final bool canManage;
  final VoidCallback onEdit;

  const _SupplierActionsSheet({
    required this.supplier,
    required this.canCreatePo,
    required this.canManage,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final phone = supplier.phone;
    final email = supplier.email;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  supplier.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: getOutfitStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (canCreatePo)
              _ActionTile(
                icon: IconlyLight.plus,
                label: 'New purchase order',
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.poForm, extra: supplier);
                },
              ),
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
                label: 'Edit supplier',
                onTap: onEdit,
              ),
            if (canManage)
              _ActionTile(
                icon: IconlyLight.delete,
                label: 'Archive supplier',
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
      debugPrint('[SuppliersPage] Error launching $uri: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open that link.')),
        );
      }
    }
  }

  void _confirmArchive(BuildContext context) {
    final cubit = context.read<SupplierCubit>();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Supplier'),
        content: Text(
          'Archive "${supplier.name}"? It will be hidden from the directory '
          'but kept for historical purchase orders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              cubit.archiveSupplier(supplier.id);
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
