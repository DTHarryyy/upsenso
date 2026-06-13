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

  Future<List<Map<String, dynamic>>> getSuppliersByBusiness(
    String businessId,
  ) async {
    return await _client
        .from('suppliers')
        .select()
        .eq('business_id', businessId)
        .eq('is_deleted', false);
  }

  Future<void> upsertSupplier(Map<String, dynamic> row) async {
    await _client.from('suppliers').upsert(row);
  }

  Future<void> deleteSupplier(String id) async {
    await _client.from('suppliers').delete().eq('id', id);
  }

  // ── Purchase Orders ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPurchaseOrdersByBusiness(
    String businessId,
  ) async {
    return await _client
        .from('purchase_orders')
        .select()
        .eq('business_id', businessId)
        .eq('is_deleted', false);
  }

  Future<void> upsertPurchaseOrder(Map<String, dynamic> row) async {
    await _client.from('purchase_orders').upsert(row);
  }

  Future<void> deletePurchaseOrder(String id) async {
    await _client.from('purchase_orders').delete().eq('id', id);
  }

  // ── Purchase Order Lines ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPurchaseOrderLinesByBusiness(
    String businessId,
  ) async {
    return await _client
        .from('purchase_order_lines')
        .select()
        .eq('business_id', businessId)
        .eq('is_deleted', false);
  }

  Future<void> upsertPurchaseOrderLine(Map<String, dynamic> row) async {
    await _client.from('purchase_order_lines').upsert(row);
  }

  Future<void> deletePurchaseOrderLine(String id) async {
    await _client.from('purchase_order_lines').delete().eq('id', id);
  }
}
