import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/routes/app_routes.dart';
import 'package:pos/core/services/cart_service.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/drafts/domain/entities/draft_sale.dart';
import 'package:pos/features/drafts/domain/entities/draft_sale_item.dart';
import 'package:pos/features/drafts/domain/repositories/i_draft_sales_repository.dart';
import 'package:pos/features/inventory/domain/repositories/i_inventory_repository.dart';
import 'package:pos/features/drafts/presentation/cubit/drafts_cubit.dart';
import 'package:pos/features/drafts/presentation/cubit/drafts_state.dart';
import 'package:pos/features/drafts/presentation/draft_cart_mapper.dart';
import 'package:pos/features/drafts/presentation/widgets/held_sale_detail_sheet.dart';
import 'package:pos/features/products/checkout/product_checkout_page.dart';

/// Lists held / suspended sales and lets the cashier resume or finish them.
class HeldSalesPage extends StatefulWidget {
  const HeldSalesPage({super.key});

  @override
  State<HeldSalesPage> createState() => _HeldSalesPageState();
}

class _HeldSalesPageState extends State<HeldSalesPage> {
  late final DraftsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = DraftsCubit(sl<IDraftSalesRepository>());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cubit.startWatching(
        branchId: context.read<BranchCubit>().state.selectedBranchId,
      );
    });
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<BranchCubit, BranchState>(
        listener: (context, branchState) =>
            _cubit.startWatching(branchId: branchState.selectedBranchId),
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppSubPageBar(title: 'Held Sales'),
          body: BlocBuilder<DraftsCubit, DraftsState>(
            builder: (context, state) => _buildBody(context, state),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DraftsState state) {
    if (state is DraftsInitial || state is DraftsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      );
    }
    if (state is DraftsError) {
      return Center(child: Text(state.message));
    }
    if (state is! DraftsLoaded) return const SizedBox.shrink();
    if (state.drafts.isEmpty) return _buildEmpty();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.drafts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _HeldSaleCard(
        draft: state.drafts[i],
        onTap: () => _openDetail(state.drafts[i]),
        onDiscard: () => _confirmDiscard(state.drafts[i]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(IconlyLight.bag, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'No held sales',
            style: AppTextStyles.subtitle(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Suspended sales you save from the POS appear here.',
            style: AppTextStyles.body(
              context,
            ).copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _openDetail(DraftSale draft) async {
    final repo = sl<IDraftSalesRepository>();
    final items = await repo.getItems(draft.id);
    if (!mounted) return;
    await showHeldSaleDetailSheet(
      context,
      draft: draft,
      items: items,
      onResume: () => _resume(draft),
      onFinish: () => _finish(draft),
    );
  }

  Future<void> _confirmDiscard(DraftSale draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard held sale?'),
        content: Text(
          'This will permanently remove "${draft.label ?? 'Untitled sale'}" '
          '(${draft.itemCount} item${draft.itemCount == 1 ? '' : 's'}).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _cubit.discard(draft.id);
    _auditDiscarded(draft);
    if (mounted) {
      AppToast.show(context, 'Held sale discarded');
    }
  }

  /// Pops the held sale back into the live cart and opens the POS terminal.
  ///
  /// The draft is intentionally left "open" here rather than marked resumed —
  /// it only converts when [ProductCheckoutPage] confirms payment (via the
  /// cart's tracked [CartService.sourceDraftId]). If the cashier abandons the
  /// cart before checking out, the held sale stays in the list instead of
  /// being silently lost.
  Future<void> _resume(DraftSale draft) async {
    final cart = sl<CartService>();
    // Resuming replaces the live cart — warn if it would discard current items.
    if (cart.isNotEmpty) {
      final replace = await _confirmReplaceCart(cart.itemCount);
      if (replace != true || !mounted) return;
    }
    final repo = sl<IDraftSalesRepository>();
    final items = await repo.getItems(draft.id);
    cart.loadFrom(
      DraftCartMapper.toCartItems(items),
      discountType: DraftCartMapper.discountTypeFrom(draft.discountType),
      discountValue: draft.discountValue ?? 0,
      sourceDraftId: draft.id,
    );
    _auditResumed(draft);
    if (!mounted) return;
    final router = GoRouter.of(context);
    Navigator.of(context, rootNavigator: true).pop(); // close held sales page
    router.go(AppRoutes.posTerminal);
  }

  Future<bool?> _confirmReplaceCart(int currentCount) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace current cart?'),
        content: Text(
          'Your current cart has $currentCount '
          '${currentCount == 1 ? 'item' : 'items'} that will be cleared when '
          'you resume this held sale.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  /// Pushes checkout directly; conversion happens via [sourceDraftId].
  /// Re-validates stock first — a parked sale can sell out while held.
  Future<void> _finish(DraftSale draft) async {
    final items = await sl<IDraftSalesRepository>().getItems(draft.id);
    final shortages = await sl<IInventoryRepository>().checkStockAvailability(
      items: items
          .map((i) => (variantId: i.variantId, qty: i.qty))
          .toList(),
      branchId: draft.branchId,
    );
    if (!mounted) return;
    if (shortages.isNotEmpty) {
      final proceed = await _confirmStockShortage(items, shortages);
      if (proceed != true || !mounted) return;
    }
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ProductCheckoutPage(
          items: DraftCartMapper.toCartItems(items),
          subtotal: draft.subtotal,
          tax: draft.taxAmount,
          total: draft.totalAmount,
          discountAmount: draft.discountAmount,
          sourceDraftId: draft.id,
          onPaymentConfirmed: () {},
        ),
      ),
    );
  }

  Future<bool?> _confirmStockShortage(
    List<DraftSaleItem> items,
    List<({String variantId, double available, double requested})> shortages,
  ) {
    final nameFor = {for (final i in items) i.variantId: i.productName};
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stock may be short'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Some items have less stock than this held sale needs:',
              style: getOutfitStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            ...shortages.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${nameFor[s.variantId] ?? 'Item'} — need '
                  '${AppFormatters.quantity(s.requested)}, '
                  '${AppFormatters.quantity(s.available)} in stock',
                  style: getOutfitStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _auditResumed(DraftSale draft) {
    sl<AuditLogService>().log(
      actionType: AuditLogActionType.draftResumed,
      entityType: 'draft_sale',
      entityId: draft.id,
      description: 'Held sale resumed — ${draft.itemCount} item(s)',
      metadata: {'total': draft.totalAmount, 'item_count': draft.itemCount},
    );
  }

  void _auditDiscarded(DraftSale draft) {
    sl<AuditLogService>().log(
      actionType: AuditLogActionType.draftDiscarded,
      entityType: 'draft_sale',
      entityId: draft.id,
      description: 'Held sale discarded — ${draft.itemCount} item(s)',
      metadata: {'total': draft.totalAmount, 'item_count': draft.itemCount},
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _HeldSaleCard extends StatelessWidget {
  final DraftSale draft;
  final VoidCallback onTap;
  final VoidCallback onDiscard;

  const _HeldSaleCard({
    required this.draft,
    required this.onTap,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(draft.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDiscard();
        return false; // discard handled via confirm dialog upstream
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(IconlyLight.delete, color: Colors.white, size: 22),
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    IconlyLight.bag,
                    size: 20,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.label?.trim().isNotEmpty == true
                            ? draft.label!
                            : (draft.customerName?.trim().isNotEmpty == true
                                  ? draft.customerName!
                                  : 'Untitled sale'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: getOutfitStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${draft.itemCount} item${draft.itemCount == 1 ? '' : 's'} · '
                        '${AppFormatters.shortDate(draft.updatedAt)} '
                        '${AppFormatters.time12h(draft.updatedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: getOutfitStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppFormatters.currency(draft.totalAmount),
                  style: getOutfitStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
