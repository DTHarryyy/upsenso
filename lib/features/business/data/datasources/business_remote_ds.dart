import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessRemoteDs {
  final SupabaseClient client;
  BusinessRemoteDs(this.client);

  /// Fetch all business templates
  Future<List<Map<String, dynamic>>> getBusinessTemplates() async {
    final response = await client
        .from('business_templates')
        .select()
        .order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a new business
  Future<Map<String, dynamic>> createBusiness({
    required String name,
    required String ownerId,
    required String templateId,
  }) async {
    final response = await client
        .from('businesses')
        .insert({
          'name': name,
          'owner_id': ownerId,
          'template_id': templateId,
          'is_active': true,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  /// Get business by owner ID
  Future<Map<String, dynamic>?> getBusinessByOwner(String ownerId) async {
    final response = await client
        .from('businesses')
        .select()
        .eq('owner_id', ownerId)
        .maybeSingle();

    return response != null ? Map<String, dynamic>.from(response) : null;
  }

  /// Get business by ID
  Future<Map<String, dynamic>?> getBusinessById(String businessId) async {
    final response = await client
        .from('businesses')
        .select()
        .eq('id', businessId)
        .maybeSingle();

    return response != null ? Map<String, dynamic>.from(response) : null;
  }
}
