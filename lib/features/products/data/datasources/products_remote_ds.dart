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
    String? imagePath,
    String type = 'product',
    String trackingMethod = 'product_stock',
  }) async {
    await client.from('products').upsert({
      'id': id,
      'business_id': businessId,
      'category_id': categoryId,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'tax': tax ?? 0.0,
      'sell_by': sellBy,
      'has_variants': hasVariants,
      'is_active': isActive,
      'image_path': imagePath,
      'type': type,
      'tracking_method': trackingMethod,
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
    String? imagePath,
    String type = 'product',
    String trackingMethod = 'product_stock',
  }) async {
    await client
        .from('products')
        .update({
          'category_id': categoryId,
          'name': name,
          'sku': sku,
          'barcode': barcode,
          'tax': tax ?? 0.0,
          'sell_by': sellBy,
          'has_variants': hasVariants,
          'is_active': isActive,
          'image_path': imagePath,
          'type': type,
          'tracking_method': trackingMethod,
        })
        .eq('id', id);
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

  // ── RECIPE LINES ──────────────────────────────────────────────────────────────

  /// Fetch a business's recipe lines (bill-of-materials) for pull sync.
  Future<List<Map<String, dynamic>>> getRecipeLinesByBusiness(
    String businessId,
  ) async {
    final response = await client
        .from('recipe_lines')
        .select()
        .eq('business_id', businessId)
        .eq('is_deleted', false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> upsertRecipeLine(Map<String, dynamic> row) async {
    await client.from('recipe_lines').upsert(row);
  }

  Future<void> deleteRecipeLine(String id) async {
    await client.from('recipe_lines').delete().eq('id', id);
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
    int? expiryDate,
    required bool isActive,
  }) async {
    await client.from('product_variants').upsert({
      'id': id,
      'product_id': productId,
      'business_id': businessId,
      'name': name,
      'price': price,
      'cost_price': costPrice ?? 0.0,
      'retail_price': retailPrice ?? 0.0,
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
    int? expiryDate,
    required bool isActive,
  }) async {
    await client
        .from('product_variants')
        .update({
          'name': name,
          'price': price,
          'cost_price': costPrice ?? 0.0,
          'retail_price': retailPrice ?? 0.0,
          'stock': stock,
          'sku': sku,
          'barcode': barcode,
          'track_expiry': trackExpiry,
          'expiry_date': expiryDate,
          'is_active': isActive,
        })
        .eq('id', id);
  }

  /// Delete a variant from Supabase.
  Future<void> deleteProductVariant(String id) async {
    await client.from('product_variants').delete().eq('id', id);
  }

  /// Soft-delete a variant that is still referenced by transaction history.
  /// Sets is_active = false so it no longer appears in the product catalogue
  /// but the FK constraints from transaction_items / stock_ledger are satisfied.
  Future<void> softDeleteProductVariant(String id) async {
    await client
        .from('product_variants')
        .update({'is_active': false})
        .eq('id', id);
  }

  /// Fetch all variants for a business (for pull sync).
  Future<List<Map<String, dynamic>>> getVariantsByBusiness(
    String businessId,
  ) async {
    final response = await client
        .from('product_variants')
        .select()
        .eq('business_id', businessId)
        .eq('is_active', true);
    return List<Map<String, dynamic>>.from(response);
  }

  // ── INVENTORY LEVELS ────────────────────────────────────────────────────────

  Future<void> upsertInventoryLevel({
    required String id, // local composite key — not sent to Supabase (uuid mismatch)
    required String variantId,
    required String branchId,
    required String businessId,
    required int quantity,
    double? quantityDecimal,
    int? lowStockAlertOverride,
  }) async {
    // Do NOT send 'id': Supabase generates a UUID on insert.
    // Conflict is resolved via the unique constraint on (product_variant_id, branch_id).
    await client.from('inventory_levels').upsert(
      {
        'product_variant_id': variantId,
        'branch_id': branchId,
        'business_id': businessId,
        'quantity': quantity,
        // null for unit products — 0.0 would mask the integer quantity on other devices.
        'quantity_decimal': quantityDecimal,
        'low_stock_alert_override': lowStockAlertOverride,
      },
      onConflict: 'product_variant_id,branch_id',
    );
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
      'created_at': createdAt.toUtc().toIso8601String(),
    });
  }

  /// Stock ledger rows for a business.
  ///
  /// The ledger is append-only (rows are never updated or deleted), so passing
  /// [createdAfter] returns only entries newer than the last pulled one —
  /// enabling incremental sync. Results are ordered ascending by (created_at,
  /// id) so a created_at cursor can page forward deterministically. Omit both
  /// args for the original full pull.
  Future<List<Map<String, dynamic>>> getStockLedgerByBusiness(
    String businessId, {
    DateTime? createdAfter,
    int? limit,
  }) async {
    var filter = client
        .from('stock_ledger')
        .select()
        .eq('business_id', businessId);
    if (createdAfter != null) {
      filter = filter.gt('created_at', createdAfter.toUtc().toIso8601String());
    }
    final ordered = filter
        .order('created_at', ascending: true)
        .order('id', ascending: true);
    final response =
        limit != null ? await ordered.limit(limit) : await ordered;
    return List<Map<String, dynamic>>.from(response);
  }
}
