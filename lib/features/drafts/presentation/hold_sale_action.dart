import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/services/cart_service.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/drafts/domain/entities/draft_sale_item.dart';
import 'package:pos/features/drafts/domain/repositories/i_draft_sales_repository.dart';
import 'package:pos/features/drafts/presentation/draft_cart_mapper.dart';

/// Whether the current user may hold (suspend) a sale.
bool canHoldSale() => sl<PermissionService>().can(PermissionKeys.posHoldSale);

/// Saves the shared [CartService] cart as a held sale, then clears the cart.
/// Shared by the POS terminal and the Products cart so both behave identically.
/// No-op on empty cart or when the label prompt is cancelled.
Future<void> holdCurrentCart(BuildContext context) async {
  final cart = sl<CartService>();
  if (cart.isEmpty) return;

  final authState = context.read<AuthBloc>().state;
  if (authState is! AuthAuthenticated) return;

  final label = await _promptHoldLabel(context);
  if (label == null || !context.mounted) return; // cancelled

  final totals = cart.computeTotals();

  final branchId =
      context.read<BranchCubit>().getSelectedBranchIdForFiltering() ??
      authState.user.branchId;
  final id = const Uuid().v4();
  final items = cart.items
      .map(
        (i) => DraftSaleItem(
          variantId: i.variantId,
          productName: i.name,
          variantName: i.variant,
          unitPrice: i.unitPrice,
          taxRate: i.taxRate,
          qty: i.qty,
          lineTotal: i.total,
          lineTax: totals.lineTax(i),
        ),
      )
      .toList();

  try {
    await sl<IDraftSalesRepository>().saveDraft(
      id: id,
      businessId: authState.user.businessId,
      branchId: branchId,
      cashierId: authState.user.id,
      label: label.isEmpty ? null : label,
      subtotal: totals.subtotal,
      taxAmount: totals.tax,
      discountAmount: totals.discountAmount,
      totalAmount: totals.total,
      // Sum exact quantities, not per-line rounded ints — fractional items
      // (e.g. 0.5 kg + 0.5 kg) must not collapse to 0 or double-count.
      itemCount: cart.items.fold(0.0, (s, i) => s + i.qty).round(),
      discountType: DraftCartMapper.discountTypeToString(cart.discountType),
      discountValue: cart.discountValue,
      items: items,
    );
    sl<AuditLogService>().log(
      actionType: AuditLogActionType.draftCreated,
      entityType: 'draft_sale',
      entityId: id,
      description: 'Held sale saved — ${AppFormatters.currency(totals.total)}',
      metadata: {'total': totals.total, 'item_count': items.length},
      businessId: authState.user.businessId,
      branchId: branchId,
      userId: authState.user.id,
    );
    cart.clear();
    if (context.mounted) {
      AppToast.show(context, 'Sale held');
    }
  } catch (e, st) {
    debugPrint('[HoldSale] Error in holdCurrentCart: $e\n$st');
    if (context.mounted) {
      AppToast.show(
        context,
        'Could not hold this sale. Please try again.',
        variant: AppToastVariant.error,
      );
    }
  }
}

/// Returns the entered label (may be empty) or `null` if cancelled.
Future<String?> _promptHoldLabel(BuildContext context) async {
  final controller = TextEditingController();
  try {
    return await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hold Sale'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Label (optional)',
            hintText: 'e.g. Table 5, Mrs. Cruz',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Hold'),
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
  }
}
