import 'package:flutter_test/flutter_test.dart';
import 'package:pos/features/drafts/domain/entities/draft_sale_item.dart';
import 'package:pos/features/drafts/presentation/draft_cart_mapper.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';

void main() {
  group('DraftCartMapper', () {
    test('toCartItems preserves all line fields', () {
      final items = [
        const DraftSaleItem(
          variantId: 'v1',
          productName: 'Coke',
          variantName: '500ml',
          unitPrice: 20,
          taxRate: 12,
          qty: 2,
          lineTotal: 40,
          lineTax: 4.8,
        ),
      ];
      final cart = DraftCartMapper.toCartItems(items);
      expect(cart, hasLength(1));
      expect(cart.single.variantId, 'v1');
      expect(cart.single.name, 'Coke');
      expect(cart.single.variant, '500ml');
      expect(cart.single.unitPrice, 20);
      expect(cart.single.taxRate, 12);
      expect(cart.single.qty, 2);
    });

    test('discount type round-trips through string form', () {
      expect(
        DraftCartMapper.discountTypeToString(DiscountType.percentage),
        'percentage',
      );
      expect(DraftCartMapper.discountTypeToString(DiscountType.fixed), 'fixed');
      expect(DraftCartMapper.discountTypeToString(null), isNull);

      expect(
        DraftCartMapper.discountTypeFrom('percentage'),
        DiscountType.percentage,
      );
      expect(DraftCartMapper.discountTypeFrom('fixed'), DiscountType.fixed);
      expect(DraftCartMapper.discountTypeFrom(null), isNull);
      expect(DraftCartMapper.discountTypeFrom('garbage'), isNull);
    });
  });
}
