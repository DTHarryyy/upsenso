import 'package:pos/features/inventory/data/inventory_data.dart';

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

  Future<void> recordSaleDeductions({
    required List<({String variantId, int qty})> items,
    required String businessId,
    required String? branchId,
  });

  /// Returns the subset of [items] whose tracked stock is below the requested
  /// quantity (e.g. a held sale where stock sold out while parked). Untracked
  /// variants are ignored. Empty list = everything is in stock.
  Future<List<({String variantId, double available, double requested})>>
  checkStockAvailability({
    required List<({String variantId, double qty})> items,
    required String? branchId,
  });
}
