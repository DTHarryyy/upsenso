import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/services/cart_service.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';

void main() {
  group('CartService.loadFrom', () {
    test('replaces cart with copies and restores a percentage discount', () {
      final cart = CartService();
      cart.addOrIncrement(
        variantId: 'old',
        name: 'Old',
        variant: '',
        unitPrice: 5,
      );

      final source = [
        CartItem(
          variantId: 'v1',
          name: 'Coke',
          variant: '500ml',
          unitPrice: 20,
          taxRate: 12,
        )..qty = 3,
      ];

      cart.loadFrom(
        source,
        discountType: DiscountType.percentage,
        discountValue: 10,
      );

      expect(cart.itemCount, 1);
      expect(cart.items.single.variantId, 'v1');
      expect(cart.items.single.qty, 3);
      expect(cart.hasDiscount, isTrue);
      expect(cart.discountType, DiscountType.percentage);
      expect(cart.discountValue, 10);

      // Mutating the source list afterwards must not affect the cart.
      source.single.qty = 99;
      expect(cart.items.single.qty, 3);
    });

    test('null discount type clears any previous discount', () {
      final cart = CartService();
      cart.applyDiscount(DiscountType.fixed, 50);
      cart.loadFrom([]);
      expect(cart.hasDiscount, isFalse);
      expect(cart.discountValue, 0);
      expect(cart.isEmpty, isTrue);
    });
  });
}
