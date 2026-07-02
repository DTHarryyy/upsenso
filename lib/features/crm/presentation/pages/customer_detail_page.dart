import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/app_modal.dart';
import 'package:pos/core/widgets/app_skeleton.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/core/widgets/stat_card.dart';
import 'package:pos/features/crm/domain/entities/customer.dart';
import 'package:pos/features/crm/domain/entities/customer_purchase.dart';
import 'package:pos/features/crm/presentation/cubit/customer_cubit.dart';
import 'package:pos/features/crm/presentation/cubit/customer_detail_cubit.dart';
import 'package:pos/features/crm/presentation/widgets/customer_form_sheet.dart';

class CustomerDetailPage extends StatelessWidget {
  final Customer customer;

  const CustomerDetailPage({super.key, required this.customer});

  bool get _canManage => sl<PermissionService>().can(PermissionKeys.crmManage);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageBar(
        title: customer.name,
        actions: _canManage
            ? [
                IconButton(
                  icon: const Icon(IconlyLight.edit, size: 20),
                  tooltip: 'Edit customer',
                  onPressed: () => _showForm(context),
                ),
              ]
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _ProfileCard(customer: customer),
          const SizedBox(height: 16),
          _StatsSection(),
          const SizedBox(height: 20),
          Text(
            'Purchase history',
            style: getOutfitStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _HistorySection(),
        ],
      ),
    );
  }

  void _showForm(BuildContext context) {
    final cubit = context.read<CustomerCubit>();
    showAppModal<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: CustomerFormSheet(customer: customer),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Customer customer;

  const _ProfileCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final c = customer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                    style: getOutfitStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  c.name,
                  style: getOutfitStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (_hasContact) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.borderSoft),
            const SizedBox(height: 12),
            if (c.phone?.isNotEmpty == true)
              _ContactRow(icon: IconlyLight.call, value: c.phone!),
            if (c.email?.isNotEmpty == true)
              _ContactRow(icon: IconlyLight.message, value: c.email!),
            if (c.address?.isNotEmpty == true)
              _ContactRow(icon: IconlyLight.location, value: c.address!),
            if (c.notes?.isNotEmpty == true)
              _ContactRow(icon: IconlyLight.document, value: c.notes!),
          ],
        ],
      ),
    );
  }

  bool get _hasContact =>
      customer.phone?.isNotEmpty == true ||
      customer.email?.isNotEmpty == true ||
      customer.address?.isNotEmpty == true ||
      customer.notes?.isNotEmpty == true;
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ContactRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: getOutfitStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerDetailCubit, CustomerDetailState>(
      builder: (context, state) {
        final stats = state is CustomerDetailLoaded
            ? state.stats
            : const CustomerStats();
        return StatCardsRow(
          cards: [
            AppStatCard(
              title: 'Orders',
              value: '${stats.orderCount}',
              icon: IconlyBold.bag,
              iconBg: AppColors.brandSoft,
              iconColor: AppColors.brand,
            ),
            AppStatCard(
              title: 'Total spent',
              value: AppFormatters.currency(stats.totalSpent),
              icon: IconlyBold.wallet,
              iconBg: AppColors.successSoft,
              iconColor: AppColors.success,
            ),
            AppStatCard(
              title: 'Avg order',
              value: AppFormatters.currency(stats.averageOrderValue),
              icon: IconlyBold.chart,
              iconBg: AppColors.infoSoft,
              iconColor: AppColors.info,
            ),
          ],
        );
      },
    );
  }
}

class _HistorySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerDetailCubit, CustomerDetailState>(
      builder: (context, state) {
        if (state is CustomerDetailLoading) {
          // Column (not AppSkeletonList) — this section already lives inside the
          // page's scrolling ListView, so no nested scrollable.
          return const Column(
            children: [
              AppSkeleton(height: 64, radius: 14),
              SizedBox(height: 8),
              AppSkeleton(height: 64, radius: 14),
              SizedBox(height: 8),
              AppSkeleton(height: 64, radius: 14),
            ],
          );
        }
        if (state is CustomerDetailError) {
          return _EmptyHistory(
            icon: IconlyLight.danger,
            message: state.message,
          );
        }
        final purchases =
            state is CustomerDetailLoaded ? state.purchases : const [];
        if (purchases.isEmpty) {
          return const _EmptyHistory(
            icon: IconlyLight.bag,
            message: 'No purchases yet. Sales attributed to this customer will '
                'show up here.',
          );
        }
        return Column(
          children: [
            for (final p in purchases) ...[
              _PurchaseTile(purchase: p),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  final CustomerPurchase purchase;

  const _PurchaseTile({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final p = purchase;
    final label = p.invoiceNumber?.isNotEmpty == true
        ? p.invoiceNumber!
        : 'Sale';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: getOutfitStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${AppFormatters.relativeDate(p.createdAt)} · '
                  '${p.itemCount} ${p.itemCount == 1 ? 'item' : 'items'} · '
                  '${p.paymentMethod}',
                  style: getOutfitStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            AppFormatters.currency(p.totalAmount),
            style: getOutfitStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyHistory({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: getOutfitStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
