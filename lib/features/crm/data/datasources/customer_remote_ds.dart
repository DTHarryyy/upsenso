import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for the CRM `customers` table.
/// Schema is confirmed via CustomersDao.upsertFromServer and the
/// _syncCustomers implementation in SyncService (mirrors suppliers).
class CustomerRemoteDs {
  final SupabaseClient _client;

  CustomerRemoteDs(this._client);

  Future<List<Map<String, dynamic>>> getCustomersByBusiness(
    String businessId,
  ) async {
    return await _client
        .from('customers')
        .select()
        .eq('business_id', businessId)
        .eq('is_deleted', false);
  }

  Future<void> upsertCustomer(Map<String, dynamic> row) async {
    await _client.from('customers').upsert(row);
  }
}
