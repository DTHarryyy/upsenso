import 'package:pos/features/inventory/data/inventory_data.dart';
import 'package:pos/features/inventory/domain/repositories/i_inventory_repository.dart';

class LoadInventoryUseCase {
  final IInventoryRepository _repository;
  const LoadInventoryUseCase(this._repository);

  Future<InventoryData> call({required String businessId, String? branchId}) =>
      _repository.load(businessId: businessId, branchId: branchId);
}

class AdjustStockUseCase {
  final IInventoryRepository _repository;
  const AdjustStockUseCase(this._repository);

  Future<void> call({
    required String variantId,
    required String productId,
    required String businessId,
    String? branchId,
    required bool isIncoming,
    required int quantity,
    required String reason,
    String? note,
  }) => _repository.adjustStock(
    variantId: variantId,
    productId: productId,
    businessId: businessId,
    branchId: branchId,
    isIncoming: isIncoming,
    quantity: quantity,
    reason: reason,
    note: note,
  );
}
