import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pos/core/services/image_compressor.dart';

/// Builds a random-noise image (deterministic seed) so it is genuinely large and
/// poorly compressible — tests then exercise real re-encoding, not a trivial fill.
Uint8List _noisePng(int w, int h, {bool alpha = false}) {
  final rng = Random(42);
  final image = img.Image(width: w, height: h, numChannels: alpha ? 4 : 3);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final r = rng.nextInt(256);
      final g = rng.nextInt(256);
      final b = rng.nextInt(256);
      if (alpha) {
        image.setPixelRgba(x, y, r, g, b, rng.nextInt(256));
      } else {
        image.setPixelRgb(x, y, r, g, b);
      }
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

int _longestEdge(Uint8List bytes) {
  final decoded = img.decodeImage(bytes)!;
  return decoded.width > decoded.height ? decoded.width : decoded.height;
}

void main() {
  group('ImageCompressor.compress', () {
    test('downscales and re-encodes a large opaque image to JPEG', () async {
      final input = _noisePng(900, 600);
      final result = await ImageCompressor.compress(input, maxDimension: 512);

      expect(_longestEdge(result.bytes), lessThanOrEqualTo(512));
      expect(result.bytes.length, lessThan(input.length));
      expect(result.contentType, 'image/jpeg');
      expect(result.extension, '.jpg');
    });

    test('keeps transparency as PNG when preserveAlpha is true', () async {
      final input = _noisePng(800, 800, alpha: true);
      final result = await ImageCompressor.compress(
        input,
        maxDimension: 512,
        preserveAlpha: true,
      );

      expect(result.contentType, 'image/png');
      expect(_longestEdge(result.bytes), lessThanOrEqualTo(512));
      expect(img.decodeImage(result.bytes)!.hasAlpha, isTrue);
    });

    test('does not upscale an image already under the cap', () async {
      final input = _noisePng(100, 100);
      final result = await ImageCompressor.compress(input, maxDimension: 512);

      final decoded = img.decodeImage(result.bytes)!;
      expect(decoded.width, 100);
      expect(decoded.height, 100);
      expect(result.bytes.length, lessThanOrEqualTo(input.length));
    });

    test('returns the input untouched for undecodable bytes', () async {
      final garbage = Uint8List.fromList(
        List<int>.generate(64, (i) => (i * 7) % 256),
      );
      final result = await ImageCompressor.compress(garbage, maxDimension: 512);

      expect(result.bytes, equals(garbage));
    });
  });
}
