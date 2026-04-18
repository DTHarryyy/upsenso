import 'package:supabase_flutter/supabase_flutter.dart';

class ProductsRemoteDs {
  final SupabaseClient client;
  ProductsRemoteDs(this.client);

  // ── PRODUCTS ────────────────────────────────────────────────────────────────

  /// Upsert a product to Supabase (safe for re-sync).
  Future<void> createProduct({
    required String id,
    required String businessId,
    String? categoryId,
    required String name,
    String? sku,
    String? barcode,
    double? tax,
    String sellBy = 'unit',
    required bool hasVariants,
    required bool isActive,
  }) async {
    await client.from('products').upsert({
      'id': id,
      'business_id': businessId,
      'category_id': categoryId,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'tax': tax,
      'sell_by': sellBy,
      'has_variants': hasVariants,
      'is_active': isActive,
    });
  }

  /// Update an existing product on Supabase.
  Future<void> updateProduct({
    required String id,
    String? categoryId,
    required String name,
    String? sku,
    String? barcode,
    double? tax,
    required String sellBy,
    required bool hasVariants,
    required bool isActive,
  }) async {
    await client.from('products').update({
      'category_id': categoryId,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'tax': tax,
      'sell_by': sellBy,
      'has_variants': hasVariants,
      'is_active': isActive,
    }).eq('id', id);
  }

  /// Delete a product from Supabase.
  Future<void> deleteProduct(String id) async {
    await client.from('products').delete().eq('id', id);
  }

  /// Fetch all products for a business (for pull sync).
  Future<List<Map<String, dynamic>>> getProductsByBusiness(
    String businessId,
  ) async {
    final response = await client
        .from('products')
        .select()
        .eq('business_id', businessId)
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  // ── PRODUCT VARIANTS ────────────────────────────────────────────────────────

  /// Upsert a product variant to Supabase (safe for re-sync).
  Future<void> createProductVariant({
    required String id,
    required String productId,
    required String businessId,
    required String name,
    required double price,
    double? costPrice,
    double? retailPrice,
    required int stock,
    String? sku,
    String? barcode,
    double? stockDecimal,
    bool trackExpiry = false,
    String? expiryDate,
    required bool isActive,
  }) async {
    await client.from('product_variants').upsert({
      'id': id,
      'product_id': productId,
      'business_id': businessId,
      'name': name,
      'price': price,
      'cost_price': costPrice,
      'retail_price': retailPrice,
      'stock': stock,
      'sku': sku,
      'barcode': barcode,
      'track_expiry': trackExpiry,
      'expiry_date': expiryDate,
      'is_active': isActive,
    });
  }

  /// Update an existing variant on Supabase.
  Future<void> updateProductVariant({
    required String id,
    required String name,
    required double price,
    double? costPrice,
    double? retailPrice,
    required int stock,
    String? sku,
    String? barcode,
    bool trackExpiry = false,
    String? expiryDate,
    required bool isActive,
  }) async {
    await client.from('product_variants').update({
      'name': name,
      'price': price,
      'cost_price': costPrice,
      'retail_price': retailPrice,
      'stock': stock,
      'sku': sku,
      'barcode': barcode,
      'track_expiry': trackExpiry,
      'expiry_date': expiryDate,
      'is_active': isActive,
    }).eq('id', id);
  }

  /// Delete a variant from Supabase.
  Future<void> deleteProductVariant(String id) async {
    await client.from('product_variants').delete().eq('id', id);
  }

  /// Fetch all variants for a business (for pull sync).
  Future<List<Map<String, dynamic>>> getVariantsByBusiness(
    String businessId,
  ) async {
    final response = await client
        .from('product_variants')
        .select()
        .eq('business_id', businessId);
    return List<Map<String, dynamic>>.from(response);
  }

  // ── INVENTORY LEVELS ────────────────────────────────────────────────────────

  Future<void> upsertInventoryLevel({
    required String id,
    required String variantId,
    required String branchId,
    required String businessId,
    required int quantity,
    double? quantityDecimal,
    int? lowStockAlertOverride,
  }) async {
    await client.from('inventory_levels').upsert({
      'id': id,
      'variant_id': variantId,
      'branch_id': branchId,
      'business_id': businessId,
      'quantity': quantity,
      'quantity_decimal': quantityDecimal,
      'low_stock_alert_override': lowStockAlertOverride,
    });
  }

  Future<List<Map<String, dynamic>>> getInventoryLevelsByBusiness(
    String businessId,
  ) async {
    final response = await client
        .from('inventory_levels')
        .select()
        .eq('business_id', businessId);
    return List<Map<String, dynamic>>.from(response);
  }

  // ── STOCK LEDGER ─────────────────────────────────────────────────────────────

  Future<void> insertStockLedgerEntry({
    required String id,
    required String variantId,
    required String productId,
    required String branchId,
    required String businessId,
    required String changeType,
    required double quantity,
    double? quantityBefore,
    double? quantityAfter,
    required String reason,
    String? note,
    required DateTime createdAt,
  }) async {
    await client.from('stock_ledger').upsert({
      'id': id,
      'variant_id': variantId,
      'product_id': productId,
      'branch_id': branchId,
      'business_id': businessId,
      'change_type': changeType,
      'quantity': quantity,
      'quantity_before': quantityBefore,
      'quantity_after': quantityAfter,
      'reason': reason,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getStockLedgerByBusiness(
    String businessId,
  ) async {
    final response = await client
        .from('stock_ledger')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
