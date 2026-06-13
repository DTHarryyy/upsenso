import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/recipe_lines_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';

/// Handles inventory deductions for recipe-based products.
/// Called by [InventoryRepository] when tracking_method='recipe'.
class RecipeConsumptionService {
  final RecipeLinesDao _recipeLinesDao;
  final StockLedgerDao _ledgerDao;
  final ProductVariantsDao _variantsDao;
  final InventoryLevelsDao _levelsDao;

  static const _uuid = Uuid();

  RecipeConsumptionService({
    required RecipeLinesDao recipeLinesDao,
    required StockLedgerDao ledgerDao,
    required ProductVariantsDao variantsDao,
    required InventoryLevelsDao levelsDao,
  })  : _recipeLinesDao = recipeLinesDao,
        _ledgerDao = ledgerDao,
        _variantsDao = variantsDao,
        _levelsDao = levelsDao;

  /// Deducts ingredient stock for [qty] units sold of [productVariantId].
  Future<void> consume({
    required String productVariantId,
    required int qty,
    required String businessId,
    required String branchId,
  }) async {
    final lines = await _recipeLinesDao.getByVariantId(productVariantId);
    for (final line in lines) {
      if (line.quantity <= 0) continue;
      final needed = line.quantity * qty;
      final ingredientVariant =
          await _variantsDao.getById(line.ingredientVariantId);
      if (ingredientVariant == null) {
        debugPrint(
          '[Recipe] consume: ingredient variant ${line.ingredientVariantId} not found — skipping',
        );
        continue;
      }

      await _ledgerDao.db.transaction(() async {
        final levelBefore =
            await _levelsDao.getLevel(line.ingredientVariantId, branchId);
        final double qtyBefore = levelBefore?.effectiveQuantity ?? 0.0;
        final double qtyAfter = (qtyBefore - needed).clamp(0.0, 999999.0);

        await _ledgerDao.insertEntry(
          StockLedgerTableCompanion.insert(
            id: _uuid.v4(),
            variantId: line.ingredientVariantId,
            productId: ingredientVariant.productId,
            branchId: branchId,
            businessId: businessId,
            changeType: 'OUT',
            quantity: needed,
            quantityBefore: Value(qtyBefore),
            quantityAfter: Value(qtyAfter),
            reason: 'Recipe consumption',
            createdAt: Value(DateTime.now()),
          ),
        );

        await _levelsDao.adjustQuantity(
          variantId: line.ingredientVariantId,
          branchId: branchId,
          businessId: businessId,
          delta: -needed.round(),
        );

        await _variantsDao.decrementStockIfTracked(
          line.ingredientVariantId,
          needed,
        );
      });
    }
  }

  /// Returns how many units of [productVariantId] can currently be made,
  /// limited by whichever ingredient is most constrained.
  /// Returns null when there are no recipe lines (treat as unlimited).
  Future<double?> availableUnits({
    required String productVariantId,
    required String branchId,
  }) async {
    final lines = await _recipeLinesDao.getByVariantId(productVariantId);
    if (lines.isEmpty) return null;

    double? minUnits;
    for (final line in lines) {
      if (line.quantity <= 0) continue;
      final level =
          await _levelsDao.getLevel(line.ingredientVariantId, branchId);
      final available = level?.effectiveQuantity ?? 0.0;
      final units = available / line.quantity;
      if (minUnits == null || units < minUnits) minUnits = units;
    }
    return minUnits;
  }
}
