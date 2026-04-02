import 'dart:convert';

/// Layer 3 — JSON Parser: Safely extracts JSON from LLM output.
///
/// Handles malformed responses by extracting the first valid JSON object
/// from the raw string. Never crashes — returns null on failure.
class AiJsonParser {
  /// Extract a JSON map from raw LLM output.
  /// Finds the first `{` to the matching `}` and parses it.
  /// Returns null if no valid JSON is found.
  static Map<String, dynamic>? extractJson(String raw) {
    try {
      final trimmed = raw.trim();

      // Try direct parse first (cleanest case)
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}

      // Find first { and matching }
      final startIdx = trimmed.indexOf('{');
      if (startIdx == -1) return null;

      int depth = 0;
      int? endIdx;
      for (int i = startIdx; i < trimmed.length; i++) {
        if (trimmed[i] == '{') depth++;
        if (trimmed[i] == '}') depth--;
        if (depth == 0) {
          endIdx = i;
          break;
        }
      }

      if (endIdx == null) return null;

      final jsonStr = trimmed.substring(startIdx, endIdx + 1);
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) return decoded;

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Clean common LLM artifacts before parsing.
  /// Removes markdown code fences, trailing text, etc.
  static String cleanRawOutput(String raw) {
    var cleaned = raw.trim();

    // Remove markdown code fences
    cleaned = cleaned.replaceAll(RegExp(r'```json\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'```\s*'), '');

    // Remove leading text before JSON
    final firstBrace = cleaned.indexOf('{');
    if (firstBrace > 0) {
      cleaned = cleaned.substring(firstBrace);
    }

    return cleaned.trim();
  }
}
