import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/product_barcodes_dao.dart';
import 'package:pos/features/products/domain/entities/category.dart';
import 'package:pos/features/products/domain/entities/inventory_level.dart';
import 'package:pos/features/products/domain/entities/product.dart';
import 'package:pos/features/products/domain/entities/product_variant.dart';
import 'package:pos/features/products/domain/repositories/i_products_repository.dart';

class ProductsRepository implements IProductsRepository {
  final ProductsDao _productsDao;
  final ProductVariantsDao _variantsDao;
  final ProductBarcodesDao _barcodesDao;
  final CategoriesDao _categoriesDao;
  final InventoryLevelsDao _levelsDao;

  const ProductsRepository({
    required ProductsDao productsDao,
    required ProductVariantsDao variantsDao,
    required ProductBarcodesDao barcodesDao,
    required CategoriesDao categoriesDao,
    required InventoryLevelsDao levelsDao,
  }) : _productsDao = productsDao,
       _variantsDao = variantsDao,
       _barcodesDao = barcodesDao,
       _categoriesDao = categoriesDao,
       _levelsDao = levelsDao;

  // ── Streams ───────────────────────────────────────────────────────────────

  @override
  Stream<List<Product>> watchProducts(String businessId) => _productsDao
      .watchSellableByBusinessId(businessId)
      .map((rows) => rows.map(_mapProduct).toList());

  @override
  Stream<List<ProductVariant>> watchVariants(String businessId) => _variantsDao
      .watchByBusinessId(businessId)
      .map((rows) => rows.map(_mapVariant).toList());

  @override
  Stream<List<Category>> watchCategories(String businessId) => _categoriesDao
      .watchByBusinessId(businessId)
      .map((rows) => rows.map(_mapCategory).toList());

  @override
  Stream<List<InventoryLevel>> watchInventoryLevels(String businessId) =>
      _levelsDao
          .watchByBusinessId(businessId)
          .map((rows) => rows.map(_mapLevel).toList());

  // ── Barcode resolution ────────────────────────────────────────────────────

  @override
  Future<ProductVariant?> getVariantByBarcode(
    String barcode,
    String businessId,
  ) async {
    // 1. Normalized store first — the authoritative multi-barcode source.
    final bc = await _barcodesDao.getByCode(barcode, businessId);
    if (bc != null) {
      final v = await _variantsDao.getById(bc.variantId);
      if (v != null) return _mapVariant(v);
    }
    // 2. Legacy fallback (variant.barcode) — backfilled-redundant, but defends
    // against any pre-migration row not yet in product_barcodes.
    final row = await _variantsDao.getByBarcode(barcode, businessId);
    return row == null ? null : _mapVariant(row);
  }

  @override
  Future<Product?> getProductByBarcode(
    String barcode,
    String businessId,
  ) async {
    final row = await _productsDao.getByBarcode(barcode, businessId);
    return row == null ? null : _mapProduct(row);
  }

  @override
  Future<Product?> getProductById(String id) async {
    final row = await _productsDao.getById(id);
    return row == null ? null : _mapProduct(row);
  }

  @override
  Future<List<ProductVariant>> getVariantsByProductId(String productId) async {
    final rows = await _variantsDao.getByProductId(productId);
    return rows.map(_mapVariant).toList();
  }

  // ── Mappers ───────────────────────────────────────────────────────────────

  static Product _mapProduct(ProductsTableData row) => Product(
    id: row.id,
    businessId: row.businessId,
    name: row.name,
    categoryId: row.categoryId,
    sku: row.sku,
    barcode: row.barcode,
    hasVariants: row.hasVariants,
    isActive: row.isActive,
    sellBy: row.sellBy,
    imagePath: row.imagePath,
    tax: row.tax,
    trackingMethod: row.trackingMethod,
  );

  static ProductVariant _mapVariant(ProductVariantsTableData row) =>
      ProductVariant(
        id: row.id,
        productId: row.productId,
        businessId: row.businessId,
        name: row.name,
        price: row.price,
        costPrice: row.costPrice,
        retailPrice: row.retailPrice,
        stock: row.stock,
        sku: row.sku,
        barcode: row.barcode,
        unit: row.unit,
        isActive: row.isActive,
        trackStock: row.trackStock,
        lowStockAlert: row.lowStockAlert,
      );

  static Category _mapCategory(CategoriesTableData row) => Category(
    id: row.id,
    businessId: row.businessId,
    name: row.name,
    sortOrder: row.sortOrder,
  );

  static InventoryLevel _mapLevel(InventoryLevelsTableData row) =>
      InventoryLevel(
        variantId: row.variantId,
        branchId: row.branchId,
        businessId: row.businessId,
        quantity: row.quantity,
      );
}
