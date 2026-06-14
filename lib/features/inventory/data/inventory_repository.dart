import 'package:flutter/foundation.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/services/recipe_consumption_service.dart';
import 'package:pos/core/services/stock_movement_service.dart';
import 'package:pos/features/inventory/data/inventory_data.dart';
import 'package:pos/features/inventory/domain/repositories/i_inventory_repository.dart';

class InventoryRepository implements IInventoryRepository {
  final ProductsDao _productsDao;
  final ProductVariantsDao _variantsDao;
  final BranchesDao _branchesDao;
  final InventoryLevelsDao _levelsDao;
  final StockMovementService _stockMovement;
  final RecipeConsumptionService _recipeConsumption;

  InventoryRepository({
    required ProductsDao productsDao,
    required ProductVariantsDao variantsDao,
    required BranchesDao branchesDao,
    required InventoryLevelsDao levelsDao,
    required StockMovementService stockMovement,
    required RecipeConsumptionService recipeConsumption,
  }) : _productsDao = productsDao,
       _variantsDao = variantsDao,
       _branchesDao = branchesDao,
       _levelsDao = levelsDao,
       _stockMovement = stockMovement,
       _recipeConsumption = recipeConsumption;

  /// Emits whenever inventory_levels or stock_ledger changes.
  @override
  Stream<void> watchChanges(String businessId) {
    return _levelsDao.watchByBusinessId(businessId).map((_) {});
  }

  /// Load all inventory items with per-branch stock for [businessId].
  /// If [branchId] is provided, only loads data for that branch.
  @override
  Future<InventoryData> load({
    required String businessId,
    String? branchId,
  }) async {
    final products = await _productsDao.getSellableByBusinessId(businessId);
    final variants = await _variantsDao.getByBusinessId(businessId);
    final rawBranches = await _branchesDao.getByBusinessId(businessId);
    final levels = await _levelsDao.getByBusinessId(businessId);

    // Deduplicate branches by ID (sync can occasionally insert duplicates)
    final seenIds = <String>{};
    final branches = rawBranches.where((b) => seenIds.add(b.id)).toList();

    // branchInfos always contains ALL branches so the dropdown can show
    // every option regardless of which branch is currently selected.
    final branchInfos = branches
        .map((b) => BranchInfo(id: b.id, name: b.name))
        .toList();

    // The branches actually used for computing per-item stock columns.
    // Build a lookup: variantId -> { branchId -> quantity }
    // branchId is now non-nullable (no "global" rows exist post-v17).
    final levelMap = <String, Map<String, int>>{};
    for (final level in levels) {
      levelMap.putIfAbsent(
        level.variantId,
        () => <String, int>{},
      )[level.branchId] = level.quantity;
    }

    final productMap = {for (final p in products) p.id: p};

    // Deduplicate variants by (productId, name) — repeated syncs can insert
    // multiple rows for the same logical variant with different UUIDs.
    // Active variants take priority: sort active first so the dedup always
    // keeps the active row when both an active and inactive copy exist.
    final sortedVariants = [...variants]
      ..sort((a, b) {
        if (a.isActive == b.isActive) return 0;
        return a.isActive ? -1 : 1; // active first
      });
    final seenVariantKeys = <String>{};
    final dedupedVariants = sortedVariants.where((v) {
      return seenVariantKeys.add('${v.productId}:${v.name}');
    }).toList();

    debugPrint(
      '[INV] load: ${variants.length} raw variants → ${dedupedVariants.length} after dedup',
    );

    final items = <InventoryItem>[];
    for (final v in dedupedVariants) {
      if (!v.isActive) continue;
      final product = productMap[v.productId];
      if (product == null || !product.isActive) continue;

      final branchStock = levelMap[v.id] ?? {};

      // Always include ALL branches in stockByBranch so per-branch columns in
      // the table show accurate data regardless of which branch is filtered.
      // A missing inventory_levels row means 0 for that branch.
      final stockByBranch = <String, int>{};
      for (final b in branches) {
        stockByBranch[b.id] = branchStock[b.id] ?? 0;
      }

      // Total stock: sum inventory_levels rows. A branch with no rows is 0.
      // product_variants.stock is NOT used as a fallback — it is a sync/seed
      // value only and must not be assigned as a branch's starting stock.
      final int total;
      if (branchId != null) {
        total = branchStock[branchId] ?? 0;
      } else {
        total = branchStock.values.fold(0, (s, q) => s + q);
      }

      // Per-branch low stock threshold: check for override on the level row,
      // fall back to the global threshold on the variant.
      InventoryLevelsTableData? levelRow;
      if (branchId != null) {
        for (final l in levels) {
          if (l.variantId == v.id && l.branchId == branchId) {
            levelRow = l;
            break;
          }
        }
      }
      final reorderLevel = _levelsDao.getEffectiveLowStockAlert(
        levelRow,
        v.lowStockAlert,
      );

      final displayName = v.name == 'Default' ? product.name : product.name;
      final variantLabel = v.name == 'Default' ? '' : v.name;

      items.add(
        InventoryItem(
          variantId: v.id,
          productId: v.productId,
          productName: displayName,
          variantName: variantLabel,
          sku: v.sku ?? product.sku,
          stockByBranch: stockByBranch,
          totalStock: total,
          reorderLevel: reorderLevel,
          trackStock: v.trackStock,
          trackingMethod: product.trackingMethod,
        ),
      );
    }

    items.sort((a, b) => a.productName.compareTo(b.productName));

    return InventoryData(items: items, branches: branchInfos);
  }

  /// Adjust stock for a variant at a branch via the shared StockMovementService.
  @override
  Future<void> adjustStock({
    required String variantId,
    required String productId,
    required String businessId,
    String? branchId,
    required bool isIncoming,
    required int quantity,
    required String reason,
    String? note,
  }) async {
    if (branchId == null) {
      assert(
        false,
        'adjustStock called without branchId — auth context must include a branch',
      );
      return;
    }
    await _stockMovement.applyInt(
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

  @override
  Future<List<({String variantId, double available, double requested})>>
  checkStockAvailability({
    required List<({String variantId, double qty})> items,
    required String? branchId,
  }) async {
    final shortages =
        <({String variantId, double available, double requested})>[];
    for (final item in items) {
      if (item.qty <= 0) continue;
      final variant = await _variantsDao.getById(item.variantId);
      if (variant == null) continue;

      final product = await _productsDao.getById(variant.productId);
      final method = product?.trackingMethod ?? 'product_stock';

      if (method == 'service') continue;

      if (method == 'recipe' && branchId != null) {
        final units = await _recipeConsumption.availableUnits(
          productVariantId: item.variantId,
          branchId: branchId,
        );
        // null means no recipe lines — treat as unlimited
        if (units != null && units < item.qty) {
          shortages.add((
            variantId: item.variantId,
            available: units,
            requested: item.qty,
          ));
        }
        continue;
      }

      // product_stock: existing behavior
      if (!variant.trackStock) continue;
      final double available;
      if (branchId != null) {
        final level = await _levelsDao.getLevel(item.variantId, branchId);
        available = level?.effectiveQuantity ?? 0.0;
      } else {
        available = variant.stockDecimal ?? variant.stock.toDouble();
      }
      if (available < item.qty) {
        shortages.add((
          variantId: item.variantId,
          available: available,
          requested: item.qty,
        ));
      }
    }
    return shortages;
  }

  /// Called at checkout to deduct sold items.
  /// Branches on the product's tracking_method:
  ///   product_stock → deduct from the variant's own stock
  ///   recipe        → deduct from ingredient variants via RecipeConsumptionService
  ///   service       → skip (no inventory impact)
  @override
  Future<void> recordSaleDeductions({
    required List<({String variantId, double qty})> items,
    required String businessId,
    required String? branchId,
  }) async {
    if (branchId == null) {
      assert(false, 'recordSaleDeductions called without branchId');
      return;
    }

    for (final item in items) {
      if (item.qty <= 0) continue;
      final variant = await _variantsDao.getById(item.variantId);
      if (variant == null) continue;

      final product = await _productsDao.getById(variant.productId);
      final method = product?.trackingMethod ?? 'product_stock';

      switch (method) {
        case 'recipe':
          // Recipe products are finished goods sold in whole units; the
          // per-ingredient fractional math happens inside the consumer.
          await _recipeConsumption.consume(
            productVariantId: item.variantId,
            qty: item.qty.round(),
            businessId: businessId,
            branchId: branchId,
          );
        case 'service':
          break; // no stock impact
        default:
          if (!variant.trackStock) break;
          // Use the fractional-aware path so weight products deduct the exact
          // quantity (0.5 kg) instead of truncating to an int.
          await _stockMovement.apply(
            variantId: item.variantId,
            productId: variant.productId,
            businessId: businessId,
            branchId: branchId,
            isIncoming: false,
            quantity: item.qty,
            reason: 'Sale',
            sourceType: 'sale',
          );
      }
    }
  }
}
