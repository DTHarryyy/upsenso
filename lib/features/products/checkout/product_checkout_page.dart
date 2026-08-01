import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/errors/app_error_mapper.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/permissions/entitlement_enforcement_service.dart';
import 'package:pos/core/services/checkout_service.dart';
import 'package:pos/core/widgets/upgrade_prompt.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/crm/presentation/widgets/customer_inline_picker.dart';
import 'package:pos/features/crm/presentation/widgets/customer_selection.dart';
import 'package:pos/features/drafts/domain/repositories/i_draft_sales_repository.dart';
import 'package:pos/features/pos/presentation/pages/checkout_success_page.dart';
import 'package:pos/features/pos/presentation/widgets/denom_chip.dart';
import 'package:pos/features/products/checkout/product_cart_page.dart';

class ProductCheckoutPage extends StatefulWidget {
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final double discountAmount;
  final VoidCallback onPaymentConfirmed;

  /// When set, this checkout is finishing a held / suspended sale. On success
  /// the draft is marked converted and soft-deleted.
  final String? sourceDraftId;

  const ProductCheckoutPage({
    super.key,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.discountAmount = 0,
    required this.onPaymentConfirmed,
    this.sourceDraftId,
  });

  @override
  State<ProductCheckoutPage> createState() => _ProductCheckoutPageState();
}

class _ProductCheckoutPageState extends State<ProductCheckoutPage> {
  final _amountController = TextEditingController();

  // null = walk-in. Set via the customer picker — may be a saved customer, an
  // ad-hoc name, or an explicit walk-in.
  CustomerSelection? _customer;
  String _paymentMethod = 'cash';
  double _amountReceived = 0;
  bool _confirming = false;
  bool _summaryExpanded = false;

  static const _denoms = [
    1.0,
    5.0,
    10.0,
    20.0,
    50.0,
    100.0,
    200.0,
    500.0,
    1000.0,
  ];

  static final _methods = [
    ('cash', 'Cash', IconlyLight.wallet),
    ('card', 'Card', IconlyLight.buy),
    ('gcash', 'GCash', IconlyLight.call),
    ('maya', 'Maya', IconlyLight.wallet),
  ];

  bool get _isCash => _paymentMethod == 'cash';
  double get _change => _amountReceived - widget.total;
  bool get _canConfirm => !_isCash || (_amountReceived > 0 && _change >= 0);

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String? get _businessId {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.user.businessId : null;
  }

  void _addDenom(double denom) {
    setState(() {
      _amountReceived += denom;
      _amountController.text = _amountReceived.toStringAsFixed(2);
    });
  }

  void _setExact() {
    setState(() {
      _amountReceived = widget.total;
      _amountController.text = widget.total.toStringAsFixed(2);
    });
  }

  Future<void> _confirm() async {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final branchCubit = context.read<BranchCubit>();
    String? branchId =
        branchCubit.getSelectedBranchIdForFiltering() ??
        authState.user.branchId;

    // When no branch is resolved, prompt the cashier to pick one.
    if (branchId == null) {
      if (branchCubit.state.canSwitchBranches) {
        final selection = await showBranchSaleDialog(context);
        if (selection == null || !mounted) return;
        branchId = selection.id;
      } else {
        if (mounted) {
          AppToast.show(
            context,
            'No branch assigned. Please contact your administrator.',
            variant: AppToastVariant.error,
          );
        }
        return;
      }
    }

    // A missing businessId here means the session lost its tenant context —
    // letting it fall through as '' would write the invoice/stock-ledger
    // rows under a fake tenant instead of the real one. Abort with a clear
    // message rather than silently corrupting cross-table tenant linkage.
    final businessId = authState.user.businessId;
    if (businessId == null || businessId.isEmpty) {
      if (mounted) {
        AppToast.show(
          context,
          'Session error: no business context. Please sign in again.',
          variant: AppToastVariant.error,
        );
      }
      return;
    }

    setState(() => _confirming = true);
    try {
      final cashierId = authState.user.id;
      final txId = const Uuid().v4();
      // A saved customer links via customer_id; an ad-hoc "name only" selection
      // carries just the snapshot name. The name is always snapshotted so
      // receipts/history stay correct if a saved customer is later renamed.
      final selection = _customer;
      final customerName = selection?.displayName?.trim() ?? '';

      final tx = TransactionsTableCompanion.insert(
        id: txId,
        cashierId: cashierId,
        businessId: Value(businessId),
        branchId: Value(branchId),
        totalAmount: widget.total,
        taxAmount: widget.tax,
        subtotal: widget.subtotal,
        discountAmount: Value(widget.discountAmount),
        customerId: Value(selection?.customerId),
        customerName: Value(customerName.isEmpty ? null : customerName),
        paymentMethod: Value(_paymentMethod),
        amountReceived: Value(_isCash ? _amountReceived : null),
        changeDue: Value(_isCash ? _change : null),
        // Whole-quantity lines count by their qty; weighed lines (fractional)
        // count as a single item so 1.5 kg isn't rounded to "2 items".
        itemCount: widget.items.fold(
          0,
          (s, i) => s + (i.qty == i.qty.roundToDouble() ? i.qty.round() : 1),
        ),
        createdAt: Value(DateTime.now()),
      );

      // widget.tax is already post-discount (see CartTotals); back-derive the
      // same ratio here so each persisted line's tax sums back to widget.tax
      // instead of the line's raw pre-discount taxAmount.
      final preDiscountTax = widget.items.fold(0.0, (s, i) => s + i.taxAmount);
      final taxRatio = preDiscountTax > 0 ? widget.tax / preDiscountTax : 1.0;

      final txItems = widget.items
          .map(
            (item) => TransactionItemsTableCompanion.insert(
              id: const Uuid().v4(),
              transactionId: txId,
              variantId: item.variantId,
              productName: item.name,
              variantName: item.variant,
              unitPrice: item.unitPrice,
              taxRate: Value(item.taxRate),
              qty: item.qty,
              lineTotal: item.total,
              lineTax: item.taxAmount * taxRatio,
            ),
          )
          .toList();

      // Record the sale and move inventory atomically — never one without the
      // other (see CheckoutService).
      final invoiceNumber = await sl<CheckoutService>().completeSale(
        transaction: tx,
        items: txItems,
        deductions: widget.items
            .map((i) => (variantId: i.variantId, qty: i.qty))
            .toList(),
        businessId: businessId,
        branchId: branchId,
        transactionId: txId,
      );

      // saleCreated is audit-logged inside CheckoutService.completeSale —
      // every sale path shares one chained entry point.

      // Finishing a held sale: convert + soft-delete the draft so it leaves the
      // Held Sales list and exactly one completed transaction remains.
      final draftId = widget.sourceDraftId;
      if (draftId != null) {
        await sl<IDraftSalesRepository>().markConverted(draftId);
        unawaited(
          sl<AuditLogService>().log(
            actionType: AuditLogActionType.draftConverted,
            entityType: 'draft_sale',
            entityId: draftId,
            description:
                'Held sale completed — ${AppFormatters.currency(widget.total)}',
            metadata: {'transaction_id': txId, 'total': widget.total},
            businessId: businessId,
            branchId: branchId,
            userId: cashierId,
          ),
        );
      }

      widget.onPaymentConfirmed();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, _, _) => CheckoutSuccessPage(
            transactionId: txId,
            invoiceNumber: invoiceNumber,
            items: widget.items,
            subtotal: widget.subtotal,
            taxAmount: widget.tax,
            discountAmount: widget.discountAmount,
            total: widget.total,
            amountReceived: _isCash ? _amountReceived : widget.total,
            change: _isCash ? _change : 0,
            paymentMethod: _paymentMethod,
            cashierName: authState.user.fullName ?? authState.user.email ?? '',
            customerName: customerName,
            itemCount: widget.items.length,
            dateTime: DateTime.now(),
            businessId: businessId,
          ),
          transitionsBuilder: (_, animation, _, child) {
            final slide =
                Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );
            final fade = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
            );
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        ),
      );
    } on BranchLockedException catch (e, st) {
      // Not a failure to save — the plan doesn't cover this branch.
      debugPrint('[ProductCheckoutPage] Sale on a locked branch: $e\n$st');
      if (mounted) {
        AppToast.show(context, e.message, variant: AppToastVariant.warning);
        await showUpgradePrompt(context, UpgradeMoment.branchCap);
      }
    } catch (e, st) {
      debugPrint('[ProductCheckoutPage] Error saving transaction: $e\n$st');
      if (mounted) {
        AppToast.show(
          context,
          'Failed to save transaction',
          subtitle: AppErrorMapper.message(e),
          variant: AppToastVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Breakpoints.isTablet(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('Checkout', style: AppTextStyles.title(context)),
        leading: IconButton(
          icon: const Icon(IconlyLight.arrow_left, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isWide ? _buildWideBody(context) : _buildNarrowBody(context),
    );
  }

  // ── Wide layout (tablet / desktop) ────────────────────────────────────────

  Widget _buildWideBody(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left: full-height order summary panel
        Container(
          width: 400,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(right: BorderSide(color: AppColors.borderSoft)),
          ),
          child: _buildOrderSummaryPanel(),
        ),
        // Right: payment form + confirm button
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                  child: _buildPaymentFormContent(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
                child: SafeArea(
                  top: false,
                  child: AppFilledButton(
                    label:
                        'Confirm Payment  ·  ${ProductCartPage.fmtPrice(widget.total)}',
                    loading: _confirming,
                    onPressed: (_canConfirm && !_confirming) ? _confirm : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Narrow layout (phone) ─────────────────────────────────────────────────

  Widget _buildNarrowBody(BuildContext context) {
    return Column(
      children: [
        _buildOrderSummary(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: _buildPaymentFormContent(),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(15),
          child: SafeArea(
            top: false,
            child: AppFilledButton(
              label:
                  'Confirm Payment  ·  ${ProductCartPage.fmtPrice(widget.total)}',
              loading: _confirming,
              onPressed: (_canConfirm && !_confirming) ? _confirm : null,
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared payment form content ───────────────────────────────────────────

  Widget _buildPaymentFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer — inline search: pick existing, type a name only, or quick-add
        CustomerInlinePicker(
          businessId: _businessId,
          initial: _customer,
          // No setState: nothing in this form depends on the selection until
          // confirm, and rebuilding here would fight the picker's own focus.
          onChanged: (sel) => _customer = sel,
        ),
        const SizedBox(height: 20),

        // Payment method (visual cards)
        const AppFieldLabel('Payment Method'),
        const SizedBox(height: 10),
        _buildPaymentMethodSelector(),

        // Cash section
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _isCash
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const AppFieldLabel('Amount Received'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      decoration: appInputDeco('0.00', prefixText: '₱ '),
                      style: getOutfitStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                      onChanged: (v) => setState(
                        () => _amountReceived = double.tryParse(v) ?? 0,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._denoms.map(
                          (d) => DenomChip(
                            label: '₱${d.toInt()}',
                            onTap: () => _addDenom(d),
                          ),
                        ),
                        DenomChip(
                          label: 'Exact',
                          isExact: true,
                          onTap: _setExact,
                        ),
                      ],
                    ),
                    if (_amountReceived > 0) ...[
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _change >= 0
                              ? AppColors.successSoft
                              : AppColors.errorSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _change >= 0 ? 'Change' : 'Short',
                              style: getOutfitStyle(
                                color: _change >= 0
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              ProductCartPage.fmtPrice(_change.abs()),
                              style: getOutfitStyle(
                                color: _change >= 0
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }

  // ── Wide-only: full order summary side panel ──────────────────────────────

  Widget _buildOrderSummaryPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  IconlyLight.paper,
                  size: 18,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: getOutfitStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${widget.items.length} item${widget.items.length == 1 ? '' : 's'}',
                    style: getOutfitStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                ProductCartPage.fmtPrice(widget.total),
                style: getOutfitStyle(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: AppColors.borderSoft),
        // Items list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: widget.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: getOutfitStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.variant.isNotEmpty)
                            Text(
                              item.variant,
                              style: getOutfitStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '×${item.qtyDisplay}',
                      style: getOutfitStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      ProductCartPage.fmtPrice(item.total),
                      style: getOutfitStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1, color: AppColors.borderSoft),
        // Totals
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            children: [
              _summaryLine(
                'Subtotal',
                ProductCartPage.fmtPrice(widget.subtotal),
              ),
              if (widget.discountAmount > 0) ...[
                const SizedBox(height: 4),
                _summaryLine(
                  'Discount',
                  '− ${ProductCartPage.fmtPrice(widget.discountAmount)}',
                  valueColor: AppColors.success,
                ),
              ],
              if (widget.tax > 0) ...[
                const SizedBox(height: 4),
                _summaryLine('Tax', ProductCartPage.fmtPrice(widget.tax)),
              ],
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.borderSoft),
              const SizedBox(height: 10),
              _summaryLine(
                'Total',
                ProductCartPage.fmtPrice(widget.total),
                isBold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Order summary collapsible header (narrow only) ────────────────────────

  Widget _buildOrderSummary() {
    return Container(
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tappable header
          InkWell(
            onTap: () => setState(() => _summaryExpanded = !_summaryExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      IconlyLight.paper,
                      size: 18,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: getOutfitStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${widget.items.length} item${widget.items.length == 1 ? '' : 's'}',
                          style: getOutfitStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    ProductCartPage.fmtPrice(widget.total),
                    style: getOutfitStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _summaryExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      IconlyLight.arrow_down_2,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable items list
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _summaryExpanded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(height: 1, color: AppColors.borderSoft),
                      ...widget.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: getOutfitStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (item.variant.isNotEmpty)
                                      Text(
                                        item.variant,
                                        style: getOutfitStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                '×${item.qtyDisplay}',
                                style: getOutfitStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                ProductCartPage.fmtPrice(item.total),
                                style: getOutfitStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
          // Subtotal / Discount / Tax / Total footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              children: [
                _summaryLine(
                  'Subtotal',
                  ProductCartPage.fmtPrice(widget.subtotal),
                ),
                if (widget.discountAmount > 0) ...[
                  const SizedBox(height: 4),
                  _summaryLine(
                    'Discount',
                    '− ${ProductCartPage.fmtPrice(widget.discountAmount)}',
                    valueColor: AppColors.success,
                  ),
                ],
                if (widget.tax > 0) ...[
                  const SizedBox(height: 4),
                  _summaryLine('Tax', ProductCartPage.fmtPrice(widget.tax)),
                ],
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.borderSoft),
                const SizedBox(height: 8),
                _summaryLine(
                  'Total',
                  ProductCartPage.fmtPrice(widget.total),
                  isBold: true,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSoft),
        ],
      ),
    );
  }

  Widget _summaryLine(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: getOutfitStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: getOutfitStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color:
                valueColor ??
                (isBold ? AppColors.brand : AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  // ── Payment method selector ───────────────────────────────────────────────

  Widget _buildPaymentMethodSelector() {
    return Row(
      children: List.generate(_methods.length, (i) {
        final (value, label, icon) = _methods[i];
        final selected = _paymentMethod == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _paymentMethod = value;
              if (value != 'cash') {
                _amountReceived = 0;
                _amountController.clear();
              }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: EdgeInsets.only(right: i < _methods.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppColors.brand : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.brand : AppColors.borderSoft,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected ? Colors.white : AppColors.textMuted,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    style: getOutfitStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
