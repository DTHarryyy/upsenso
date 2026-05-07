import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/features/inventory/domain/repositories/i_inventory_repository.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';
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

  const ProductCheckoutPage({
    super.key,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.discountAmount = 0,
    required this.onPaymentConfirmed,
  });

  @override
  State<ProductCheckoutPage> createState() => _ProductCheckoutPageState();
}

class _ProductCheckoutPageState extends State<ProductCheckoutPage> {
  final _customerController = TextEditingController();
  final _amountController = TextEditingController();

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
    ('cash', 'Cash', Icons.payments_outlined),
    ('card', 'Card', Icons.credit_card_rounded),
    ('gcash', 'GCash', Icons.phone_android_rounded),
    ('maya', 'Maya', Icons.account_balance_wallet_outlined),
  ];

  bool get _isCash => _paymentMethod == 'cash';
  double get _change => _amountReceived - widget.total;
  bool get _canConfirm => !_isCash || (_amountReceived > 0 && _change >= 0);

  @override
  void dispose() {
    _customerController.dispose();
    _amountController.dispose();
    super.dispose();
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
          StatusSnack.show(
            context,
            type: StatusType.error,
            message: 'No branch assigned. Please contact your administrator.',
          );
        }
        return;
      }
    }

    setState(() => _confirming = true);
    try {
      final cashierId = authState.user.id;
      final txId = const Uuid().v4();
      final customerName = _customerController.text.trim();

      final tx = TransactionsTableCompanion.insert(
        id: txId,
        cashierId: cashierId,
        businessId: Value(authState.user.businessId),
        branchId: Value(branchId),
        totalAmount: widget.total,
        taxAmount: widget.tax,
        subtotal: widget.subtotal,
        discountAmount: Value(widget.discountAmount),
        customerName: Value(customerName.isEmpty ? null : customerName),
        paymentMethod: Value(_paymentMethod),
        amountReceived: Value(_isCash ? _amountReceived : null),
        changeDue: Value(_isCash ? _change : null),
        itemCount: widget.items.fold(0, (s, i) => s + i.qty.round()),
      );

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
              lineTax: item.taxAmount,
            ),
          )
          .toList();

      await sl<TransactionsDao>().insertTransaction(tx, txItems);

      await sl<IInventoryRepository>().recordSaleDeductions(
        items: widget.items
            .map((i) => (variantId: i.variantId, qty: i.qty.round()))
            .toList(),
        businessId: authState.user.businessId ?? '',
        branchId: branchId,
      );

      widget.onPaymentConfirmed();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, _, _) => CheckoutSuccessPage(
            transactionId: txId,
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
            businessId: authState.user.businessId ?? '',
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
    } catch (e) {
      if (mounted) {
        StatusSnack.show(
          context,
          type: StatusType.error,
          message: 'Failed to save transaction: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('Checkout', style: AppTextStyles.title(context)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          _buildOrderSummary(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer name
                  const AppFieldLabel('Customer (optional)'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _customerController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    decoration: appInputDeco('Customer name'),
                    style: getOutfitStyle(color: AppColors.textPrimary),
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
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                decoration: appInputDeco(
                                  '0.00',
                                  prefixText: '₱ ',
                                ),
                                style: getOutfitStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                                onChanged: (v) => setState(
                                  () =>
                                      _amountReceived = double.tryParse(v) ?? 0,
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
              ),
            ),
          ),

          // Confirm button
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
      ),
    );
  }

  // ── Order summary header ──────────────────────────────────────────────────

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
                      Icons.receipt_long_rounded,
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
                      Icons.keyboard_arrow_down_rounded,
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
                                '×${item.qty.toInt()}',
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
