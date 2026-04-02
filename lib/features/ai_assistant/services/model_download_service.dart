import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pos/features/ai_assistant/services/model_manager.dart';

/// Status of the model download.
enum ModelDownloadStatus {
  idle,
  downloading,
  completed,
  failed,
  cancelled,
}

/// Progress info emitted during download.
class ModelDownloadProgress {
  final ModelDownloadStatus status;
  final double progress; // 0.0 → 1.0
  final int bytesDownloaded;
  final int totalBytes;
  final String? error;

  const ModelDownloadProgress({
    required this.status,
    this.progress = 0.0,
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
    this.error,
  });

  String get downloadedMB => (bytesDownloaded / (1024 * 1024)).toStringAsFixed(1);
  String get totalMB => (totalBytes / (1024 * 1024)).toStringAsFixed(1);
  int get percentInt => (progress * 100).round();
}

/// Downloads the Qwen GGUF model from Hugging Face to the device.
///
/// Supports:
///  - Streaming download with progress reporting
///  - Pause / cancel
///  - Resume (if server supports Range header)
///  - Writes to a `.part` temp file; renames on completion
class ModelDownloadService {
  final ModelManager _modelManager;

  /// Default model: Qwen 2.5 1.5B Instruct Q4_K_M (~1 GB, practical for mobile)
  static const String defaultModelUrl =
      'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/'
      'qwen2.5-1.5b-instruct-q4_k_m.gguf';

  static const String defaultModelFilename =
      'qwen2.5-1.5b-instruct-q4_k_m.gguf';

  ModelDownloadService({required ModelManager modelManager})
      : _modelManager = modelManager;

  HttpClient? _httpClient;
  IOSink? _fileSink;
  bool _isCancelled = false;

  final _progressController =
      StreamController<ModelDownloadProgress>.broadcast();

  /// Stream of download progress updates.
  Stream<ModelDownloadProgress> get progressStream =>
      _progressController.stream;

  /// Start downloading the model.
  ///
  /// If a partial `.part` file exists and [resume] is true, attempts to
  /// resume from where it left off.
  Future<String?> downloadModel({
    String url = defaultModelUrl,
    String filename = defaultModelFilename,
    bool resume = true,
  }) async {
    _isCancelled = false;

    final modelsDir = await _modelManager.getModelsDirectory();
    final targetFile = File('${modelsDir.path}/$filename');
    final partFile = File('${modelsDir.path}/$filename.part');

    // Already downloaded?
    if (await targetFile.exists()) {
      _emitProgress(ModelDownloadStatus.completed, 1.0, 0, 0);
      return targetFile.path;
    }

    int existingBytes = 0;
    if (resume && await partFile.exists()) {
      existingBytes = await partFile.length();
      debugPrint('ModelDownload: Resuming from $existingBytes bytes');
    }

    _emitProgress(ModelDownloadStatus.downloading, 0.0, existingBytes, 0);

    try {
      _httpClient = HttpClient();
      // Follow redirects (Hugging Face uses them)
      _httpClient!.maxConnectionsPerHost = 1;

      final request = await _httpClient!.getUrl(Uri.parse(url));

      // Range header for resume
      if (existingBytes > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$existingBytes-');
      }

      final response = await request.close();

      // Handle redirect edge cases or errors
      if (response.statusCode != 200 && response.statusCode != 206) {
        final error = 'Server returned ${response.statusCode}';
        _emitProgress(ModelDownloadStatus.failed, 0.0, 0, 0, error: error);
        return null;
      }

      // Determine total size
      int totalBytes;
      if (response.statusCode == 206) {
        // Partial content — total = existing + remaining
        totalBytes = existingBytes + response.contentLength;
      } else {
        // Full response — start fresh
        totalBytes = response.contentLength;
        existingBytes = 0;
        // Truncate if we're not resuming
        if (await partFile.exists()) {
          await partFile.delete();
        }
      }

      int bytesReceived = existingBytes;
      _fileSink = partFile.openWrite(
        mode: existingBytes > 0 ? FileMode.append : FileMode.write,
      );

      await for (final chunk in response) {
        if (_isCancelled) {
          await _fileSink?.flush();
          await _fileSink?.close();
          _fileSink = null;
          _emitProgress(
            ModelDownloadStatus.cancelled,
            bytesReceived / totalBytes,
            bytesReceived,
            totalBytes,
          );
          return null;
        }

        _fileSink!.add(chunk);
        bytesReceived += chunk.length;

        final progress =
            totalBytes > 0 ? bytesReceived / totalBytes : 0.0;
        _emitProgress(
          ModelDownloadStatus.downloading,
          progress,
          bytesReceived,
          totalBytes,
        );
      }

      await _fileSink?.flush();
      await _fileSink?.close();
      _fileSink = null;

      // Rename .part → final file
      await partFile.rename(targetFile.path);

      _emitProgress(
        ModelDownloadStatus.completed,
        1.0,
        bytesReceived,
        totalBytes,
      );
      debugPrint('ModelDownload: Completed (${targetFile.path})');
      return targetFile.path;
    } catch (e) {
      await _fileSink?.flush();
      await _fileSink?.close();
      _fileSink = null;

      final error = e.toString();
      debugPrint('ModelDownload: Error — $error');
      _emitProgress(ModelDownloadStatus.failed, 0.0, 0, 0, error: error);
      return null;
    } finally {
      _httpClient?.close(force: _isCancelled);
      _httpClient = null;
    }
  }

  /// Cancel an in-progress download.
  /// The .part file is preserved so it can resume later.
  void cancel() {
    _isCancelled = true;
  }

  /// Delete any partial download file.
  Future<void> deletePartialDownload({
    String filename = defaultModelFilename,
  }) async {
    final modelsDir = await _modelManager.getModelsDirectory();
    final partFile = File('${modelsDir.path}/$filename.part');
    if (await partFile.exists()) {
      await partFile.delete();
    }
  }

  void _emitProgress(
    ModelDownloadStatus status,
    double progress,
    int bytesDownloaded,
    int totalBytes, {
    String? error,
  }) {
    _progressController.add(ModelDownloadProgress(
      status: status,
      progress: progress.clamp(0.0, 1.0),
      bytesDownloaded: bytesDownloaded,
      totalBytes: totalBytes,
      error: error,
    ));
  }

  void dispose() {
    cancel();
    _progressController.close();
  }
}
