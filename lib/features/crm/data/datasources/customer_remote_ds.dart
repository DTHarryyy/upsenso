import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for the CRM `customers` table.
/// Schema is confirmed via CustomersDao.upsertFromServer and the
/// _syncCustomers implementation in SyncService (mirrors suppliers).
class CustomerRemoteDs {
  final SupabaseClient _client;

  CustomerRemoteDs(this._client);

  /// Incremental/paged pull. Includes soft-deleted rows so tombstones propagate
  /// to other devices via delta (filtering is_deleted here previously stranded
  /// deletes). Keyset ordered by (updated_at, id); omit cursor + limit for a
  /// full first-run pull.
  Future<List<Map<String, dynamic>>> getCustomersByBusiness(
    String businessId, {
    DateTime? afterTs,
    String? afterId,
    int? limit,
  }) async {
    var filter =
        _client.from('customers').select().eq('business_id', businessId);
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

  Future<void> upsertCustomer(Map<String, dynamic> row) async {
    await _client.from('customers').upsert(row);
  }
}
