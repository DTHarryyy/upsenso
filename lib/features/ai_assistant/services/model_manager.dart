import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos/features/ai_assistant/services/model_download_service.dart';

/// Manages model file discovery and location on the device.
///
/// Looks for GGUF model files in the app's documents directory under
/// a `models/` subfolder. If no model is found, can trigger an
/// automatic download via [ModelDownloadService].
///
/// Expected path: `<documents>/models/<filename>.gguf`
class ModelManager {
  static const String _modelsDir = 'models';

  /// Known filenames for Qwen 2.5 Instruct quantised models.
  static const List<String> _knownModelNames = [
    'qwen2.5-3b-instruct-q4_k_m.gguf',
    'qwen2.5-3b-instruct-q4_k_s.gguf',
    'qwen2.5-3b-instruct-q5_k_m.gguf',
    'qwen2.5-3b-instruct-q8_0.gguf',
    'qwen2.5-1.5b-instruct-q4_k_m.gguf',
    'qwen2.5-1.5b-instruct-q5_k_m.gguf',
    'qwen2.5-1.5b-instruct-q8_0.gguf',
  ];

  /// Get the path to the models directory.
  Future<Directory> getModelsDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final modelsPath = Directory('${docs.path}/$_modelsDir');
    if (!await modelsPath.exists()) {
      await modelsPath.create(recursive: true);
    }
    return modelsPath;
  }

  /// Scan the models directory and return the path of the first
  /// recognised GGUF model file found. Returns `null` if none found.
  Future<String?> findModelPath() async {
    try {
      final modelsDir = await getModelsDirectory();

      // First try the known filenames (preferred order)
      for (final name in _knownModelNames) {
        final file = File('${modelsDir.path}/$name');
        if (await file.exists()) {
          debugPrint('ModelManager: Found model at ${file.path}');
          return file.path;
        }
      }

      // Fallback: any .gguf file in the directory
      final files = await modelsDir
          .list()
          .where((e) => e is File && e.path.toLowerCase().endsWith('.gguf'))
          .cast<File>()
          .toList();

      if (files.isNotEmpty) {
        debugPrint('ModelManager: Found model at ${files.first.path}');
        return files.first.path;
      }

      debugPrint('ModelManager: No .gguf model found in ${modelsDir.path}');
      return null;
    } catch (e) {
      debugPrint('ModelManager: Error scanning for models: $e');
      return null;
    }
  }

  /// Check whether any model file is available on the device.
  Future<bool> isModelAvailable() async {
    final path = await findModelPath();
    return path != null;
  }

  /// Returns a user-facing description of where to place the model.
  Future<String> getModelDirectoryHint() async {
    final dir = await getModelsDirectory();
    return dir.path;
  }

  /// Check if a partial download exists (for resume).
  Future<bool> hasPartialDownload() async {
    final modelsDir = await getModelsDirectory();
    final partFile = File(
      '${modelsDir.path}/${ModelDownloadService.defaultModelFilename}.part',
    );
    return partFile.exists();
  }

  /// Get the size (in bytes) of any existing partial download.
  Future<int> partialDownloadSize() async {
    final modelsDir = await getModelsDirectory();
    final partFile = File(
      '${modelsDir.path}/${ModelDownloadService.defaultModelFilename}.part',
    );
    if (await partFile.exists()) return partFile.length();
    return 0;
  }
}
