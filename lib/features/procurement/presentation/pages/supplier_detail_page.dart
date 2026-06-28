import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/widgets/app_modal.dart';
import 'package:pos/core/widgets/app_section_card.dart';
import 'package:pos/core/widgets/app_sticky_action_bar.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/core/widgets/stat_card.dart';
import 'package:pos/features/procurement/domain/entities/po_status.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order.dart';
import 'package:pos/features/procurement/domain/entities/supplier.dart';
import 'package:pos/features/procurement/presentation/cubit/po_cubit.dart';
import 'package:pos/features/procurement/presentation/cubit/po_state.dart';
import 'package:pos/features/procurement/presentation/cubit/supplier_cubit.dart';
import 'package:pos/features/procurement/presentation/cubit/supplier_state.dart';
import 'package:pos/features/procurement/presentation/widgets/po_list_card.dart';
import 'package:pos/features/procurement/presentation/widgets/supplier_form_sheet.dart';

/// Strategic supplier profile: stats + purchase history derived from the POs
/// linked by supplierId, plus contact details. The passed [supplier] renders
/// instantly; live edits are reflected from the SupplierCubit stream.
class SupplierDetailPage extends StatelessWidget {
  final Supplier supplier;

  const SupplierDetailPage({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SupplierCubit, SupplierState>(
      builder: (context, state) {
        final current = _resolve(state) ?? supplier;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: Breakpoints.isTablet(context)
              ? null
              : AppSubPageBar(
                  title: current.name,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.mode_edit, size: 20),
                      tooltip: 'Edit',
                      onPressed: () => _edit(context, current),
                    ),
                  ],
                ),
          body: BlocBuilder<PoCubit, PoState>(
            builder: (context, poState) {
              final pos = _supplierPos(poState, current.id);
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Breakpoints.maxContentWidth(context),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _StatsGrid(pos: pos),
                      const SizedBox(height: 16),
                      _ContactCard(supplier: current),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: 'Purchase History',
                        count: pos.length,
                      ),
                      const SizedBox(height: 8),
                      if (pos.isEmpty)
                        _NoHistory()
                      else
                        ...pos.map(
                          (po) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: PoListCard(
                              po: po,
                              onTap: () => context.push(
                                AppRoutes.poDetail,
                                extra: po.id,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          bottomNavigationBar:
              sl<PermissionService>().can(PermissionKeys.procurementCreatePo)
              ? AppStickyActionBar(
                  primary: AppFilledButton(
                    label: 'New PO for ${current.name}',
                    icon: Icons.add,
                    onPressed: () =>
                        context.push(AppRoutes.poForm, extra: current),
                  ),
                )
              : null,
        );
      },
    );
  }

  Supplier? _resolve(SupplierState state) {
    final list = switch (state) {
      SupplierLoaded(:final suppliers) => suppliers,
      SupplierActionInProgress(:final suppliers) => suppliers,
      _ => const <Supplier>[],
    };
    for (final s in list) {
      if (s.id == supplier.id) return s;
    }
    return null;
  }

  // Newest first; cancelled excluded only from stats, not from history.
  List<PurchaseOrder> _supplierPos(PoState state, String supplierId) {
    final orders = switch (state) {
      PoLoaded(:final orders) => orders,
      PoActionInProgress(:final orders) => orders,
      _ => const <PurchaseOrder>[],
    };
    final mine = orders.where((o) => o.supplierId == supplierId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  void _edit(BuildContext context, Supplier supplier) {
    final cubit = context.read<SupplierCubit>();
    showAppModal<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: SupplierFormSheet(supplier: supplier),
      ),
    );
  }
}

/// List section header with an optional count pill — keeps the "Purchase
/// History" heading aligned with the rest of the app's section styling.
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: getOutfitStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: getOutfitStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<PurchaseOrder> pos;

  const _StatsGrid({required this.pos});

  @override
  Widget build(BuildContext context) {
    final orderCount = pos.where((o) => o.status != PoStatus.cancelled).length;
    final spend = pos
        .where((o) => o.status == PoStatus.received)
        .fold<double>(0, (s, o) => s + o.totalAmount);
    final outstanding = pos
        .where((o) => !o.status.isClosed && o.status != PoStatus.cancelled)
        .length;
    final lastOrder = pos.isEmpty
        ? '—'
        : AppFormatters.shortDate(
            pos.map((o) => o.createdAt).reduce((a, b) => a.isAfter(b) ? a : b),
          );

    return StatCardsRow(
      cards: [
        AppStatCard(
          title: 'Total spend',
          value: AppFormatters.currency(spend),
          icon: Icons.analytics,
          iconBg: AppColors.successSoft,
          iconColor: AppColors.success,
        ),
        AppStatCard(
          title: 'Orders',
          value: '$orderCount',
          icon: Icons.shopping_bag,
          iconBg: AppColors.brandSoft,
          iconColor: AppColors.brand,
        ),
        AppStatCard(
          title: 'Outstanding',
          value: '$outstanding',
          icon: Icons.arrow_outward_rounded,
          iconBg: AppColors.infoSoft,
          iconColor: AppColors.info,
        ),
        AppStatCard(
          title: 'Last order',
          value: lastOrder,
          icon: Icons.calendar_month,
          iconBg: AppColors.warningSoft,
          iconColor: AppColors.warning,
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Supplier supplier;

  const _ContactCard({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (supplier.phone != null) _row(Icons.phone, supplier.phone!),
      if (supplier.email != null) _row(Icons.email, supplier.email!),
      if (supplier.address != null) _row(Icons.location_on, supplier.address!),
      if (supplier.notes != null && supplier.notes!.isNotEmpty)
        _row(IconlyLight.document, supplier.notes!),
    ];

    return AppSectionCard(
      title: 'Contact',
      icon: Icons.person,
      children: rows.isEmpty
          ? [
              Text(
                'No contact details yet',
                style: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ]
          : rows,
    );
  }

  Widget _row(IconData icon, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: getOutfitStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      ],
    ),
  );
}

class _NoHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          Icon(IconlyLight.bag, size: 26, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(
            'No orders yet',
            style: getOutfitStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'Purchase orders for this supplier will appear here',
            textAlign: TextAlign.center,
            style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
