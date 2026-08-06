import 'package:pos/features/inventory/data/inventory_data.dart';
import 'package:pos/features/inventory/domain/entities/stock_shortage.dart';

abstract class IInventoryRepository {
  Stream<void> watchChanges(String businessId);

  Future<InventoryData> load({required String businessId, String? branchId});

  Future<void> adjustStock({
    required String variantId,
    required String productId,
    required String businessId,
    String? branchId,
    required bool isIncoming,
    required int quantity,
    required String reason,
    String? note,
  });

  // qty is a double so weight/fraction products (e.g. 0.5 kg) deduct the exact
  // amount sold instead of being rounded to a whole unit.
  //
  // [sourceId] (the sale's transaction id) is stamped on the stock ledger
  // entries so server-side RLS can verify each deduction traces back to a
  // real sale instead of trusting the client-supplied source_type label.
  Future<void> recordSaleDeductions({
    required List<({String variantId, double qty})> items,
    required String businessId,
    required String? branchId,
    required String sourceId,
    bool allowNegativeStock = false,
  });

  /// Reverses [recordSaleDeductions] for refunded items — restocks tracked
  /// product stock and recipe ingredients. [sourceId] (the refund's id) is
  /// stamped on the stock ledger entries for traceability.
  Future<void> reverseSaleDeductions({
    required List<({String variantId, double qty})> items,
    required String businessId,
    required String? branchId,
    required String sourceId,
  });

  /// Returns the subset of [items] whose tracked stock is below the requested
  /// quantity (e.g. a held sale where stock sold out while parked). Untracked
  /// variants are ignored. Empty list = everything is in stock.
  Future<List<StockShortage>> checkStockAvailability({
    required List<({String variantId, double qty})> items,
    required String? branchId,
  });
}
