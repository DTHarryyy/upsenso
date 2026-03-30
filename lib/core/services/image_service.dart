import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

/// Picks a product image from the camera or gallery, copies it to the app's
/// permanent documents directory, and returns the stable local path.
/// For gallery: image_picker uses the system photo picker (no permission needed).
/// For camera: requests camera permission before opening.
/// Returns null if the user cancels or denies permission.
class ImageService {
  final _picker = ImagePicker();

  Future<String?> pickAndSaveImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    // Gallery uses the Android system photo picker — no permission required.
    // Only camera needs an explicit permission check.
    if (source == ImageSource.camera) {
      final granted = await _requestCameraPermission();
      if (!granted) return null;
    }

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final docsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(docsDir.path, 'product_images'));
    if (!imagesDir.existsSync()) {
      imagesDir.createSync(recursive: true);
    }

    final ext = p.extension(picked.path).isNotEmpty
        ? p.extension(picked.path)
        : '.jpg';
    final filename = '${const Uuid().v4()}$ext';
    final destPath = p.join(imagesDir.path, filename);

    await File(picked.path).copy(destPath);
    return destPath;
  }

  /// Requests camera permission.
  /// Opens app settings if permanently denied, then re-checks.
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
