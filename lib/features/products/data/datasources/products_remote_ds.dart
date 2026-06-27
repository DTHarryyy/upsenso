import 'package:supabase_flutter/supabase_flutter.dart';

class ProductsRemoteDs {
  final SupabaseClient client;
  ProductsRemoteDs(this.client);

  /// Shared incremental/paged fetch for pull-sync.
  ///
  /// Orders by ([tsField], id) ascending and, when a cursor is supplied, returns
  /// only rows strictly after it using a (timestamp, id) keyset — so rows that
  /// share a timestamp (a migration backfill, a batch insert) are never skipped
  /// at a page boundary. A legacy cursor with no id falls back to a plain
  /// greater-than. Omit the cursor + limit for a full pull.
  Future<List<Map<String, dynamic>>> _pullByBusiness(
    String table,
    String businessId,
    String tsField, {
    DateTime? afterTs,
    String? afterId,
    int? limit,
    Map<String, Object> extraEq = const {},
  }) async {
    var filter = client.from(table).select().eq('business_id', businessId);
    extraEq.forEach((k, v) => filter = filter.eq(k, v));
    if (afterTs != null) {
      final ts = afterTs.toUtc().toIso8601String();
      filter = afterId != null
          ? filter.or('$tsField.gt.$ts,and($tsField.eq.$ts,id.gt.$afterId)')
          : filter.gt(tsField, ts);
    }
    final ordered =
        filter.order(tsField, ascending: true).order('id', ascending: true);
    final res = limit != null ? await ordered.limit(limit) : await ordered;
    return List<Map<String, dynamic>>.from(res);
  }

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
    DateTime? clientUpdatedAt,
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
      'client_updated_at': clientUpdatedAt?.toUtc().toIso8601String(),
    });
  }

  /// Update an existing product on Supabase.
  ///
  /// When [clientUpdatedAt] is given, the write only applies if the row's
  /// stored client_updated_at isn't already newer — so a device pushing a
  /// stale edit late can't clobber a newer edit that already landed. Returns
  /// the updated rows; an empty list means the push was rejected as stale.
  Future<List<Map<String, dynamic>>> updateProduct({
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
    DateTime? clientUpdatedAt,
  }) async {
    var query = client
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
          'client_updated_at': clientUpdatedAt?.toUtc().toIso8601String(),
        })
        .eq('id', id);
    if (clientUpdatedAt != null) {
      final iso = clientUpdatedAt.toUtc().toIso8601String();
      query = query.or('client_updated_at.is.null,client_updated_at.lte.$iso');
    }
    return List<Map<String, dynamic>>.from(await query.select('id'));
  }

  /// Delete a product from Supabase.
  Future<void> deleteProduct(String id) async {
    await client.from('products').delete().eq('id', id);
  }

  /// Soft-delete a product by stamping deleted_at. Preferred over a hard delete:
  /// it bumps updated_at (via trigger) so the deletion propagates to other
  /// devices through the delta-pull, and it never violates FK constraints.
  Future<void> softDeleteProduct(String id) async {
    await client
        .from('products')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  /// Fetch all products for a business (for pull sync).
  Future<List<Map<String, dynamic>>> getProductsByBusiness(
    String businessId, {
    DateTime? afterTs,
    String? afterId,
    int? limit,
  }) =>
      _pullByBusiness('products', businessId, 'updated_at',
          afterTs: afterTs, afterId: afterId, limit: limit);

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
    required double stock,
    String? sku,
    String? barcode,
    bool trackExpiry = false,
    int? expiryDate,
    required bool isActive,
    DateTime? clientUpdatedAt,
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
      'client_updated_at': clientUpdatedAt?.toUtc().toIso8601String(),
    });
  }

  /// Update an existing variant on Supabase. See [updateProduct] for the
  /// [clientUpdatedAt] staleness guard.
  Future<List<Map<String, dynamic>>> updateProductVariant({
    required String id,
    required String name,
    required double price,
    double? costPrice,
    double? retailPrice,
    required double stock,
    String? sku,
    String? barcode,
    bool trackExpiry = false,
    int? expiryDate,
    required bool isActive,
    DateTime? clientUpdatedAt,
  }) async {
    var query = client
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
          'client_updated_at': clientUpdatedAt?.toUtc().toIso8601String(),
        })
        .eq('id', id);
    if (clientUpdatedAt != null) {
      final iso = clientUpdatedAt.toUtc().toIso8601String();
      query = query.or('client_updated_at.is.null,client_updated_at.lte.$iso');
    }
    return List<Map<String, dynamic>>.from(await query.select('id'));
  }

  /// Delete a variant from Supabase.
  Future<void> deleteProductVariant(String id) async {
    await client.from('product_variants').delete().eq('id', id);
  }

  /// Soft-delete a variant by stamping deleted_at. is_active is left true on
  /// purpose so the (is_active = true) pull still returns the tombstone once,
  /// letting the deletion propagate to other devices; each device then removes
  /// it locally. FK constraints from transaction_items / stock_ledger stay
  /// satisfied because the row is never hard-deleted.
  Future<void> softDeleteProductVariant(String id) async {
    await client
        .from('product_variants')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  /// Fetch all variants for a business (for pull sync).
  Future<List<Map<String, dynamic>>> getVariantsByBusiness(
    String businessId, {
    DateTime? afterTs,
    String? afterId,
    int? limit,
  }) =>
      _pullByBusiness('product_variants', businessId, 'updated_at',
          afterTs: afterTs,
          afterId: afterId,
          limit: limit,
          extraEq: const {'is_active': true});

  // ── INVENTORY LEVELS ────────────────────────────────────────────────────────

  Future<void> upsertInventoryLevel({
    required String id, // local composite key — not sent to Supabase (uuid mismatch)
    required String variantId,
    required String branchId,
    required String businessId,
    required double quantity,
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
        'low_stock_alert_override': lowStockAlertOverride,
      },
      onConflict: 'product_variant_id,branch_id',
    );
  }

  Future<List<Map<String, dynamic>>> getInventoryLevelsByBusiness(
    String businessId, {
    DateTime? afterTs,
    String? afterId,
    int? limit,
  }) =>
      _pullByBusiness('inventory_levels', businessId, 'updated_at',
          afterTs: afterTs, afterId: afterId, limit: limit);

  /// Record a discarded local change after a Last-Write-Wins supersede so the
  /// loss is never silent (CLAUDE.md: never silently discard).
  Future<void> logSyncConflict({
    required String businessId,
    required String tableName,
    required String recordId,
    required Map<String, dynamic> localData,
  }) async {
    await client.from('sync_conflicts').insert({
      'business_id': businessId,
      'table_name': tableName,
      'record_id': recordId,
      'local_data': localData,
      'resolution': 'lww_remote_wins',
    });
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
    String? sourceType,
    String? sourceId,
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
      // Movement provenance — the server gates stock_ledger inserts by source_type
      // and derives inventory_levels from the ledger, so a null source_type is
      // treated as a manual adjustment (requires inventory.adjust).
      'source_type': sourceType,
      'source_id': sourceId,
      'created_at': createdAt.toUtc().toIso8601String(),
    });
  }

  /// Stock ledger rows for a business. The ledger is append-only, but rows
  /// written in the same batch can share created_at, so it uses the same
  /// (created_at, id) keyset pull as the other tables to avoid skipping ties.
  Future<List<Map<String, dynamic>>> getStockLedgerByBusiness(
    String businessId, {
    DateTime? afterTs,
    String? afterId,
    int? limit,
  }) =>
      _pullByBusiness('stock_ledger', businessId, 'created_at',
          afterTs: afterTs, afterId: afterId, limit: limit);
}
