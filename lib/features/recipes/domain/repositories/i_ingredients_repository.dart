import 'package:pos/features/recipes/domain/entities/ingredient.dart';
import 'package:pos/features/recipes/domain/entities/stock_movement.dart';

abstract interface class IIngredientsRepository {
  Stream<List<Ingredient>> watchByBusinessId(String businessId);

  Future<List<Ingredient>> getByBusinessId(String businessId);

  Future<Ingredient?> getById(String variantId);

  Future<String> create({
    required String businessId,
    required String name,
    String? unit,
    double openingStock,
    String? branchId,
    int? lowStockAlert,
  });

  Future<void> update({
    required String variantId,
    required String productId,
    required String name,
    String? unit,
    int? lowStockAlert,
  });

  Future<void> softDelete(String productId);

  Future<void> adjustStock({
    required String variantId,
    required String productId,
    required String businessId,
    required String branchId,
    required bool isIncoming,
    required double quantity,
    required String reason,
    String? note,
  });

  Stream<List<StockMovement>> watchHistory(String variantId);
}
