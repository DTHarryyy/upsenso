import 'package:flutter/material.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/services/cart_service.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/widgets.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';
import 'package:pos/features/pos/presentation/widgets/discount_sheet.dart';
import 'package:pos/features/products/checkout/product_checkout_page.dart';

class ProductCartPage extends StatelessWidget {
  const ProductCartPage({super.key});

  static String fmtPrice(double v) => AppFormatters.currency(v);
  @override
  Widget build(BuildContext context) {
    final cartService = sl<CartService>();
    return ListenableBuilder(
      listenable: cartService,
      builder: (context, _) {
        // Auto-pop when cart is emptied — but only if this page is active
        // (not buried behind the checkout page when payment clears the cart)
        if (cartService.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted &&
                Navigator.of(context).canPop() &&
                (ModalRoute.of(context)?.isCurrent ?? false)) {
              Navigator.of(context).pop();
            }
          });
        }

        final items = cartService.items;
        final subtotal = items.fold(0.0, (s, i) => s + i.total);
        final tax = items.fold(0.0, (s, i) => s + i.taxAmount);
        final discountAmount = cartService.discountAmount(subtotal);
        final total = (subtotal - discountAmount + tax).clamp(
          0.0,
          double.infinity,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                Text('Cart', style: AppTextStyles.title(context)),
                const SizedBox(width: 8),
                if (cartService.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${cartService.itemCount}',
                      style: getOutfitStyle(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              if (cartService.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.delete_sweep_outlined,
                    color: AppColors.error,
                    size: 22,
                  ),
                  tooltip: 'Clear cart',
                  onPressed: () => _confirmClear(context, cartService),
                ),
            ],
          ),
          body: cartService.isEmpty
              ? _buildEmptyState(context)
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          color: AppColors.borderSoft,
                        ),
                        itemBuilder: (_, i) => _CartItemRow(
                          item: items[i],
                          cartService: cartService,
                        ),
                      ),
                    ),
                    _CartFooter(
                      subtotal: subtotal,
                      tax: tax,
                      total: total,
                      discountAmount: discountAmount,
                      cartService: cartService,
                      onCheckout: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductCheckoutPage(
                            items: List.from(cartService.items),
                            subtotal: subtotal,
                            tax: tax,
                            total: total,
                            discountAmount: discountAmount,
                            onPaymentConfirmed: cartService.clear,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: AppTextStyles.subtitle(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap a product to add items',
            style: AppTextStyles.body(
              context,
            ).copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.storefront_rounded, size: 18),
            label: const Text('Browse Products'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brand,
              side: const BorderSide(color: AppColors.brand),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    CartService cartService,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) cartService.clear();
  }
}

// ── Cart item row ─────────────────────────────────────────────────────────────

class _CartItemRow extends StatelessWidget {
  final CartItem item;
  final CartService cartService;

  const _CartItemRow({required this.item, required this.cartService});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.variantId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        color: AppColors.error,
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
      onDismissed: (_) => cartService.remove(item.variantId),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: getOutfitStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.variant.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.variant,
                        style: getOutfitStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    ProductCartPage.fmtPrice(item.unitPrice),
                    style: getOutfitStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Qty stepper
            _QtyControl(item: item, cartService: cartService),
            const SizedBox(width: 14),
            // Line total
            SizedBox(
              width: 72,
              child: Text(
                ProductCartPage.fmtPrice(item.total),
                textAlign: TextAlign.right,
                style: getOutfitStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Qty stepper ───────────────────────────────────────────────────────────────

class _QtyControl extends StatelessWidget {
  final CartItem item;
  final CartService cartService;

  const _QtyControl({required this.item, required this.cartService});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(
            Icons.remove_rounded,
            () => cartService.setQty(item.variantId, item.qty - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              item.qty.toInt().toString(),
              style: getOutfitStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          _btn(
            Icons.add_rounded,
            () => cartService.setQty(item.variantId, item.qty + 1),
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.brand),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _CartFooter extends StatelessWidget {
  final double subtotal;
  final double tax;
  final double total;
  final double discountAmount;
  final CartService cartService;
  final VoidCallback onCheckout;

  const _CartFooter({
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.discountAmount,
    required this.cartService,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = cartService.hasDiscount;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('Subtotal', ProductCartPage.fmtPrice(subtotal)),
            if (hasDiscount) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        cartService.discountType?.name == 'percentage'
                            ? 'Discount (${cartService.discountValue.toStringAsFixed(cartService.discountValue % 1 == 0 ? 0 : 1)}%)'
                            : 'Discount (Fixed)',
                        style: getOutfitStyle(
                          fontSize: 14,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: cartService.clearDiscount,
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '− ${ProductCartPage.fmtPrice(discountAmount)}',
                    style: getOutfitStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
            if (tax > 0) ...[
              const SizedBox(height: 4),
              _row('Tax', ProductCartPage.fmtPrice(tax)),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: AppColors.borderSoft),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTextStyles.subtitle(context).copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  ProductCartPage.fmtPrice(total),
                  style: getOutfitStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Discount button
            GestureDetector(
              onTap: () => showDiscountSheet(context, cartService, subtotal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: hasDiscount
                      ? AppColors.successSoft
                      : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasDiscount
                        ? AppColors.success
                        : AppColors.borderSoft,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasDiscount
                          ? Icons.local_offer_rounded
                          : Icons.local_offer_outlined,
                      size: 15,
                      color: hasDiscount
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasDiscount
                          ? 'Discount applied · tap to change'
                          : 'Add Discount',
                      style: getOutfitStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hasDiscount
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            AppFilledButton(
              label: 'Proceed to Checkout',
              onPressed: onCheckout,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: getOutfitStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: getOutfitStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
