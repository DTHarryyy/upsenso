import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/features/products/domain/entities/category.dart';
import 'package:pos/features/products/domain/entities/inventory_level.dart';
import 'package:pos/features/products/domain/entities/product.dart';
import 'package:pos/features/products/domain/entities/product_variant.dart';
import 'package:pos/features/products/domain/repositories/i_products_repository.dart';

class ProductsRepository implements IProductsRepository {
  final ProductsDao _productsDao;
  final ProductVariantsDao _variantsDao;
  final CategoriesDao _categoriesDao;
  final InventoryLevelsDao _levelsDao;

  const ProductsRepository({
    required ProductsDao productsDao,
    required ProductVariantsDao variantsDao,
    required CategoriesDao categoriesDao,
    required InventoryLevelsDao levelsDao,
  }) : _productsDao = productsDao,
       _variantsDao = variantsDao,
       _categoriesDao = categoriesDao,
       _levelsDao = levelsDao;

  // ── Streams ───────────────────────────────────────────────────────────────

  @override
  Stream<List<Product>> watchProducts(String businessId) => _productsDao
      .watchByBusinessId(businessId)
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
  );

  static ProductVariant _mapVariant(ProductVariantsTableData row) =>
      ProductVariant(
        id: row.id,
        productId: row.productId,
        businessId: row.businessId,
        name: row.name,
        price: row.price,
        costPrice: row.costPrice,
        stock: row.stock,
        stockDecimal: row.stockDecimal,
        sku: row.sku,
        barcode: row.barcode,
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
