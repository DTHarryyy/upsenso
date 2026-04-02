import 'package:flutter/foundation.dart';

/// Layer 1 — LLM Engine: Manages the on-device LLM model lifecycle.
///
/// Currently a **stub** — the on-device native inference backend
/// (llama_cpp_dart) is disabled because its pub package does not
/// ship the required llama.cpp C++ sources, causing Android CMake
/// builds to fail.
///
/// The full interface is preserved so it can be wired up later when
/// a working native backend is available. Until then the pipeline
/// falls through to the rule-based parser automatically.
class LlmEngine {
  bool _isLoaded = false;
  String? _lastError;

  bool get isLoaded => _isLoaded;
  bool get isLoading => false;
  String? get lastError => _lastError;

  /// Attempt to load a GGUF model.
  ///
  /// Always returns `false` while the native backend is disabled.
  Future<bool> loadModel(String modelPath) async {
    _lastError = 'Native LLM backend not available — using rule-based parser';
    debugPrint('LlmEngine: $_lastError');
    _isLoaded = false;
    return false;
  }

  /// Generate a response from the model. Returns `null` (model never loads).
  Future<String?> generate(String systemPrompt, String userMessage) async {
    return null;
  }

  Future<void> dispose() async {
    _isLoaded = false;
  }
}
