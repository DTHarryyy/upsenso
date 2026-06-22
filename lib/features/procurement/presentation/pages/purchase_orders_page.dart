import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';

import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_filled_button.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/widgets/app_empty_state.dart';
import 'package:pos/core/widgets/app_filter_chip.dart';
import 'package:pos/core/widgets/app_search_bar.dart';
import 'package:pos/core/widgets/app_skeleton.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/features/procurement/domain/entities/po_status.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order.dart';
import 'package:pos/features/procurement/presentation/cubit/po_cubit.dart';
import 'package:pos/features/procurement/presentation/cubit/po_state.dart';
import 'package:pos/features/procurement/presentation/widgets/po_list_card.dart';

class PurchaseOrdersPage extends StatelessWidget {
  const PurchaseOrdersPage({super.key});

  bool get _canCreate =>
      sl<PermissionService>().can(PermissionKeys.procurementCreatePo);
  bool get _canManage =>
      sl<PermissionService>().can(PermissionKeys.procurementManage);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PoCubit, PoState>(
      listenWhen: (_, current) => current is PoError,
      listener: (context, state) {
        if (state is PoError) {
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
              : const AppSubPageBar(title: 'Purchase Orders'),
          floatingActionButton: _canCreate
              ? FloatingActionButton(
                  onPressed: () => context.push(AppRoutes.poForm),
                  backgroundColor: AppColors.brand,
                  tooltip: 'New PO',
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                )
              : null,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: AppSearchBar(
                        hint: 'Search by PO number or supplier...',
                        onChanged: (q) => context.read<PoCubit>().search(q),
                      ),
                    ),
                    if (_canManage) ...[
                      const SizedBox(width: 8),
                      _ApprovalSettingsButton(cubit: context.read<PoCubit>()),
                    ],
                  ],
                ),
              ),
              _StatusFilterRow(
                current: state is PoLoaded ? state.statusFilter : null,
                counts: state is PoLoaded ? _statusCounts(state) : const {},
                onChanged: (s) => context.read<PoCubit>().filterByStatus(s),
              ),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        );
      },
    );
  }

  // Counts shown on the filter chips reflect the current search, ignoring the
  // active status filter so each chip always shows how many match it.
  Map<PoStatus?, int> _statusCounts(PoLoaded state) {
    final q = state.searchQuery.toLowerCase().trim();
    final base = q.isEmpty
        ? state.orders
        : state.orders.where((o) {
            return o.poNumber.toLowerCase().contains(q) ||
                (o.supplierName?.toLowerCase().contains(q) ?? false);
          }).toList();
    final counts = <PoStatus?, int>{null: base.length};
    for (final s in PoStatus.values) {
      counts[s] = base.where((o) => o.status == s).length;
    }
    return counts;
  }

  Widget _buildBody(BuildContext context, PoState state) {
    if (state is PoLoading || state is PoInitial) {
      return const AppSkeletonList(itemCount: 6);
    }

    final List<PurchaseOrder> orders;
    if (state is PoLoaded) {
      orders = state.filtered;
    } else if (state is PoActionInProgress) {
      orders = state.orders;
    } else {
      return const SizedBox.shrink();
    }

    if (orders.isEmpty) {
      return AppEmptyState(
        icon: IconlyLight.document,
        title: 'No purchase orders',
        message: _canCreate
            ? 'Create your first PO to start ordering stock from suppliers.'
            : 'Purchase orders will appear here once created.',
        actionLabel: _canCreate ? 'New Purchase Order' : null,
        onAction: _canCreate ? () => context.push(AppRoutes.poForm) : null,
      );
    }

    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: () async => context.read<PoCubit>().watch(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        itemCount: orders.length,
        separatorBuilder: (context, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) => PoListCard(
          po: orders[i],
          onTap: () => context.push(AppRoutes.poDetail, extra: orders[i].id),
        ),
      ),
    );
  }
}

class _StatusFilterRow extends StatelessWidget {
  final PoStatus? current;
  final Map<PoStatus?, int> counts;
  final ValueChanged<PoStatus?> onChanged;

  const _StatusFilterRow({
    required this.current,
    required this.counts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [null, ...PoStatus.values];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: statuses.length,
        separatorBuilder: (context, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = statuses[i];
          return AppFilterChip(
            label: s?.label ?? 'All',
            isSelected: current == s,
            badgeCount: counts[s],
            onTap: () => onChanged(s),
          );
        },
      ),
    );
  }
}

/// Opens the approval-threshold settings dialog. Visible only to users who can
/// manage procurement (see PurchaseOrdersPage._canManage).
class _ApprovalSettingsButton extends StatelessWidget {
  final PoCubit cubit;

  const _ApprovalSettingsButton({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Approval settings',
      icon: const Icon(IconlyLight.setting, color: AppColors.textSecondary),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const _ApprovalThresholdDialog(),
        ),
      ),
    );
  }
}

/// Lets an authorised user set the PO approval threshold: orders above it need a
/// separate approver. Leaving it blank clears the threshold (self-approve any
/// amount).
class _ApprovalThresholdDialog extends StatefulWidget {
  const _ApprovalThresholdDialog();

  @override
  State<_ApprovalThresholdDialog> createState() =>
      _ApprovalThresholdDialogState();
}

class _ApprovalThresholdDialogState extends State<_ApprovalThresholdDialog> {
  final _ctrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final current = await context.read<PoCubit>().loadApprovalThreshold();
    if (!mounted) return;
    setState(() {
      if (current != null) _ctrl.text = current.toStringAsFixed(2);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _ctrl.text.trim();
    final value = raw.isEmpty ? null : double.tryParse(raw);
    if (raw.isNotEmpty && (value == null || value < 0 || !value.isFinite)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount, or leave blank.')),
      );
      return;
    }
    setState(() => _saving = true);
    final ok = await context.read<PoCubit>().setApprovalThreshold(value);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Approval threshold',
        style: getOutfitStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: _loading
          ? const SizedBox(
              height: 64,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Purchase orders above this amount must be approved by someone '
                  'other than the person who created them. Leave blank for no '
                  'limit.',
                  style: getOutfitStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _ctrl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: getOutfitStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    prefixText: '₱ ',
                    hintText: 'No limit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: getOutfitStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(
          width: 120,
          child: AppFilledButton(
            label: 'Save',
            loading: _saving,
            onPressed: _loading || _saving ? null : _save,
          ),
        ),
      ],
    );
  }
}
