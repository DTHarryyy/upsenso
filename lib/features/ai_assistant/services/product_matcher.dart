import 'dart:math';
import 'package:pos/features/ai_assistant/models/ai_models.dart';
import 'package:pos/features/ai_assistant/services/ai_tool_service.dart';

/// Layer 6 — Intelligence Layer: Fuzzy matching and name normalization.
///
/// Enhances AI output BEFORE execution by:
/// - Fuzzy matching product names (e.g., "coke" → "Coca-Cola 1.5L")
/// - Handling partial matches
/// - Normalizing item names
class ProductMatcher {
  /// Match parsed items against the product catalog.
  /// Returns matched products and unmatched names.
  static MatchResult matchItems({
    required List<AiParsedItem> parsedItems,
    required List<ProductWithVariant> catalog,
  }) {
    final matched = <AiMatchedProduct>[];
    final unmatched = <String>[];

    for (final item in parsedItems) {
      final best = _findBestMatch(item.name, catalog);
      if (best != null) {
        // Collect all active variants for this product
        final allVariants = catalog
            .where((pw) => pw.product.id == best.product.id)
            .map((pw) => AiVariantOption(
                  variantId: pw.variant.id,
                  variantName: pw.variant.name,
                  price: pw.variant.price,
                  stock: pw.variant.stock,
                  trackStock: pw.variant.trackStock,
                ))
            .toList();

        // Avoid duplicates — merge quantities if same variant
        final existingIdx = matched.indexWhere(
          (m) => m.variantId == best.variant.id,
        );
        if (existingIdx >= 0) {
          final existing = matched[existingIdx];
          matched[existingIdx] = AiMatchedProduct(
            productId: existing.productId,
            variantId: existing.variantId,
            productName: existing.productName,
            variantName: existing.variantName,
            unitPrice: existing.unitPrice,
            taxRate: existing.taxRate,
            quantity: existing.quantity + item.quantity,
            availableStock: existing.availableStock,
            trackStock: existing.trackStock,
            availableVariants: existing.availableVariants,
          );
        } else {
          matched.add(AiMatchedProduct(
            productId: best.product.id,
            variantId: best.variant.id,
            productName: best.product.name,
            variantName: best.variant.name,
            unitPrice: best.variant.price,
            taxRate: best.product.tax,
            quantity: item.quantity,
            availableStock: best.variant.stock,
            trackStock: best.variant.trackStock,
            availableVariants: allVariants,
          ));
        }
      } else {
        unmatched.add(item.name);
      }
    }

    return MatchResult(matched: matched, unmatched: unmatched);
  }

  /// Find the best matching product for a given name.
  /// Uses a combination of exact, contains, prefix, word, bigram, and
  /// Levenshtein distance matching to handle typos and shorthand.
  static ProductWithVariant? _findBestMatch(
    String query,
    List<ProductWithVariant> catalog,
  ) {
    if (catalog.isEmpty) return null;

    final queryLower = query.toLowerCase().trim();
    if (queryLower.isEmpty) return null;

    ProductWithVariant? bestMatch;
    double bestScore = 0;

    // Minimum threshold for acceptance (0.0 - 1.0)
    const double threshold = 0.35;

    for (final pw in catalog) {
      final productName = pw.product.name.toLowerCase();
      final variantName = pw.variant.name.toLowerCase();
      final fullName = '$productName $variantName'.trim();

      double score = 0;

      // Exact match on product name
      if (productName == queryLower) {
        score = 1.0;
      }
      // Exact match on full name (product + variant)
      else if (fullName == queryLower) {
        score = 0.98;
      }
      // Product name contains query (e.g., "coca-cola" contains "coca")
      else if (productName.contains(queryLower)) {
        score = 0.85;
      }
      // Query contains product name (e.g., "coca cola large" contains "coca cola")
      else if (queryLower.contains(productName)) {
        score = 0.8;
      }
      // Product name starts with query (e.g., "cok" → "coke")
      else if (productName.startsWith(queryLower) && queryLower.length >= 2) {
        score = 0.78;
      }
      // Query starts with product name (e.g., "cokes" starts with "coke")
      else if (queryLower.startsWith(productName) && productName.length >= 2) {
        score = 0.75;
      }
      // Any word in product name matches query
      else if (_anyWordMatches(productName, queryLower)) {
        score = 0.65;
      }
      // Bigram similarity — great for typos like "cokee", "coek", "sprit"
      else {
        final bigramScore = _bigramSimilarity(queryLower, productName);
        final levenScore = _levenshteinScore(queryLower, productName);
        // Take the better of the two fuzzy scores
        score = max(bigramScore, levenScore);
      }

      if (score > bestScore && score >= threshold) {
        bestScore = score;
        bestMatch = pw;
      }
    }

    return bestMatch;
  }

  static bool _anyWordMatches(String text, String query) {
    final words = text.split(RegExp(r'\s+'));
    for (final word in words) {
      if (word == query) return true;
      if (word.startsWith(query) && query.length >= 2) return true;
      if (query.startsWith(word) && word.length >= 2) return true;
    }
    return false;
  }

  /// Bigram (character pair) similarity — robust against transpositions
  /// and single-character typos.
  static double _bigramSimilarity(String a, String b) {
    if (a.length < 2 || b.length < 2) return 0;
    final bigramsA = _bigrams(a);
    final bigramsB = _bigrams(b);
    final intersection = bigramsA.intersection(bigramsB).length;
    final total = bigramsA.length + bigramsB.length;
    if (total == 0) return 0;
    return (2 * intersection) / total;
  }

  static Set<String> _bigrams(String s) {
    final set = <String>{};
    for (int i = 0; i < s.length - 1; i++) {
      set.add(s.substring(i, i + 2));
    }
    return set;
  }

  /// Levenshtein-based similarity score.
  static double _levenshteinScore(String a, String b) {
    final distance = _levenshteinDistance(a, b);
    final maxLen = max(a.length, b.length);
    if (maxLen == 0) return 0;
    return 1.0 - (distance / maxLen);
  }

  /// Levenshtein distance for fuzzy matching.
  static int _levenshteinDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final matrix = List.generate(
      a.length + 1,
      (_) => List.filled(b.length + 1, 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce(min);
      }
    }

    return matrix[a.length][b.length];
  }
}

/// Result of product matching.
class MatchResult {
  final List<AiMatchedProduct> matched;
  final List<String> unmatched;

  const MatchResult({required this.matched, required this.unmatched});
}
