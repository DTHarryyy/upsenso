import 'package:pos/features/products/domain/entities/category.dart';
import 'package:pos/features/products/domain/entities/inventory_level.dart';
import 'package:pos/features/products/domain/entities/product.dart';
import 'package:pos/features/products/domain/entities/product_variant.dart';
import 'package:pos/features/products/domain/repositories/i_products_repository.dart';

class WatchCatalogUseCase {
  final IProductsRepository _repository;
  const WatchCatalogUseCase(this._repository);

  Stream<List<Product>> watchProducts(String businessId) =>
      _repository.watchProducts(businessId);

  Stream<List<ProductVariant>> watchVariants(String businessId) =>
      _repository.watchVariants(businessId);

  Stream<List<Category>> watchCategories(String businessId) =>
      _repository.watchCategories(businessId);

  Stream<List<InventoryLevel>> watchInventoryLevels(String businessId) =>
      _repository.watchInventoryLevels(businessId);
}
