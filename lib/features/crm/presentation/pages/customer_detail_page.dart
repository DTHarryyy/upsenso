import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/app_list_section_header.dart';
import 'package:pos/core/widgets/app_modal.dart';
import 'package:pos/core/widgets/app_section_card.dart';
import 'package:pos/core/widgets/app_skeleton.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/core/widgets/stat_card.dart';
import 'package:pos/features/crm/domain/entities/customer.dart';
import 'package:pos/features/crm/domain/entities/customer_purchase.dart';
import 'package:pos/features/crm/presentation/cubit/customer_cubit.dart';
import 'package:pos/features/crm/presentation/cubit/customer_detail_cubit.dart';
import 'package:pos/features/crm/presentation/widgets/customer_contact_card.dart';
import 'package:pos/features/crm/presentation/widgets/customer_form_sheet.dart';
import 'package:pos/features/crm/presentation/widgets/customer_profile_header.dart';
import 'package:pos/features/crm/presentation/widgets/customer_purchase_tile.dart';

class CustomerDetailPage extends StatelessWidget {
  final Customer customer;

  const CustomerDetailPage({super.key, required this.customer});

  bool get _canManage => sl<PermissionService>().can(PermissionKeys.crmManage);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageBar(title: customer.name),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.maxContentWidth(context),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              CustomerProfileHeader(
                customer: customer,
                canManage: _canManage,
                onEdit: () => _showForm(context),
              ),
              const SizedBox(height: 16),
              _StatsSection(),
              const SizedBox(height: 16),
              CustomerContactCard(customer: customer),
              if (customer.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                AppSectionCard(
                  title: 'Notes',
                  icon: IconlyBold.document,
                  children: [
                    Text(
                      customer.notes!,
                      style: getOutfitStyle(
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              _HistorySection(),
            ],
          ),
        ),
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
        final purchases = state is CustomerDetailLoaded
            ? state.purchases
            : const <CustomerPurchase>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppListSectionHeader(
              title: 'Purchase history',
              count: purchases.length,
            ),
            const SizedBox(height: 10),
            _buildBody(state, purchases),
          ],
        );
      },
    );
  }

  Widget _buildBody(
    CustomerDetailState state,
    List<CustomerPurchase> purchases,
  ) {
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
      return _EmptyHistory(icon: IconlyLight.danger, message: state.message);
    }
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
          CustomerPurchaseTile(purchase: p),
          const SizedBox(height: 8),
        ],
      ],
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
