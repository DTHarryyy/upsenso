import 'package:pos/features/pos/data/models/cart_model.dart';
import 'package:pos/features/drafts/domain/entities/draft_sale_item.dart';

/// Translates persisted draft data back into live POS cart types.
class DraftCartMapper {
  DraftCartMapper._();

  static List<CartItem> toCartItems(List<DraftSaleItem> items) => items
      .map(
        (i) => CartItem(
          variantId: i.variantId,
          name: i.productName,
          variant: i.variantName,
          unitPrice: i.unitPrice,
          taxRate: i.taxRate,
        )..qty = i.qty,
      )
      .toList();

  static DiscountType? discountTypeFrom(String? value) => switch (value) {
    'percentage' => DiscountType.percentage,
    'fixed' => DiscountType.fixed,
    _ => null,
  };

  static String? discountTypeToString(DiscountType? type) => switch (type) {
    DiscountType.percentage => 'percentage',
    DiscountType.fixed => 'fixed',
    null => null,
  };
}
