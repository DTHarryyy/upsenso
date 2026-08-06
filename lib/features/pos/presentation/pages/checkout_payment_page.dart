import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/errors/app_error_mapper.dart';
import 'package:pos/core/services/checkout_service.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/permissions/entitlement_enforcement_service.dart';
import 'package:pos/core/widgets/upgrade_prompt.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/crm/presentation/widgets/customer_inline_picker.dart';
import 'package:pos/features/crm/presentation/widgets/customer_selection.dart';
import 'package:pos/features/inventory/domain/repositories/i_inventory_repository.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';
import 'package:pos/features/pos/presentation/pages/checkout_success_page.dart';
import 'package:pos/features/pos/presentation/widgets/denom_chip.dart';
import 'package:pos/features/pos/presentation/widgets/interactive_checkout.dart';
import 'package:pos/features/pos/presentation/widgets/total_banner.dart';

class CheckoutPaymentPage extends StatefulWidget {
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final double discountAmount;
  final VoidCallback onPaymentConfirmed;

  const CheckoutPaymentPage({
    super.key,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.discountAmount = 0,
    required this.onPaymentConfirmed,
  });

  @override
  State<CheckoutPaymentPage> createState() => _CheckoutPaymentPageState();
}

class _CheckoutPaymentPageState extends State<CheckoutPaymentPage> {
  final _amountController = TextEditingController();
  // null = walk-in (no customer). Set via the customer picker — may be a saved
  // customer, an ad-hoc name, or an explicit walk-in.
  CustomerSelection? _customer;
  String _paymentMethod = 'cash';
  double _amountReceived = 0;
  bool _confirming = false;

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

  bool get _isCash => _paymentMethod == 'cash';
  double get _change => _amountReceived - widget.total;
  bool get _canConfirm => !_isCash || (_amountReceived > 0 && _change >= 0);

  @override
  void dispose() {
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
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final branchCubit = context.read<BranchCubit>();
    String? branchId =
        branchCubit.getSelectedBranchIdForFiltering() ??
        authState.user.branchId;
    String? branchName = branchCubit.getSelectedBranchIdForFiltering() != null
        ? branchCubit.state.selectedBranch
        : authState.user.branchName;

    // When no branch is resolved, prompt the cashier to pick one.
    if (branchId == null) {
      if (branchCubit.state.canSwitchBranches) {
        final selection = await showBranchSaleDialog(context);
        if (selection == null || !mounted) return;
        branchId = selection.id;
        branchName = selection.name;
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

    // A discounted sale requires pos.apply_discount. Enforce here (not only in
    // the discount sheet) so a resumed held sale that already carries a discount
    // can't be completed without the permission — mirrors the server RLS gate.
    if (widget.discountAmount > 0 &&
        !sl<PermissionService>().can(PermissionKeys.posApplyDiscount)) {
      if (mounted) {
        AppToast.show(
          context,
          'You do not have permission to apply a discount.',
          variant: AppToastVariant.error,
        );
      }
      return;
    }

    setState(() => _confirming = true);
    try {
      final cashierId = authState.user.id;
      final txId = const Uuid().v4();
      // Snapshot the name onto the sale even though customer_id links a saved
      // record — so receipts/history stay correct if the customer is later
      // renamed. An ad-hoc "name only" selection carries a name but no id.
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
        itemCount: widget.items.fold(0, (s, i) => s + i.qty.round()),
        createdAt: Value(DateTime.now()),
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

      // Record the sale and move inventory atomically — never one without the
      // other (see CheckoutService). Returns the assigned invoice number.
      final invoiceNumber = await completeInteractiveSale(
        context: context,
        checkoutService: sl<CheckoutService>(),
        inventoryRepository: sl<IInventoryRepository>(),
        transaction: tx,
        transactionItems: txItems,
        cartItems: widget.items,
        businessId: businessId,
        branchId: branchId,
        transactionId: txId,
      );
      if (invoiceNumber == null) return;

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
            branchName: branchName,
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
      // Not a failure to save — the plan doesn't cover this branch. Say so
      // plainly and point at the fix instead of "Failed to save transaction".
      debugPrint('[CheckoutPaymentPage] Sale on a locked branch: $e\n$st');
      if (mounted) {
        AppToast.show(context, e.message, variant: AppToastVariant.warning);
        await showUpgradePrompt(context, UpgradeMoment.branchCap);
      }
    } catch (e, st) {
      debugPrint('[CheckoutPaymentPage] Error saving transaction: $e\n$st');
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

  String? get _businessId {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated ? authState.user.businessId : null;
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
          icon: const Icon(IconlyLight.arrow_left, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          TotalBanner(
            total: widget.total,
            itemCount: widget.items.length,
            tax: widget.tax,
            fmt: AppFormatters.currency,
          ),

          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Customer (optional) — inline search ───────────────
                    CustomerInlinePicker(
                      businessId: _businessId,
                      initial: _customer,
                      onChanged: (sel) => _customer = sel,
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
                          icon: IconlyLight.wallet,
                        ),
                        AppDropdownItem(
                          value: 'card',
                          label: 'Card',
                          icon: IconlyLight.buy,
                        ),
                        AppDropdownItem(
                          value: 'gcash',
                          label: 'GCash',
                          icon: IconlyLight.call,
                        ),
                        AppDropdownItem(
                          value: 'maya',
                          label: 'Maya',
                          icon: IconlyLight.wallet,
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
                                _change >= 0
                                    ? AppFormatters.currency(_change)
                                    : AppFormatters.currency(_change.abs()),
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
