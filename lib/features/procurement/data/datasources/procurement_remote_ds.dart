import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for procurement tables.
/// Schema is confirmed — purchase_orders and purchase_order_lines tables
/// match the columns defined in migration 20260611000002_procurement_schema.sql.
/// The suppliers table schema is confirmed via SuppliersDao.upsertFromServer
/// and the existing _syncSuppliers implementation in SyncService.
class ProcurementRemoteDs {
  final SupabaseClient _client;

  ProcurementRemoteDs(this._client);

  // ── Suppliers ───────────────────────────────────────────────────────────────

  /// Incremental/paged pull for suppliers.
  ///
  /// **Includes soft-deleted rows** (`is_deleted=true`) on purpose: a delta pull
  /// keyed on `updated_at` can only propagate a deletion if the tombstone row
  /// comes through. Filtering `is_deleted=false` here is exactly what previously
  /// stranded deletes on other devices. Keyset ordered by (`updated_at`, `id`) so
  /// rows sharing a timestamp are never skipped at a page boundary. Omit the
  /// cursor + limit for a full (first-run) pull.
  Future<List<Map<String, dynamic>>> getSuppliersByBusiness(
    String businessId, {
    DateTime? afterTs,
    String? afterId,
    int? limit,
  }) async {
    var filter =
        _client.from('suppliers').select().eq('business_id', businessId);
    if (afterTs != null) {
      final ts = afterTs.toUtc().toIso8601String();
      filter = afterId != null
          ? filter.or('updated_at.gt.$ts,and(updated_at.eq.$ts,id.gt.$afterId)')
          : filter.gt('updated_at', ts);
    }
    final ordered =
        filter.order('updated_at', ascending: true).order('id', ascending: true);
    final res = limit != null ? await ordered.limit(limit) : await ordered;
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> upsertSupplier(Map<String, dynamic> row) async {
    await _client.from('suppliers').upsert(row);
  }

  Future<void> deleteSupplier(String id) async {
    await _client.from('suppliers').delete().eq('id', id);
  }

  // ── Purchase Orders ─────────────────────────────────────────────────────────

  /// Incremental/paged pull. Includes soft-deleted rows so tombstones propagate
  /// via delta. Keyset ordered by (updated_at, id); omit cursor + limit for a
  /// full first-run pull.
  Future<List<Map<String, dynamic>>> getPurchaseOrdersByBusiness(
    String businessId, {
    DateTime? afterTs,
    String? afterId,
    int? limit,
  }) async {
    var filter =
        _client.from('purchase_orders').select().eq('business_id', businessId);
    if (afterTs != null) {
      final ts = afterTs.toUtc().toIso8601String();
      filter = afterId != null
          ? filter.or('updated_at.gt.$ts,and(updated_at.eq.$ts,id.gt.$afterId)')
          : filter.gt('updated_at', ts);
    }
    final ordered =
        filter.order('updated_at', ascending: true).order('id', ascending: true);
    final res = limit != null ? await ordered.limit(limit) : await ordered;
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> upsertPurchaseOrder(Map<String, dynamic> row) async {
    await _client.from('purchase_orders').upsert(row);
  }

  Future<void> deletePurchaseOrder(String id) async {
    await _client.from('purchase_orders').delete().eq('id', id);
  }

  // ── Purchase Order Lines ────────────────────────────────────────────────────

  /// Incremental/paged pull (includes tombstones). Keyset (updated_at, id).
  Future<List<Map<String, dynamic>>> getPurchaseOrderLinesByBusiness(
    String businessId, {
    DateTime? afterTs,
    String? afterId,
    int? limit,
  }) async {
    var filter = _client
        .from('purchase_order_lines')
        .select()
        .eq('business_id', businessId);
    if (afterTs != null) {
      final ts = afterTs.toUtc().toIso8601String();
      filter = afterId != null
          ? filter.or('updated_at.gt.$ts,and(updated_at.eq.$ts,id.gt.$afterId)')
          : filter.gt('updated_at', ts);
    }
    final ordered =
        filter.order('updated_at', ascending: true).order('id', ascending: true);
    final res = limit != null ? await ordered.limit(limit) : await ordered;
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> upsertPurchaseOrderLine(Map<String, dynamic> row) async {
    await _client.from('purchase_order_lines').upsert(row);
  }

  Future<void> deletePurchaseOrderLine(String id) async {
    await _client.from('purchase_order_lines').delete().eq('id', id);
  }

  // ── Goods Receipts ──────────────────────────────────────────────────────────

  /// Incremental/paged pull (includes tombstones). Keyset (updated_at, id).
  Future<List<Map<String, dynamic>>> getGoodsReceiptsByBusiness(
    String businessId, {
    DateTime? afterTs,
    String? afterId,
    int? limit,
  }) async {
    var filter =
        _client.from('goods_receipts').select().eq('business_id', businessId);
    if (afterTs != null) {
      final ts = afterTs.toUtc().toIso8601String();
      filter = afterId != null
          ? filter.or('updated_at.gt.$ts,and(updated_at.eq.$ts,id.gt.$afterId)')
          : filter.gt('updated_at', ts);
    }
    final ordered =
        filter.order('updated_at', ascending: true).order('id', ascending: true);
    final res = limit != null ? await ordered.limit(limit) : await ordered;
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> upsertGoodsReceipt(Map<String, dynamic> row) async {
    await _client.from('goods_receipts').upsert(row);
  }

  /// Incremental/paged pull, keyset (updated_at, id). GR items have no
  /// soft-delete (append-only children of a receipt), so there is no tombstone
  /// to carry — delta here is purely a scalability change.
  Future<List<Map<String, dynamic>>> getGoodsReceiptItemsByBusiness(
    String businessId, {
    DateTime? afterTs,
    String? afterId,
    int? limit,
  }) async {
    var filter = _client
        .from('goods_receipt_items')
        .select()
        .eq('business_id', businessId);
    if (afterTs != null) {
      final ts = afterTs.toUtc().toIso8601String();
      filter = afterId != null
          ? filter.or('updated_at.gt.$ts,and(updated_at.eq.$ts,id.gt.$afterId)')
          : filter.gt('updated_at', ts);
    }
    final ordered =
        filter.order('updated_at', ascending: true).order('id', ascending: true);
    final res = limit != null ? await ordered.limit(limit) : await ordered;
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> upsertGoodsReceiptItem(Map<String, dynamic> row) async {
    await _client.from('goods_receipt_items').upsert(row);
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  /// Upserts the per-business approval threshold so the server-side RLS check
  /// can read it. [threshold] null clears the limit.
  Future<void> upsertApprovalThreshold(
    String businessId,
    double? threshold,
  ) async {
    await _client.from('procurement_settings').upsert({
      'business_id': businessId,
      'approval_threshold': threshold,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
