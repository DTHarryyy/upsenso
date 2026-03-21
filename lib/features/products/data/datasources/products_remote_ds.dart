import 'package:supabase_flutter/supabase_flutter.dart';

class ProductsRemoteDs {
  final SupabaseClient client;
  ProductsRemoteDs(this.client);

  Future<void> createProduct({
    required String id,
    required String businessId,
    String? categoryId,
    required String name,
    String? sku,
    String? barcode,
    required bool hasVariants,
    required bool isActive,
  }) async {
    await client.from('products').insert({
      'id': id,
      'business_id': businessId,
      'category_id': ?categoryId,
      'name': name,
      'sku': ?sku,
      'barcode': ?barcode,
      'has_variants': hasVariants,
      'is_active': isActive,
    });
  }

  Future<void> createProductVariant({
    required String id,
    required String productId,
    required String businessId,
    required String name,
    required double price,
    double? costPrice,
    required int stock,
    String? sku,
    String? barcode,
    required bool isActive,
  }) async {
    await client.from('product_variants').insert({
      'id': id,
      'product_id': productId,
      'business_id': businessId,
      'name': name,
      'price': price,
      'cost_price': ?costPrice,
      'stock': stock,
      'sku': ?sku,
      'barcode': ?barcode,
      'is_active': isActive,
    });
  }
}
