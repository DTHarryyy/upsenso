import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:uuid/uuid.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';
import 'package:pos/core/services/stock_movement_service.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/recipes/domain/entities/ingredient.dart';
import 'package:pos/features/recipes/domain/entities/stock_movement.dart';
import 'package:pos/features/recipes/domain/repositories/i_ingredients_repository.dart';

class IngredientsRepository implements IIngredientsRepository {
  final ProductsDao _productsDao;
  final ProductVariantsDao _variantsDao;
  final InventoryLevelsDao _levelsDao;
  final StockMovementService _stockMovement;
  final StockLedgerDao _ledgerDao;

  static const _uuid = Uuid();

  IngredientsRepository({
    required ProductsDao productsDao,
    required ProductVariantsDao variantsDao,
    required InventoryLevelsDao levelsDao,
    required StockMovementService stockMovement,
    required StockLedgerDao ledgerDao,
  })  : _productsDao = productsDao,
        _variantsDao = variantsDao,
        _levelsDao = levelsDao,
        _stockMovement = stockMovement,
        _ledgerDao = ledgerDao;

  @override
  Stream<List<Ingredient>> watchByBusinessId(String businessId) {
    // Rebuild on BOTH product changes (add / edit / rename / delete) AND stock
    // movements (inventory_levels). A restock/adjust only touches levels +
    // variants + ledger — never the products table — so watching products
    // alone would leave the list and detail hero showing stale stock.
    late final StreamController<List<Ingredient>> controller;
    StreamSubscription<void>? productsSub;
    StreamSubscription<void>? levelsSub;
    var isBuilding = false;
    var rebuildQueued = false;

    Future<void> rebuild() async {
      if (isBuilding) {
        rebuildQueued = true;
        return;
      }
      isBuilding = true;
      try {
        final list = await getByBusinessId(businessId);
        if (!controller.isClosed) controller.add(list);
      } catch (e, st) {
        debugPrint('[IngredientsRepository] watch rebuild error: $e\n$st');
        if (!controller.isClosed) controller.addError(e, st);
      } finally {
        isBuilding = false;
        if (rebuildQueued) {
          rebuildQueued = false;
          await rebuild();
        }
      }
    }

    controller = StreamController<List<Ingredient>>(
      onListen: () {
        productsSub =
            _productsDao.watchByBusinessId(businessId).listen((_) => rebuild());
        levelsSub =
            _levelsDao.watchByBusinessId(businessId).listen((_) => rebuild());
      },
      onCancel: () async {
        await productsSub?.cancel();
        await levelsSub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<List<Ingredient>> getByBusinessId(String businessId) async {
    final products = await _productsDao.getByBusinessId(businessId);
    return _buildIngredients(products, businessId);
  }

  Future<List<Ingredient>> _buildIngredients(
    List<ProductsTableData> allProducts,
    String businessId,
  ) async {
    final ingredients = allProducts.where(
      (p) => p.type == 'ingredient' && p.isActive,
    );
    final result = <Ingredient>[];
    for (final p in ingredients) {
      final variants = await _variantsDao.getByProductId(p.id);
      final v = variants.where((v) => v.isActive).firstOrNull;
      if (v == null) continue;

      final levels = await _levelsDao.getByVariantId(v.id);
      final stock = levels.fold(0.0, (s, l) => s + l.effectiveQuantity);

      result.add(Ingredient(
        id: v.id,
        productId: p.id,
        businessId: businessId,
        name: p.name,
        unit: v.unit,
        stock: stock,
        costPrice: v.costPrice,
        lowStockAlert: v.lowStockAlert,
        isActive: v.isActive,
      ));
    }
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  @override
  Future<Ingredient?> getById(String variantId) async {
    final v = await _variantsDao.getById(variantId);
    if (v == null) return null;
    final p = await _productsDao.getById(v.productId);
    if (p == null || p.type != 'ingredient') return null;

    final levels = await _levelsDao.getByVariantId(variantId);
    final stock = levels.fold(0.0, (s, l) => s + l.effectiveQuantity);

    return Ingredient(
      id: v.id,
      productId: p.id,
      businessId: p.businessId,
      name: p.name,
      unit: v.unit,
      stock: stock,
      costPrice: v.costPrice,
      lowStockAlert: v.lowStockAlert,
      isActive: v.isActive,
    );
  }

  @override
  Future<String> create({
    required String businessId,
    required String name,
    String? unit,
    double openingStock = 0,
    String? branchId,
    int? lowStockAlert,
  }) async {
    final productId = _uuid.v4();
    final variantId = _uuid.v4();

    await _productsDao.insertProduct(
      ProductsTableCompanion.insert(
        id: productId,
        businessId: businessId,
        name: name.trim(),
        type: const Value('ingredient'),
        trackingMethod: const Value('product_stock'),
        sellBy: const Value('unit'),
        isActive: const Value(true),
      ),
    );

    await _variantsDao.insertVariant(
      ProductVariantsTableCompanion.insert(
        id: variantId,
        productId: productId,
        businessId: businessId,
        name: 'Default',
        unit: Value(unit),
        lowStockAlert: Value(lowStockAlert),
        trackStock: const Value(true),
        trackExpiry: const Value(false),
      ),
    );

    if (openingStock > 0 && branchId != null) {
      await _stockMovement.apply(
        variantId: variantId,
        productId: productId,
        businessId: businessId,
        branchId: branchId,
        isIncoming: true,
        quantity: openingStock,
        reason: 'Restock',
        sourceType: 'opening_stock',
      );
    }

    sl<AuditLogService>().log(
      actionType: AuditLogActionType.ingredientCreated,
      entityType: 'ingredient',
      entityId: variantId,
      entityName: name.trim(),
      description: 'Ingredient ${name.trim()} created',
      metadata: {'unit': unit, 'opening_stock': openingStock},
      businessId: businessId,
      branchId: branchId,
    );

    return variantId;
  }

  @override
  Future<void> update({
    required String variantId,
    required String productId,
    required String name,
    String? unit,
    int? lowStockAlert,
  }) async {
    await _productsDao.updateProduct(
      productId,
      ProductsTableCompanion(
        name: Value(name.trim()),
        syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );
    await _variantsDao.updateUnitAndAlert(
      variantId,
      unit: unit,
      lowStockAlert: lowStockAlert,
    );

    sl<AuditLogService>().log(
      actionType: AuditLogActionType.ingredientUpdated,
      entityType: 'ingredient',
      entityId: variantId,
      entityName: name.trim(),
      description: 'Ingredient ${name.trim()} updated',
    );
  }

  @override
  Future<void> softDelete(String productId) async {
    final product = await _productsDao.getById(productId);
    await _productsDao.updateProduct(
      productId,
      ProductsTableCompanion(
        isActive: const Value(false),
        syncStatus: Value(SyncStatus.pendingDelete.toInt()),
        localUpdatedAt: Value(DateTime.now()),
      ),
    );

    sl<AuditLogService>().log(
      actionType: AuditLogActionType.ingredientDeleted,
      entityType: 'ingredient',
      entityId: productId,
      entityName: product?.name,
      description: 'Ingredient ${product?.name ?? productId} deleted',
    );
  }

  @override
  Future<void> adjustStock({
    required String variantId,
    required String productId,
    required String businessId,
    required String branchId,
    required bool isIncoming,
    required double quantity,
    required String reason,
    String? note,
  }) async {
    await _stockMovement.apply(
      variantId: variantId,
      productId: productId,
      businessId: businessId,
      branchId: branchId,
      isIncoming: isIncoming,
      quantity: quantity,
      reason: reason,
      note: note,
    );

    final product = await _productsDao.getById(productId);
    sl<AuditLogService>().log(
      actionType:
          isIncoming ? AuditLogActionType.stockAdded : AuditLogActionType.stockAdjusted,
      entityType: 'ingredient',
      entityId: variantId,
      entityName: product?.name,
      description: isIncoming
          ? 'Restocked ${product?.name ?? 'ingredient'} (+$quantity)'
          : 'Adjusted ${product?.name ?? 'ingredient'} stock (-$quantity)',
      metadata: {'quantity': quantity, 'reason': reason},
      businessId: businessId,
      branchId: branchId,
    );
  }

  @override
  Stream<List<StockMovement>> watchHistory(String variantId) {
    return _ledgerDao.watchByVariantId(variantId).map(
      (rows) => rows
          .map(
            (r) => StockMovement(
              id: r.id,
              changeType: r.changeType,
              quantity: r.quantity,
              quantityBefore: r.quantityBefore,
              quantityAfter: r.quantityAfter,
              reason: r.reason,
              note: r.note,
              createdAt: r.createdAt,
              // sourceType is accepted at write-time for call-site compat but
              // never persisted in stock_ledger, so it's unknown on read-back.
            ),
          )
          .toList(),
    );
  }
}
