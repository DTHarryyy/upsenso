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
}
