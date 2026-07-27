import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Re-encoded image bytes plus the storage content-type and file extension
/// that match them, so each caller can label the upload correctly.
class CompressedImage {
  const CompressedImage({
    required this.bytes,
    required this.contentType,
    required this.extension,
  });

  final Uint8List bytes;
  final String contentType;
  final String extension;
}

/// Downscales and re-encodes an image on-device before upload so Storage keeps a
/// small file instead of the multi-MB original. Pure Dart, so it works on every
/// target (including web, where `image_picker`'s own downscale is ignored).
///
/// It never throws: on any failure it returns the input untouched, because a lost
/// upload is worse than a large one.
class ImageCompressor {
  const ImageCompressor._();

  /// [maxDimension] caps the longest edge (never upscales). [preserveAlpha]
  /// keeps transparency by encoding PNG; set it false for photos (avatars) to
  /// force smaller JPEG output.
  static Future<CompressedImage> compress(
    Uint8List input, {
    required int maxDimension,
    int quality = 80,
    bool preserveAlpha = true,
  }) {
    // Off the UI thread on native; runs inline on web (no isolates there).
    return compute(
      _runCompress,
      _CompressParams(
        input: input,
        maxDimension: maxDimension,
        quality: quality,
        preserveAlpha: preserveAlpha,
      ),
    );
  }
}

class _CompressParams {
  const _CompressParams({
    required this.input,
    required this.maxDimension,
    required this.quality,
    required this.preserveAlpha,
  });

  final Uint8List input;
  final int maxDimension;
  final int quality;
  final bool preserveAlpha;
}

CompressedImage _runCompress(_CompressParams p) {
  try {
    final decoded = img.decodeImage(p.input);
    if (decoded == null) {
      // Unknown/undecodable format (e.g. a stray HEIC on web) — keep original.
      return _passthrough(p.input);
    }

    final longestEdge =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    final isLandscape = decoded.width >= decoded.height;
    final resized = longestEdge > p.maxDimension
        ? img.copyResize(
            decoded,
            width: isLandscape ? p.maxDimension : null,
            height: isLandscape ? null : p.maxDimension,
            interpolation: img.Interpolation.average,
          )
        : decoded;

    final keepAlpha = p.preserveAlpha && resized.hasAlpha;
    final bytes = keepAlpha
        ? img.encodePng(resized)
        : img.encodeJpg(resized, quality: p.quality);

    // Never make it worse: if re-encoding grew the file, keep the original.
    if (bytes.lengthInBytes >= p.input.lengthInBytes) {
      return _passthrough(p.input);
    }

    return keepAlpha
        ? CompressedImage(
            bytes: bytes,
            contentType: 'image/png',
            extension: '.png',
          )
        : CompressedImage(
            bytes: bytes,
            contentType: 'image/jpeg',
            extension: '.jpg',
          );
  } catch (e, st) {
    debugPrint('[ImageCompressor] Error in _runCompress: $e\n$st');
    return _passthrough(p.input);
  }
}

CompressedImage _passthrough(Uint8List input) {
  final (contentType, extension) = _sniffMime(input);
  return CompressedImage(
    bytes: input,
    contentType: contentType,
    extension: extension,
  );
}

/// Minimal magic-byte sniff so a passthrough still carries a sensible type.
(String, String) _sniffMime(Uint8List b) {
  if (b.length >= 4 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47) {
    return ('image/png', '.png');
  }
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
    return ('image/jpeg', '.jpg');
  }
  if (b.length >= 12 &&
      b[8] == 0x57 &&
      b[9] == 0x45 &&
      b[10] == 0x42 &&
      b[11] == 0x50) {
    return ('image/webp', '.webp');
  }
  return ('image/jpeg', '.jpg');
}
