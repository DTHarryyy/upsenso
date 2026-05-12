import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  ImageService(this._client);

  final SupabaseClient _client;
  final _picker = ImagePicker();

  /// Picks a product image and uploads it to the `product-images` bucket.
  /// Path: `{businessId}/{uuid}.ext`
  /// Returns the public URL on success, null if cancelled or permission denied.
  Future<String?> pickAndUploadProductImage({
    required String businessId,
    ImageSource source = ImageSource.gallery,
  }) async {
    if (!kIsWeb && source == ImageSource.camera) {
      final granted = await _requestCameraPermission();
      if (!granted) return null;
    }

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final ext = p.extension(picked.path).toLowerCase();
    final safeExt = ext.isNotEmpty ? ext : '.jpg';
    final storagePath = '$businessId/${const Uuid().v4()}$safeExt';

    final contentType = safeExt == '.png' ? 'image/png'
        : safeExt == '.webp' ? 'image/webp'
        : 'image/jpeg';

    await _client.storage.from('product-images').uploadBinary(
      storagePath,
      Uint8List.fromList(bytes),
      fileOptions: FileOptions(upsert: true, contentType: contentType),
    );

    return _client.storage.from('product-images').getPublicUrl(storagePath);
  }

  Future<bool> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      status = await Permission.camera.status;
      return status.isGranted;
    }
    status = await Permission.camera.request();
    return status.isGranted;
  }
}
