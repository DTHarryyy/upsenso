import 'package:pos/features/products/domain/entities/category.dart';
import 'package:pos/features/products/domain/entities/inventory_level.dart';
import 'package:pos/features/products/domain/entities/product.dart';
import 'package:pos/features/products/domain/entities/product_variant.dart';

abstract class IProductsRepository {
  // ── Reactive streams ──────────────────────────────────────────────────────

  Stream<List<Product>> watchProducts(String businessId);
  Stream<List<ProductVariant>> watchVariants(String businessId);
  Stream<List<Category>> watchCategories(String businessId);
  Stream<List<InventoryLevel>> watchInventoryLevels(String businessId);

  // ── Barcode resolution ────────────────────────────────────────────────────

  Future<ProductVariant?> getVariantByBarcode(
    String barcode,
    String businessId,
  );
  Future<Product?> getProductByBarcode(String barcode, String businessId);
  Future<Product?> getProductById(String id);
  Future<List<ProductVariant>> getVariantsByProductId(String productId);
}
