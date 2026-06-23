import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:pos/core/widgets/app_progress_bar.dart';
import 'package:pos/core/widgets/app_section_card.dart';
import 'package:pos/core/widgets/app_sticky_action_bar.dart';
import 'package:pos/core/widgets/app_sub_page_bar.dart';
import 'package:pos/features/procurement/domain/entities/goods_receipt.dart';
import 'package:pos/features/procurement/domain/entities/po_input.dart';
import 'package:pos/features/procurement/domain/entities/po_status.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order_line.dart';
import 'package:pos/features/procurement/domain/repositories/i_procurement_repository.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/features/procurement/presentation/cubit/po_cubit.dart';
import 'package:pos/features/procurement/presentation/cubit/po_state.dart';
import 'package:pos/features/procurement/presentation/widgets/po_status_badge.dart';
import 'package:pos/features/procurement/presentation/widgets/po_timeline.dart';

// Shared surface treatment so the header, receiving and section cards on this
// page match AppSectionCard's rounded-with-soft-shadow look.
final BoxDecoration _cardDecoration = BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: AppColors.borderSoft),
  boxShadow: const [
    BoxShadow(color: Color(0x07101828), blurRadius: 20, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x04101828), blurRadius: 6, offset: Offset(0, 1)),
  ],
);

class PoDetailPage extends StatelessWidget {
  final String poId;

  const PoDetailPage({super.key, required this.poId});

  @override
  Widget build(BuildContext context) {
    final repo = sl<IProcurementRepository>();

    return StreamBuilder<PurchaseOrder?>(
      stream: repo
          .watchPurchaseOrders(_businessId(context))
          .map((orders) => orders.firstWhereOrNull((o) => o.id == poId)),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: Breakpoints.isTablet(context)
              ? null
              : const AppSubPageBar(title: 'Purchase Order'),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            ),
          );
        }
        return _PoDetailContent(po: snapshot.data!);
      },
    );
  }

  String _businessId(BuildContext context) {
    final cubit = context.read<PoCubit>();
    return cubit.businessId;
  }
}

class _PoDetailContent extends StatelessWidget {
  final PurchaseOrder po;

  const _PoDetailContent({required this.po});

  @override
  Widget build(BuildContext context) {
    final repo = sl<IProcurementRepository>();
    final perms = sl<PermissionService>();

    // Lines are streamed once here and shared by the header progress, the line
    // list and the receive action — the PO itself arrives line-less from the
    // list stream, so this is the single source of line data on this page.
    return StreamBuilder<List<PurchaseOrderLine>>(
      stream: repo.watchPurchaseOrderLines(po.id),
      builder: (context, snap) {
        final lines = snap.data ?? const <PurchaseOrderLine>[];
        return BlocListener<PoCubit, PoState>(
          listenWhen: (_, s) => s is PoError,
          listener: (_, s) {
            if (s is PoError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.message)),
              );
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: Breakpoints.isTablet(context)
                ? null
                : AppSubPageBar(
                    title: po.poNumber,
                    actions: [
                      if (po.status == PoStatus.draft &&
                          perms.can(PermissionKeys.procurementCreatePo))
                        IconButton(
                          icon: const Icon(IconlyLight.edit),
                          tooltip: 'Edit',
                          onPressed: () =>
                              context.push(AppRoutes.poForm, extra: po),
                        ),
                    ],
                  ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _HeaderCard(po: po),
                if (_showsReceiving(po.status)) ...[
                  const SizedBox(height: 12),
                  _ReceivingProgressCard(lines: lines),
                ],
                const SizedBox(height: 12),
                AppSectionCard(
                  title: 'Products',
                  icon: IconlyLight.bag,
                  trailing: lines.isEmpty
                      ? null
                      : Text(
                          lines.length == 1 ? '1 item' : '${lines.length} items',
                          style: getOutfitStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                  children: [
                    if (lines.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'No lines',
                            style: getOutfitStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      )
                    else
                      ...lines.map(
                        (l) => _LineCard(
                          line: l,
                          showReceiving: _showsReceiving(po.status),
                        ),
                      ),
                  ],
                ),
                if (_showsReceiving(po.status)) ...[
                  const SizedBox(height: 12),
                  _ReceiptsSection(poId: po.id),
                ],
                const SizedBox(height: 12),
                AppSectionCard(
                  title: 'Timeline',
                  icon: IconlyLight.time_circle,
                  children: [PoTimeline(po: po)],
                ),
              ],
            ),
            bottomNavigationBar: _ActionBar(po: po, lines: lines),
          ),
        );
      },
    );
  }

  // Receiving progress is only meaningful once a PO can receive goods.
  bool _showsReceiving(PoStatus status) =>
      status == PoStatus.approved ||
      status == PoStatus.partiallyReceived ||
      status == PoStatus.received;
}

/// Header-level receiving meter: total received units over total ordered.
class _ReceivingProgressCard extends StatelessWidget {
  final List<PurchaseOrderLine> lines;

  const _ReceivingProgressCard({required this.lines});

  @override
  Widget build(BuildContext context) {
    final ordered = lines.fold<double>(0, (s, l) => s + l.quantityOrdered);
    final received = lines.fold<double>(0, (s, l) => s + l.quantityReceived);
    final fraction = ordered <= 0 ? 0.0 : received / ordered;
    final done = ordered > 0 && received >= ordered;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration,
      child: AppProgressBar(
        value: fraction,
        color: done ? AppColors.success : AppColors.brand,
        height: 8,
        label: 'Received',
        trailing:
            '${AppFormatters.quantity(received)} / ${AppFormatters.quantity(ordered)}'
            '  (${(fraction * 100).round()}%)',
      ),
    );
  }
}

/// Goods-receipt (GRN) history for the PO — one row per receiving event.
class _ReceiptsSection extends StatelessWidget {
  final String poId;

  const _ReceiptsSection({required this.poId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GoodsReceipt>>(
      stream: sl<IProcurementRepository>().watchReceipts(poId),
      builder: (context, snap) {
        final receipts = snap.data ?? const <GoodsReceipt>[];
        if (receipts.isEmpty) return const SizedBox.shrink();
        return AppSectionCard(
          title: 'Receipts',
          icon: Icons.inventory_2_outlined,
          trailing: Text(
            receipts.length == 1 ? '1 receipt' : '${receipts.length} receipts',
            style: getOutfitStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          children: [
            for (final r in receipts)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.receiptNumber,
                            style: getOutfitStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (r.receivedByName != null)
                            Text(
                              'by ${r.receivedByName}',
                              style: getOutfitStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      AppFormatters.shortDate(r.receivedAt),
                      style: getOutfitStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final PurchaseOrder po;

  const _HeaderCard({required this.po});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.brand.withAlpha(18),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.storefront_outlined,
                        size: 17,
                        color: AppColors.brand,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            po.supplierName ?? 'No supplier',
                            style: getOutfitStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            po.poNumber,
                            style: getOutfitStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    PoStatusBadge(status: po.status),
                  ],
                ),
                const SizedBox(height: 14),
                _row('Created', AppFormatters.shortDate(po.createdAt)),
                if (po.expectedDelivery != null)
                  _row(
                    'Expected',
                    AppFormatters.shortDate(po.expectedDelivery!),
                  ),
                if (po.approvedByName != null)
                  _row('Approved by', po.approvedByName!),
                if (po.notes != null && po.notes!.isNotEmpty)
                  _row('Notes', po.notes!),
              ],
            ),
          ),
          // Emphasised total band with the landed-cost breakdown when present.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.brand.withAlpha(12),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
            ),
            child: Column(
              children: [
                if (po.discount > 0 || po.shipping > 0) ...[
                  _amountLine('Subtotal',
                      po.totalAmount + po.discount - po.shipping),
                  if (po.discount > 0)
                    _amountLine('Discount', -po.discount),
                  if (po.shipping > 0) _amountLine('Shipping', po.shipping),
                  const SizedBox(height: 6),
                ],
                Row(
                  children: [
                    Text(
                      'Total',
                      style: getOutfitStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AppFormatters.currency(po.totalAmount),
                      style: getOutfitStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: getOutfitStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );

  // A subtotal/discount/shipping line in the total band.
  Widget _amountLine(String label, double amount) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Text(
          label,
          style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const Spacer(),
        Text(
          AppFormatters.currency(amount),
          style: getOutfitStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

class _LineCard extends StatelessWidget {
  final PurchaseOrderLine line;

  /// Whether the PO can receive goods — only then is the per-line received
  /// progress meaningful, so the bar is hidden for draft/pending orders.
  final bool showReceiving;

  const _LineCard({required this.line, required this.showReceiving});

  @override
  Widget build(BuildContext context) {
    final ordered = line.quantityOrdered;
    final fraction = ordered <= 0 ? 0.0 : line.quantityReceived / ordered;
    final done = line.isFullyReceived;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.productName,
                      style: getOutfitStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (line.sku != null)
                      Text(
                        line.sku!,
                        style: getOutfitStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppFormatters.currency(line.totalCost),
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${AppFormatters.quantity(ordered)} × ${AppFormatters.currency(line.unitCost)}',
            style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          if (showReceiving) ...[
            const SizedBox(height: 8),
            AppProgressBar(
              value: fraction,
              color: done ? AppColors.success : AppColors.brand,
              height: 6,
              trailing:
                  '${AppFormatters.quantity(line.quantityReceived)} / ${AppFormatters.quantity(ordered)} received',
            ),
          ],
        ],
      ),
    );
  }
}

/// Sticky bottom action bar — surfaces the one status-appropriate primary
/// action (submit/approve/receive) plus an optional destructive cancel, so the
/// next step is always reachable without scrolling past every line.
class _ActionBar extends StatelessWidget {
  final PurchaseOrder po;
  final List<PurchaseOrderLine> lines;

  const _ActionBar({required this.po, required this.lines});

  @override
  Widget build(BuildContext context) {
    final perms = sl<PermissionService>();
    final cubit = context.read<PoCubit>();
    final status = po.status;

    final canApprove = perms.can(PermissionKeys.procurementApprovePo);
    final canCreate = perms.can(PermissionKeys.procurementCreatePo);
    final canReceive = perms.can(PermissionKeys.procurementReceive);

    Widget? primary;
    if (status == PoStatus.draft) {
      // Streamlined approval: an approver approves the draft directly instead of
      // self-submitting; a creator-only user routes it on for approval.
      if (canApprove) {
        primary = AppFilledButton(
          label: 'Approve',
          onPressed: () => _approve(context, cubit),
        );
      } else if (canCreate) {
        primary = AppFilledButton(
          label: 'Submit for Approval',
          onPressed: () => _submit(context, cubit),
        );
      }
    } else if (status == PoStatus.submitted && canApprove) {
      primary = AppFilledButton(
        label: 'Approve',
        onPressed: () => _approve(context, cubit),
      );
    } else if (status.canReceive && canReceive) {
      primary = AppFilledButton(
        label: 'Receive Goods',
        onPressed: () => _showReceiveSheet(context, cubit),
      );
    }

    // Secondary destructive action: cancel while still cancellable, else
    // short-close once goods have started arriving (partially received).
    final canManage = perms.can(PermissionKeys.procurementManage);
    final Widget? secondary = status.canCancel && canManage
        ? _cancelButton(context, cubit)
        : (status.canClose && canManage ? _closeButton(context, cubit) : null);

    if (primary == null && secondary == null) return const SizedBox.shrink();

    return AppStickyActionBar(
      primary: primary ?? secondary!,
      secondary: primary != null ? secondary : null,
    );
  }

  Widget _cancelButton(BuildContext context, PoCubit cubit) => OutlinedButton(
    onPressed: () => _cancel(context, cubit),
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppColors.error),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: Text(
      'Cancel PO',
      style: getOutfitStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.error,
      ),
    ),
  );

  Future<void> _submit(BuildContext context, PoCubit cubit) async {
    final confirm = await _confirmDialog(
      context,
      'Submit PO',
      'Submit ${po.poNumber} for approval?',
    );
    if (!confirm) return;
    await cubit.submitPurchaseOrder(po.id);
  }

  Future<void> _approve(BuildContext context, PoCubit cubit) async {
    final confirm = await _confirmDialog(
      context,
      'Approve PO',
      'Approve ${po.poNumber}? This allows goods to be received.',
    );
    if (!confirm) return;
    // A draft must be submitted before it can be approved (approve only accepts
    // a submitted PO); chain them so a one-tap approve from a draft works.
    if (po.status == PoStatus.draft) {
      await cubit.submitPurchaseOrder(po.id);
    }
    await cubit.approvePurchaseOrder(po.id);
  }

  Future<void> _cancel(BuildContext context, PoCubit cubit) async {
    final confirm = await _confirmDialog(
      context,
      'Cancel PO',
      'Cancel ${po.poNumber}? This cannot be undone.',
      destructive: true,
    );
    if (!confirm) return;
    await cubit.cancelPurchaseOrder(po.id);
    if (context.mounted) context.pop();
  }

  Widget _closeButton(BuildContext context, PoCubit cubit) => OutlinedButton(
    onPressed: () => _close(context, cubit),
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppColors.textSecondary),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: Text(
      'Close (short)',
      style: getOutfitStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    ),
  );

  Future<void> _close(BuildContext context, PoCubit cubit) async {
    final confirm = await _confirmDialog(
      context,
      'Close PO',
      'Close ${po.poNumber} with outstanding quantity? Remaining items will '
          'not be received.',
      destructive: true,
    );
    if (!confirm) return;
    await cubit.closePurchaseOrder(po.id);
    if (context.mounted) context.pop();
  }

  void _showReceiveSheet(BuildContext context, PoCubit cubit) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _ReceiveGoodsDialog(po: po, lines: lines),
      ),
    );
  }

  Future<bool> _confirmDialog(
    BuildContext context,
    String title,
    String message, {
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Confirm',
              style: TextStyle(
                color: destructive
                    ? Theme.of(context).colorScheme.error
                    : AppColors.brand,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// Dialog for receiving goods against a PO.
/// Shows each open line with a qty input; user enters received quantities.
class _ReceiveGoodsDialog extends StatefulWidget {
  final PurchaseOrder po;
  final List<PurchaseOrderLine> lines;

  const _ReceiveGoodsDialog({required this.po, required this.lines});

  @override
  State<_ReceiveGoodsDialog> createState() => _ReceiveGoodsDialogState();
}

class _ReceiveGoodsDialogState extends State<_ReceiveGoodsDialog> {
  late List<_ReceiveLine> _entries;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _entries = widget.lines
        .where((l) => !l.isFullyReceived)
        .map(
          (l) => _ReceiveLine(
            line: l,
            qtyCtrl: TextEditingController(
              text: AppFormatters.quantity(l.remainingQty),
            ),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.qtyCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _receive() async {
    final inputs = <ReceiveLineInput>[];
    for (final e in _entries) {
      final qty = double.tryParse(e.qtyCtrl.text) ?? 0;
      if (qty <= 0) continue;
      inputs.add(
        ReceiveLineInput(
          lineId: e.line.id,
          variantId: e.line.variantId,
          productId: e.line.productId,
          quantityToReceive: qty,
          unitCost: e.line.unitCost,
        ),
      );
    }
    if (inputs.isEmpty) {
      Navigator.pop(context);
      return;
    }

    // Stock must land in a real branch — prefer the PO's own branch, fall back to
    // the currently-selected branch. If neither resolves, stop with a clear
    // message rather than creating orphan inventory under an empty branch id.
    final branchId = (widget.po.branchId?.trim().isNotEmpty ?? false)
        ? widget.po.branchId!
        : context.read<BranchCubit>().state.selectedBranchId;
    if (branchId == null || branchId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a branch before receiving goods.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final cubit = context.read<PoCubit>();
      await cubit.receiveGoods(
        poId: widget.po.id,
        branchId: branchId,
        lines: inputs,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.brand.withAlpha(20),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      size: 19,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receive Goods',
                          style: getOutfitStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.po.poNumber,
                          style: getOutfitStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSoft),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                shrinkWrap: true,
                itemCount: _entries.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                final e = _entries[i];
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.line.productName,
                            style: getOutfitStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Remaining: ${AppFormatters.quantity(e.line.remainingQty)}',
                            style: getOutfitStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 90,
                      child: TextFormField(
                        controller: e.qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        textAlign: TextAlign.center,
                        style: getOutfitStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Qty',
                          labelStyle: getOutfitStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.borderSoft,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.borderSoft,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.brand,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
                },
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSoft),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: AppFilledButton(
                label: 'Confirm Receipt',
                loading: _saving,
                onPressed: _saving ? null : _receive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiveLine {
  final PurchaseOrderLine line;
  final TextEditingController qtyCtrl;

  _ReceiveLine({required this.line, required this.qtyCtrl});
}
