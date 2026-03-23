import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';
import 'package:pos/features/pos/presentation/pages/checkout_success_page.dart';
import 'package:pos/features/pos/presentation/widgets/denom_chip.dart';
import 'package:pos/features/pos/presentation/widgets/total_banner.dart';

class CheckoutPaymentPage extends StatefulWidget {
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final VoidCallback onPaymentConfirmed;

  const CheckoutPaymentPage({
    super.key,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.onPaymentConfirmed,
  });

  @override
  State<CheckoutPaymentPage> createState() => _CheckoutPaymentPageState();
}

class _CheckoutPaymentPageState extends State<CheckoutPaymentPage> {
  final _customerController = TextEditingController();
  final _amountController = TextEditingController();
  String _paymentMethod = 'cash';
  double _amountReceived = 0;
  bool _confirming = false;

  static const _denoms = [
    1.0, 5.0, 10.0, 20.0, 50.0, 100.0, 200.0, 500.0, 1000.0,
  ];

  bool get _isCash => _paymentMethod == 'cash';
  double get _change => _amountReceived - widget.total;
  bool get _canConfirm =>
      !_isCash || (_amountReceived > 0 && _change >= 0);

  @override
  void dispose() {
    _customerController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _fmt(double v) => '₱${v.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+\.)'),
        (m) => '${m[1]},',
      )}';

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
    setState(() => _confirming = true);
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final cashierId = authState.user.id;
      final branchId = authState.user.branchId;
      final txId = const Uuid().v4();
      final customerName = _customerController.text.trim();

      final tx = TransactionsTableCompanion.insert(
        id: txId,
        cashierId: cashierId,
        branchId: Value(branchId),
        totalAmount: widget.total,
        taxAmount: widget.tax,
        subtotal: widget.subtotal,
        customerName: Value(customerName.isEmpty ? null : customerName),
        paymentMethod: Value(_paymentMethod),
        amountReceived: Value(_isCash ? _amountReceived : null),
        changeDue: Value(_isCash ? _change : null),
        itemCount: widget.items.length,
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

      widget.onPaymentConfirmed();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, _, _) => CheckoutSuccessPage(
            total: widget.total,
            amountReceived: _isCash ? _amountReceived : widget.total,
            change: _isCash ? _change : 0,
            paymentMethod: _paymentMethod,
            customerName: customerName,
            itemCount: widget.items.length,
          ),
          transitionsBuilder: (_, animation, _, child) {
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));
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
          TotalBanner(
            total: widget.total,
            itemCount: widget.items.length,
            tax: widget.tax,
            fmt: _fmt,
          ),

          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Customer (optional) ───────────────────────────────
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

                    // ── Payment method ────────────────────────────────────
                    const AppFieldLabel('Payment Method'),
                    const SizedBox(height: 6),
                    AppDropdown<String>(
                      value: _paymentMethod,
                      items: const [
                        AppDropdownItem(
                          value: 'cash',
                          label: 'Cash',
                          icon: Icons.payments_outlined,
                        ),
                        AppDropdownItem(
                          value: 'card',
                          label: 'Card',
                          icon: Icons.credit_card_rounded,
                        ),
                        AppDropdownItem(
                          value: 'gcash',
                          label: 'GCash',
                          icon: Icons.phone_android_rounded,
                        ),
                        AppDropdownItem(
                          value: 'maya',
                          label: 'Maya',
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _paymentMethod = v ?? 'cash';
                          if (!_isCash) {
                            _amountReceived = 0;
                            _amountController.clear();
                          }
                        });
                      },
                    ),

                    // ── Cash section ──────────────────────────────────────
                    if (_isCash) ...[
                      const SizedBox(height: 20),

                      const AppFieldLabel('Amount Received'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _amountController,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        decoration: appInputDeco('0.00', prefixText: '₱ '),
                        style: getOutfitStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                        onChanged: (v) {
                          setState(() {
                            _amountReceived = double.tryParse(v) ?? 0;
                          });
                        },
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
                              horizontal: 16, vertical: 14),
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
                                _change >= 0
                                    ? _fmt(_change)
                                    : _fmt(_change.abs()),
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
                  ],
                ),
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.all(15),
            child: SafeArea(
              top: false,
              child: AppFilledButton(
                label: 'Confirm Payment',
                loading: _confirming,
                onPressed: (_canConfirm && !_confirming) ? _confirm : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
