import 'package:flutter/foundation.dart';
import 'package:nobodywho/nobodywho.dart' as nobodywho;

/// Layer 1 — LLM Engine: Manages the on-device LLM model lifecycle.
///
/// Powered by **nobodywho** (llama.cpp + Vulkan/Metal GPU acceleration).
/// Loads any GGUF model file and provides chat-based inference.
class LlmEngine {
  nobodywho.Chat? _chat;
  bool _isLoaded = false;
  bool _isLoading = false;
  String? _lastError;
  String? _loadedModelPath;

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  /// Load a GGUF model from [modelPath].
  ///
  /// Uses nobodywho's Chat API with Vulkan/Metal GPU acceleration.
  /// Returns `true` on success.
  Future<bool> loadModel(String modelPath) async {
    if (_isLoading) return false;
    if (_isLoaded && _loadedModelPath == modelPath) return true;

    _isLoading = true;
    _lastError = null;

    try {
      _chat = await nobodywho.Chat.fromPath(
        modelPath: modelPath,
        contextSize: 2048,
        useGpu: true,
      );
      _isLoaded = true;
      _loadedModelPath = modelPath;
      debugPrint('LlmEngine: Model loaded from $modelPath');
      return true;
    } catch (e) {
      _lastError = e.toString();
      _isLoaded = false;
      _chat = null;
      debugPrint('LlmEngine: Failed to load model: $_lastError');
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// Generate a response from the loaded model.
  ///
  /// Sets the [systemPrompt] and sends [userMessage], then waits for
  /// the complete response. Returns `null` if the model is not loaded
  /// or generation fails.
  Future<String?> generate(String systemPrompt, String userMessage) async {
    if (!_isLoaded || _chat == null) return null;

    try {
      // Reset context with the system prompt for each query to ensure
      // fresh state — our use case is single-turn intent parsing.
      await _chat!.setChatHistory([
        nobodywho.Message.message(
          role: nobodywho.Role.system,
          content: systemPrompt,
        ),
      ]);

      final response = await _chat!.ask(userMessage).completed();
      return response;
    } catch (e) {
      debugPrint('LlmEngine: Generation error: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    _chat = null;
    _isLoaded = false;
    _loadedModelPath = null;
  }
}
