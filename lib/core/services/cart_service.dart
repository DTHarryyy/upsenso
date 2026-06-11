import 'package:flutter/foundation.dart';
import 'package:pos/features/pos/data/models/cart_model.dart';

/// Singleton cart shared across all pages (Products, POS terminal, etc.).
/// Notifies listeners whenever items change so any widget can rebuild.
class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  // ── Discount ──────────────────────────────────────────────────────────────
  DiscountType? _discountType;
  double _discountValue = 0;

  DiscountType? get discountType => _discountType;
  double get discountValue => _discountValue;
  bool get hasDiscount => _discountType != null && _discountValue > 0;

  /// Returns the discount amount given a [subtotal].
  double discountAmount(double subtotal) {
    if (!hasDiscount) return 0;
    if (_discountType == DiscountType.percentage) {
      return (subtotal * _discountValue / 100).clamp(0, subtotal);
    }
    return _discountValue.clamp(0, subtotal);
  }

  void applyDiscount(DiscountType type, double value) {
    _discountType = type;
    _discountValue = value;
    notifyListeners();
  }

  /// Replaces the entire cart with [items] and restores a discount snapshot.
  /// Used when resuming a held sale. The [items] are copied so the caller's
  /// list can't mutate cart state afterwards.
  void loadFrom(
    List<CartItem> items, {
    DiscountType? discountType,
    double discountValue = 0,
  }) {
    _items
      ..clear()
      ..addAll(
        items.map(
          (i) => CartItem(
            variantId: i.variantId,
            name: i.name,
            variant: i.variant,
            unitPrice: i.unitPrice,
            taxRate: i.taxRate,
          )..qty = i.qty,
        ),
      );
    _discountType = discountType;
    _discountValue = discountType == null ? 0 : discountValue;
    notifyListeners();
  }

  void clearDiscount() {
    _discountType = null;
    _discountValue = 0;
    notifyListeners();
  }

  List<CartItem> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get itemCount => _items.length;

  /// Adds a new item or increments quantity of an existing one.
  void addOrIncrement({
    required String variantId,
    required String name,
    required String variant,
    required double unitPrice,
    double? taxRate,
    double qty = 1,
  }) {
    final idx = _items.indexWhere((i) => i.variantId == variantId);
    if (idx >= 0) {
      _items[idx].qty += qty;
    } else {
      final item = CartItem(
        variantId: variantId,
        name: name,
        variant: variant,
        unitPrice: unitPrice,
        taxRate: taxRate,
      );
      item.qty = qty;
      _items.add(item);
    }
    notifyListeners();
  }

  /// Removes an item by variantId.
  void remove(String variantId) {
    _items.removeWhere((i) => i.variantId == variantId);
    notifyListeners();
  }

  /// Sets the quantity of an item. Removes the item if qty <= 0.
  void setQty(String variantId, double qty) {
    final idx = _items.indexWhere((i) => i.variantId == variantId);
    if (idx < 0) return;
    if (qty <= 0) {
      _items.removeAt(idx);
    } else {
      _items[idx].qty = qty;
    }
    notifyListeners();
  }

  /// Clears all cart items and discount (call after successful checkout).
  void clear() {
    _items.clear();
    _discountType = null;
    _discountValue = 0;
    notifyListeners();
  }
}
