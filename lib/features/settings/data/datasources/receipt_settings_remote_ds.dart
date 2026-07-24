import 'dart:typed_data';
import 'package:pos/core/services/image_compressor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all Supabase I/O for receipt_settings.
/// Table: public.receipt_settings (1 row per business).
class ReceiptSettingsRemoteDs {
  final SupabaseClient _client;

  ReceiptSettingsRemoteDs(this._client);

  Future<void> upsert(Map<String, dynamic> payload) async {
    await _client.from('receipt_settings').upsert(payload);
  }

  Future<Map<String, dynamic>?> getByBusinessId(String businessId) async {
    final response = await _client
        .from('receipt_settings')
        .select()
        .eq('business_id', businessId)
        .maybeSingle();
    return response;
  }

  /// Upload logo to Supabase Storage.
  /// Returns the public URL or throws on error.
  Future<String> uploadLogo({
    required String businessId,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    // Validate MIME type — only images allowed
    if (!mimeType.startsWith('image/')) {
      throw Exception('Only image files are allowed for the logo.');
    }

    // Shrink on-device; logos may be transparent, so keep alpha (PNG) when present.
    final compressed = await ImageCompressor.compress(
      bytes,
      maxDimension: 512,
      quality: 85,
    );

    // Guard the compressed bytes — this is what actually gets stored.
    if (compressed.bytes.lengthInBytes > 2 * 1024 * 1024) {
      throw Exception('Logo must be smaller than 2 MB.');
    }

    // Keep the base name but match the extension/type to the encoded output.
    final dot = fileName.lastIndexOf('.');
    final baseName = dot > 0 ? fileName.substring(0, dot) : fileName;
    final path = 'receipt-logos/$businessId/$baseName${compressed.extension}';
    await _client.storage
        .from('business-logos')
        .uploadBinary(
          path,
          compressed.bytes,
          fileOptions: FileOptions(
            contentType: compressed.contentType,
            upsert: true,
          ),
        );
    return _client.storage.from('business-logos').getPublicUrl(path);
  }

  Future<void> deleteLogo(String businessId) async {
    final files = await _client.storage
        .from('business-logos')
        .list(path: 'receipt-logos/$businessId');
    final paths = files
        .map((f) => 'receipt-logos/$businessId/${f.name}')
        .toList();
    if (paths.isNotEmpty) {
      await _client.storage.from('business-logos').remove(paths);
    }
  }
}
