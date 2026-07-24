import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pos/core/services/image_compressor.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  ImageService(this._client);

  final SupabaseClient _client;
  final _picker = ImagePicker();

  /// Picks a product image and saves it to the local documents directory.
  /// Returns the absolute local file path, or null if cancelled/denied.
  /// The image is uploaded to Supabase Storage during the next sync.
  Future<String?> pickImageLocally({
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
    // Shrink on-device so both the local cache and the later sync upload are small.
    final compressed = await ImageCompressor.compress(bytes, maxDimension: 1024);

    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/product_images');
    await imagesDir.create(recursive: true);
    final localPath =
        '${imagesDir.path}/${const Uuid().v4()}${compressed.extension}';
    await File(localPath).writeAsBytes(compressed.bytes);

    return localPath;
  }

  /// Uploads a locally-saved image to Supabase Storage.
  /// Returns the public URL. Throws on network or storage error.
  Future<String> uploadLocalImageToStorage({
    required String localPath,
    required String businessId,
  }) async {
    final ext = p.extension(localPath).toLowerCase();
    final safeExt = ext.isNotEmpty ? ext : '.jpg';
    final storagePath = '$businessId/${const Uuid().v4()}$safeExt';
    final contentType = safeExt == '.png'
        ? 'image/png'
        : safeExt == '.webp'
        ? 'image/webp'
        : 'image/jpeg';

    final bytes = await File(localPath).readAsBytes();
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
