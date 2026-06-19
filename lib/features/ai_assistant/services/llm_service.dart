import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pos/features/ai_assistant/services/llm_engine.dart';
import 'package:pos/features/ai_assistant/services/model_manager.dart';

/// Layer 2 — LLM Service: Converts user input into structured JSON.
///
/// Hybrid strategy:
///   1. If the on-device Qwen model is loaded → format a ChatML prompt,
///      run inference via [LlmEngine], parse the JSON output.
///   2. If inference fails (timeout / malformed output) → retry once.
///   3. If the model is not available → fall back to the rule-based parser.
class LlmService {
  final LlmEngine _engine;
  final ModelManager _modelManager;

  LlmService({
    required LlmEngine engine,
    required ModelManager modelManager,
  })  : _engine = engine,
        _modelManager = modelManager;

  bool get isModelLoaded => _engine.isLoaded;

  /// System prompt instructs the LLM to ONLY return structured JSON.
  static const String _systemPrompt = '''You are a POS AI Intent Parser for a business system.
You MUST NOT answer questions. You MUST NOT calculate or explain anything.
You MUST ONLY return JSON.

Convert user input into a structured query for a local database.

OUTPUT FORMAT (STRICT):
{"action":"GET_SALES|GET_EXPENSES|GET_SALES_BY_CATEGORY|GET_SALES_BY_PRODUCT|GET_PRODUCT_COUNT|GET_ACTIVE_PRODUCTS|GET_PRODUCTS_WITHOUT_SALES|GET_TRANSACTION_COUNT|CREATE_TRANSACTION|UNKNOWN","filters":{"date":{"type":"today|specific|range|none","value":"YYYY-MM-DD|null","start":"YYYY-MM-DD|null","end":"YYYY-MM-DD|null"},"category":"string|null","product":"string|null"},"aggregation":{"type":"total|highest|lowest|per_category|per_product"},"items":[{"name":"string","quantity":number}]}

INTENT DETECTION:
- "sales","revenue","income","earnings" → GET_SALES
- "expenses","cost","spending" → GET_EXPENSES
- "sales per category","by category" → GET_SALES_BY_CATEGORY
- "sales per product","by product" → GET_SALES_BY_PRODUCT
- "how many products","product count" → GET_PRODUCT_COUNT
- "active products","available items" → GET_ACTIVE_PRODUCTS
- "products without sales","unsold","not sold" → GET_PRODUCTS_WITHOUT_SALES
- "transactions","orders count" → GET_TRANSACTION_COUNT
- "buy","sell", item lists → CREATE_TRANSACTION
- If unclear → UNKNOWN

CRITICAL — PRODUCT & CATEGORY EXTRACTION:
- GROUP names (beverages,snacks,food,drinks) → category filter
- ANY OTHER NOUN that is NOT a group = product filter (coke,sprite,biscuits,rice,chicken,water,etc.)
- ALWAYS extract the product/category name from the query. NEVER leave product as null when a specific item is mentioned.

SCOPE EXAMPLES:
- "sales of beverages" → category="beverages", product=null
- "sales of coke" → product="coke", category=null
- "show product coke sales" → product="coke", category=null
- "coke sales today" → product="coke", date.type="today"
- "sales of coke in beverages" → product="coke", category="beverages"
Priority: Product > Category > General

RANKING / AGGREGATION:
- "highest","top","most","best selling" → type: "highest"
- "lowest","least","bottom","worst selling" → type: "lowest"
- "per category" → type: "per_category"
- "per product" → type: "per_product"
- default → type: "total"

DATE UNDERSTANDING:
- "today" → {"type":"today"}
- "yesterday" → {"type":"specific","value":"<YYYY-MM-DD>"}
- specific date → convert to YYYY-MM-DD
- "last week","this month" → {"type":"range","start":"YYYY-MM-DD","end":"YYYY-MM-DD"}
- If no date → "type":"none"

ITEMS (CREATE_TRANSACTION only): extract product names and quantities. Default quantity=1.
Users may glue quantity and name together. Separate them:
- "2coke" → {"name":"coke","quantity":2}
- "coke2" → {"name":"coke","quantity":2}
- "3xcoke" → {"name":"coke","quantity":3}
- "cok" (typo for "coke") → {"name":"cok","quantity":1} (keep as-is, matching layer handles typos)
CATEGORY: extract only if explicitly mentioned; otherwise null.
PRODUCT: extract only if a specific product name is mentioned; otherwise null.

FEW-SHOT EXAMPLES:
User: "show product coke sales"
{"action":"GET_SALES","filters":{"date":{"type":"none","value":null,"start":null,"end":null},"category":null,"product":"coke"},"aggregation":{"type":"total"},"items":[]}

User: "sales of sprite today"
{"action":"GET_SALES","filters":{"date":{"type":"today","value":null,"start":null,"end":null},"category":null,"product":"sprite"},"aggregation":{"type":"total"},"items":[]}

User: "beverages sales this week"
{"action":"GET_SALES_BY_CATEGORY","filters":{"date":{"type":"range","value":null,"start":"2026-03-27","end":"2026-04-02"},"category":"beverages","product":null},"aggregation":{"type":"total"},"items":[]}

User: "top selling product"
{"action":"GET_SALES_BY_PRODUCT","filters":{"date":{"type":"none","value":null,"start":null,"end":null},"category":null,"product":null},"aggregation":{"type":"highest"},"items":[]}

User: "buy coke 2pcs and sprite"
{"action":"CREATE_TRANSACTION","filters":{"date":{"type":"none","value":null,"start":null,"end":null},"category":null,"product":null},"aggregation":{"type":"total"},"items":[{"name":"coke","quantity":2},{"name":"sprite","quantity":1}]}

User: "3 burger and fries 2pcs"
{"action":"CREATE_TRANSACTION","filters":{"date":{"type":"none","value":null,"start":null,"end":null},"category":null,"product":null},"aggregation":{"type":"total"},"items":[{"name":"burger","quantity":3},{"name":"fries","quantity":2}]}

Return ONLY valid JSON. No explanation. No markdown. No extra text.''';

  /// Try to locate and load the on-device GGUF model.
  /// Returns true if the model loaded successfully.
  Future<bool> initialize() async {
    try {
      final modelPath = await _modelManager.findModelPath();
      if (modelPath == null) {
        debugPrint('LlmService: No model file found — using rule-based parser');
        return false;
      }

      final loaded = await _engine.loadModel(modelPath);
      if (loaded) {
        debugPrint('LlmService: Qwen model loaded — using LLM inference');
      } else {
        debugPrint(
          'LlmService: Model load failed (${_engine.lastError}) — using rule-based parser',
        );
      }
      return loaded;
    } catch (e, st) {
      debugPrint('LlmService: Initialization error: $e\n$st');
      return false;
    }
  }

  /// Send a user message and get structured JSON back.
  /// Uses the on-device LLM if available, otherwise the rule-based fallback.
  Future<String> generateResponse(String userMessage) async {
    if (_engine.isLoaded) {
      final result = await _generateFromModel(userMessage);
      if (result != null && _isValidJson(result)) return result;

      // Retry once — LLM output may have been truncated
      debugPrint('LlmService: First LLM attempt failed, retrying …');
      final retry = await _generateFromModel(userMessage);
      if (retry != null && _isValidJson(retry)) return retry;

      debugPrint('LlmService: LLM retry failed — falling back to rules');
    }
    return _ruleBasedParse(userMessage);
  }

  /// Run inference through the LLM engine.
  Future<String?> _generateFromModel(String userMessage) async {
    final raw = await _engine.generate(_systemPrompt, userMessage);
    if (raw == null || raw.trim().isEmpty) return null;

    // Strip any trailing <|im_end|> token the model may append
    final cleaned = raw.replaceAll('<|im_end|>', '').trim();
    return cleaned;
  }

  bool _isValidJson(String text) {
    try {
      final decoded = jsonDecode(text);
      return decoded is Map && decoded.containsKey('action');
    } catch (_) {
      return false;
    }
  }

  // ─── RULE-BASED PARSER ────────────────────────────────────────────────

  /// Rule-based fallback parser that produces the same JSON as the LLM.
  String _ruleBasedParse(String userMessage) {
    final lower = _normalizeInput(userMessage.toLowerCase().trim());

    // ── Detect action ─────────────────────────────────────────────
    final action = _detectAction(lower);

    // ── Detect date filter ────────────────────────────────────────
    final dateFilter = _detectDate(lower);

    // ── Detect category and product ───────────────────────────────
    final category = _detectCategory(lower);
    final product = _detectProduct(lower);

    // ── Detect aggregation type ───────────────────────────────────
    final aggregation = _detectAggregation(lower, action);

    // ── Parse items (only for CREATE_TRANSACTION) ─────────────────
    List<Map<String, dynamic>> items = [];
    if (action == 'CREATE_TRANSACTION') {
      items = _parseItemsFromText(lower);
      // If we detected CREATE_TRANSACTION but couldn't parse items,
      // fall back to UNKNOWN
      if (items.isEmpty) {
        return _buildJson('UNKNOWN', dateFilter, null, null, 'total', []);
      }
    }

    return _buildJson(action, dateFilter, category, product, aggregation, items);
  }

  String _buildJson(
    String action,
    Map<String, dynamic> dateFilter,
    String? category,
    String? product,
    String aggregation,
    List<Map<String, dynamic>> items,
  ) {
    return jsonEncode({
      'action': action,
      'filters': {
        'date': dateFilter,
        'category': category,
        'product': product,
      },
      'aggregation': {
        'type': aggregation,
      },
      'items': items,
    });
  }

  /// Detect the primary action from user input.
  String _detectAction(String lower) {
    // Sales by category — flexible: "by category" or "per category" anywhere
    // combined with any sales keyword (handles "sales today by category" etc.)
    if (_matches(lower, ['by category', 'per category']) &&
        _matches(lower, ['sales', 'revenue', 'income', 'earnings'])) {
      return 'GET_SALES_BY_CATEGORY';
    }

    // Ranking by category (e.g. "highest selling category")
    if (_matches(lower, ['selling category', 'category sales'])) {
      return 'GET_SALES_BY_CATEGORY';
    }

    // Sales by product — flexible: "by product" or "per product" anywhere
    if (_matches(lower, ['by product', 'per product']) &&
        _matches(lower, ['sales', 'revenue', 'income', 'earnings'])) {
      return 'GET_SALES_BY_PRODUCT';
    }

    // Ranking by product (e.g. "top selling product", "best selling")
    if (_matches(lower, [
      'selling product', 'product sales',
      'top selling', 'best selling', 'most sold',
      'worst selling', 'least sold',
    ])) {
      return 'GET_SALES_BY_PRODUCT';
    }

    // Expenses
    if (_matches(lower, ['expense', 'expenses', 'cost', 'spending', 'costs'])) {
      return 'GET_EXPENSES';
    }

    // Active products
    if (_matches(lower, [
      'active products', 'available products', 'available items',
      'products in stock', 'items in stock',
    ])) {
      return 'GET_ACTIVE_PRODUCTS';
    }

    // Product count
    if (_matches(lower, [
      'how many products', 'product count', 'total products',
      'number of products', 'products count', 'count products',
    ])) {
      return 'GET_PRODUCT_COUNT';
    }

    // Products without sales
    if (_matches(lower, [
      'without sales', 'no sales', 'zero sales', 'unsold',
      'not sold', 'not selling', 'never sold',
      'don\'t have sales', 'dont have sales',
      'have no sales', 'has no sales',
      'products that don\'t', 'products that dont',
      'items that don\'t', 'items that dont',
      'products with no', 'items with no',
      'products with zero', 'items with zero',
    ])) {
      return 'GET_PRODUCTS_WITHOUT_SALES';
    }

    // Transaction count
    if (_matches(lower, [
      'how many transactions', 'transaction count', 'total transactions',
      'number of transactions', 'transactions today', 'orders count',
      'how many orders', 'number of orders',
    ])) {
      return 'GET_TRANSACTION_COUNT';
    }

    // Sales (generic — checked after more specific sales queries)
    if (_matches(lower, [
      'sales', 'total sales', 'how much', 'revenue', 'income',
      "today's sales", 'earnings', 'how much did i make',
      'how much did i sell', 'how much did we make',
    ])) {
      return 'GET_SALES';
    }

    // Transaction creation
    if (_looksLikeTransaction(lower)) {
      return 'CREATE_TRANSACTION';
    }

    return 'UNKNOWN';
  }

  /// Check if input looks like a transaction (item list).
  bool _looksLikeTransaction(String lower) {
    // Skip questions
    if (lower.startsWith('how') ||
        lower.startsWith('what') ||
        lower.startsWith('when') ||
        lower.startsWith('why') ||
        lower.startsWith('where') ||
        lower.contains('?')) {
      return false;
    }

    // Has explicit transaction keywords
    if (_matches(lower, ['buy', 'sell', 'add to cart', 'ring up', 'checkout'])) {
      return true;
    }

    // Has quantity + word pattern (e.g. "2 coke", "3x coke")
    if (RegExp(r'\d+\s*(?:x|pcs|pc|pieces?)?\s+\w+').hasMatch(lower)) return true;

    // Has word + quantity pattern (e.g. "coke 2", "lol 2pcs")
    if (RegExp(r'[a-zA-Z]+\s+\d+').hasMatch(lower)) return true;

    // Has comma-separated words that aren't questions
    if (lower.contains(',') && !lower.contains('?')) return true;

    return false;
  }

  /// Detect date references and build the date filter map.
  Map<String, dynamic> _detectDate(String lower) {
    final now = DateTime.now();

    // Today
    if (lower.contains('today') || lower.contains("today's")) {
      return {'type': 'today', 'value': null, 'start': null, 'end': null};
    }

    // Yesterday
    if (lower.contains('yesterday')) {
      final yesterday = now.subtract(const Duration(days: 1));
      return {
        'type': 'specific',
        'value': _fmtDate(yesterday),
        'start': null,
        'end': null,
      };
    }

    // Last week
    if (lower.contains('last week')) {
      final end = now;
      final start = now.subtract(const Duration(days: 7));
      return {
        'type': 'range',
        'value': null,
        'start': _fmtDate(start),
        'end': _fmtDate(end),
      };
    }

    // This week
    if (lower.contains('this week')) {
      // Start of this week (Monday)
      final weekday = now.weekday; // 1 = Monday
      final start = now.subtract(Duration(days: weekday - 1));
      return {
        'type': 'range',
        'value': null,
        'start': _fmtDate(start),
        'end': _fmtDate(now),
      };
    }

    // This month
    if (lower.contains('this month')) {
      final start = DateTime(now.year, now.month, 1);
      return {
        'type': 'range',
        'value': null,
        'start': _fmtDate(start),
        'end': _fmtDate(now),
      };
    }

    // Last month
    if (lower.contains('last month')) {
      final start = DateTime(now.year, now.month - 1, 1);
      final end = DateTime(now.year, now.month, 0); // last day of prev month
      return {
        'type': 'range',
        'value': null,
        'start': _fmtDate(start),
        'end': _fmtDate(end),
      };
    }

    // Try to extract a specific date like "March 10" or "Jan 5"
    final specificDate = _tryParseNamedDate(lower, now);
    if (specificDate != null) {
      return {
        'type': 'specific',
        'value': _fmtDate(specificDate),
        'start': null,
        'end': null,
      };
    }

    return {'type': 'none', 'value': null, 'start': null, 'end': null};
  }

  /// Try to parse a named date like "March 10", "Jan 5", "December 25".
  DateTime? _tryParseNamedDate(String lower, DateTime now) {
    final months = {
      'january': 1, 'jan': 1,
      'february': 2, 'feb': 2,
      'march': 3, 'mar': 3,
      'april': 4, 'apr': 4,
      'may': 5,
      'june': 6, 'jun': 6,
      'july': 7, 'jul': 7,
      'august': 8, 'aug': 8,
      'september': 9, 'sep': 9, 'sept': 9,
      'october': 10, 'oct': 10,
      'november': 11, 'nov': 11,
      'december': 12, 'dec': 12,
    };

    for (final entry in months.entries) {
      final pattern = RegExp('${entry.key}\\s+(\\d{1,2})');
      final match = pattern.firstMatch(lower);
      if (match != null) {
        final day = int.tryParse(match.group(1)!);
        if (day != null && day >= 1 && day <= 31) {
          return DateTime(now.year, entry.value, day);
        }
      }
    }

    return null;
  }

  /// Detect an explicitly mentioned category name.
  /// Categories are GROUP names: beverages, snacks, food, drinks, etc.
  String? _detectCategory(String lower) {
    // If asking for a breakdown (per/by category), no specific category filter
    if (lower.contains('per category') || lower.contains('by category')) {
      return null;
    }
    // If asking for a breakdown (per/by product), no specific category filter
    if (lower.contains('per product') || lower.contains('by product')) {
      return null;
    }

    // "in <category>" pattern (e.g. "sales of coke in beverages")
    final inMatch = RegExp(
      r'\bin\s+([\w\s]+?)(?:\s+(?:today|yesterday|this|last|$))',
    ).firstMatch(lower);
    if (inMatch != null) {
      final candidate = _cleanCandidate(inMatch.group(1)!.trim());
      if (candidate != null) return candidate;
    }

    // "<name> category" pattern — only capture 1-3 words directly before
    final catMatch = RegExp(r'(\w+(?:\s+\w+){0,2})\s+category').firstMatch(lower);
    if (catMatch != null) {
      final candidate = _cleanCandidate(catMatch.group(1)!.trim());
      if (candidate != null) return candidate;
    }

    // "of <category>" / "for <category>" (only if not product-scoped)
    if (!_isProductScoped(lower)) {
      final ofMatch = RegExp(
        r'(?:of|for)\s+([\w\s]+?)(?:\s+(?:today|yesterday|this|last|$))',
      ).firstMatch(lower);
      if (ofMatch != null) {
        final candidate = _cleanCandidate(ofMatch.group(1)!.trim());
        if (candidate != null) return candidate;
      }
    }

    return null;
  }

  /// Clean a candidate name by stripping skip/action/ranking words.
  /// Returns null if nothing meaningful remains.
  String? _cleanCandidate(String raw) {
    final words = raw.split(RegExp(r'\s+'));
    final cleaned = words.where((w) {
      return !_isDateOrActionWord(w) && !_isRankingWord(w) && !_isFilterWord(w);
    }).join(' ').trim();
    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  bool _isFilterWord(String word) {
    const skip = {'by', 'per', 'of', 'for', 'in', 'and', 'or', 'with', 'from'};
    return skip.contains(word.toLowerCase());
  }

  /// Detect a specific product name mentioned in the input.
  /// Products are SPECIFIC ITEM names: coke, sprite, biscuits, etc.
  String? _detectProduct(String lower) {
    // Skip if asking for breakdown
    if (lower.contains('per product') || lower.contains('by product') ||
        lower.contains('per category') || lower.contains('by category')) {
      return null;
    }

    // "of <product>" pattern when it looks product-scoped
    if (_isProductScoped(lower)) {
      final ofMatch = RegExp(
        r'(?:of|for)\s+([\w\s.]+?)(?:\s+(?:today|yesterday|this|last|in|$))',
      ).firstMatch(lower);
      if (ofMatch != null) {
        final candidate = _cleanCandidate(ofMatch.group(1)!.trim());
        if (candidate != null) return candidate;
      }
    }

    return null;
  }

  /// Check if the input is scoped to a specific product rather than a category.
  /// This is a heuristic: if the subject after "of/for" doesn't look like a
  /// common category group name, treat it as a product.
  bool _isProductScoped(String lower) {
    final ofMatch = RegExp(
      r'(?:of|for)\s+([\w\s.]+?)(?:\s+(?:today|yesterday|this|last|in|$))',
    ).firstMatch(lower);
    if (ofMatch == null) return false;

    final candidate = ofMatch.group(1)!.trim().toLowerCase();
    // Common category group names
    const categoryWords = {
      'beverages', 'beverage', 'snacks', 'snack', 'food', 'foods',
      'drinks', 'drink', 'grocery', 'groceries', 'dairy', 'meat',
      'produce', 'bakery', 'frozen', 'canned', 'condiments',
      'electronics', 'household', 'cleaning', 'personal care',
      'medicine', 'medicines', 'health', 'beauty', 'stationery',
      'clothing', 'accessories', 'toys', 'supplies',
    };
    // If the candidate is a known category word, it's NOT product-scoped
    if (categoryWords.contains(candidate)) return false;

    // Otherwise, treat as product-scoped
    return true;
  }

  /// Detect ranking/aggregation type from user input.
  String _detectAggregation(String lower, String action) {
    // Highest / top / best
    if (_matches(lower, [
      'highest', 'top', 'most', 'best selling', 'best-selling',
    ])) {
      return 'highest';
    }

    // Lowest / bottom / worst
    if (_matches(lower, [
      'lowest', 'least', 'bottom', 'worst selling', 'worst-selling',
    ])) {
      return 'lowest';
    }

    // Per-category / per-product based on action
    if (action == 'GET_SALES_BY_CATEGORY') return 'per_category';
    if (action == 'GET_SALES_BY_PRODUCT') return 'per_product';

    return 'total';
  }

  bool _isDateOrActionWord(String word) {
    const skip = {
      'today', 'yesterday', 'this', 'last', 'week', 'month',
      'sales', 'revenue', 'income', 'expenses', 'products',
      'transactions', 'how', 'much', 'many', 'my', 'the',
    };
    return skip.contains(word.toLowerCase());
  }

  bool _isRankingWord(String word) {
    const ranking = {
      'highest', 'lowest', 'top', 'bottom', 'most', 'least',
      'best', 'worst', 'selling',
    };
    return ranking.contains(word.toLowerCase());
  }

  bool _matches(String input, List<String> keywords) {
    for (final kw in keywords) {
      if (input.contains(kw)) return true;
    }
    return false;
  }

  // ─── TYPO CORRECTION ──────────────────────────────────────────────────

  /// All vocabulary words that matter for intent detection.
  static const Set<String> _vocabulary = {
    // Actions
    'sales', 'sale', 'revenue', 'income', 'earnings', 'expenses', 'expense',
    'cost', 'costs', 'spending', 'products', 'product', 'items', 'item',
    'transactions', 'transaction', 'orders', 'order', 'active', 'available',
    'count', 'total', 'number',
    // Structure
    'by', 'per', 'category', 'of', 'for', 'in', 'from', 'with', 'without',
    // Dates
    'today', 'yesterday', 'week', 'month', 'this', 'last',
    // Questions
    'what', 'how', 'much', 'many', 'are', 'is', 'my', 'the', 'do', 'does',
    'did', 'have', 'has', 'show', 'get', 'give', 'me', 'list',
    // Ranking
    'highest', 'lowest', 'top', 'bottom', 'most', 'least', 'best', 'worst',
    'selling',
    // Transactions
    'buy', 'sell', 'checkout', 'ring', 'add', 'cart',
    // Negation / zero
    'no', 'not', 'zero', 'unsold', 'never', 'sold', 'don\'t', 'dont',
    'that',
  };

  /// Normalize user input: fix typos word-by-word using edit distance.
  String _normalizeInput(String input) {
    // Collapse multiple spaces
    var normalized = input.replaceAll(RegExp(r'\s+'), ' ').trim();

    final words = normalized.split(' ');
    final corrected = words.map((w) {
      if (w.length < 2) return w;
      if (_vocabulary.contains(w)) return w;

      // Find closest vocabulary word within edit distance threshold
      String? bestMatch;
      int bestDist = _maxEditDist(w.length) + 1;

      for (final vocab in _vocabulary) {
        // Quick length check — skip obviously different lengths
        if ((vocab.length - w.length).abs() > 2) continue;

        final dist = _editDistance(w, vocab);
        if (dist < bestDist) {
          bestDist = dist;
          bestMatch = vocab;
        }
      }

      return bestMatch ?? w;
    }).toList();

    return corrected.join(' ');
  }

  /// Max allowed edit distance based on word length.
  static int _maxEditDist(int len) {
    if (len <= 3) return 1;
    if (len <= 5) return 1;
    return 2;
  }

  /// Compute Levenshtein edit distance between two strings.
  static int _editDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    // Use two-row optimization for memory efficiency
    final la = a.length;
    final lb = b.length;
    var prev = List<int>.generate(lb + 1, (i) => i);
    var curr = List<int>.filled(lb + 1, 0);

    for (var i = 1; i <= la; i++) {
      curr[0] = i;
      for (var j = 1; j <= lb; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [
          prev[j] + 1,       // deletion
          curr[j - 1] + 1,   // insertion
          prev[j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }

    return prev[lb];
  }

  /// Parse item names and quantities from natural language text.
  /// Handles: "2 coke, 3 chips", "coke 1.5L, biscuits", "1 coke and 2 bread"
  List<Map<String, dynamic>> _parseItemsFromText(String text) {
    // Strip transaction trigger words
    var cleaned = text
        .replaceAll(RegExp(r'\b(buy|sell|add|ring up|checkout|i want|give me)\b'), '')
        .trim();

    // Split by comma, "and", "&"
    final segments = cleaned
        .replaceAll(' and ', ',')
        .replaceAll(' & ', ',')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (segments.isEmpty) return [];

    final items = <Map<String, dynamic>>[];
    for (final segment in segments) {
      items.addAll(_parseSegment(segment));
    }
    return items;
  }

  /// Parse a single segment into one or more items using token scanning.
  /// Handles: "2 coke", "coke 2", "coke 2pcs", "3x coke", "coke x3",
  /// "2coke", "coke2", and multi-item without separators:
  /// "lol 2 lol 2pcs", "coke 2 sprite 3".
  List<Map<String, dynamic>> _parseSegment(String segment) {
    // Pre-process: split glued qty+name and name+qty tokens.
    // "2coke" → "2 coke", "coke2" → "coke 2", "3xcoke" → "3x coke"
    final expanded = segment.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)(x?)([a-zA-Z]\w*)', caseSensitive: false),
      (m) => '${m.group(1)}${m.group(2)} ${m.group(3)}',
    ).replaceAllMapped(
      RegExp(r'([a-zA-Z]\w*)(\d+(?:\.\d+)?(?:pcs|pc|pieces?|x)?)', caseSensitive: false),
      (m) => '${m.group(1)} ${m.group(2)}',
    );

    final tokens = expanded.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final items = <Map<String, dynamic>>[];

    int i = 0;
    while (i < tokens.length) {
      final qty = _extractQty(tokens[i]);

      if (qty != null) {
        // QTY-FIRST: collect following name tokens until next qty
        i++;
        final nameTokens = <String>[];
        while (i < tokens.length &&
            _extractQty(tokens[i]) == null &&
            !_isStopWord(tokens[i])) {
          nameTokens.add(tokens[i]);
          i++;
        }
        if (nameTokens.isNotEmpty) {
          items.add({'name': nameTokens.join(' '), 'quantity': qty});
        }
      } else if (!_isStopWord(tokens[i])) {
        // NAME-FIRST: collect name tokens, then look for trailing qty
        final nameTokens = <String>[tokens[i]];
        i++;
        while (i < tokens.length &&
            _extractQty(tokens[i]) == null &&
            !_isStopWord(tokens[i])) {
          nameTokens.add(tokens[i]);
          i++;
        }
        // Check for following qty
        if (i < tokens.length) {
          final followQty = _extractQty(tokens[i]);
          if (followQty != null) {
            items.add({'name': nameTokens.join(' '), 'quantity': followQty});
            i++;
          } else {
            items.add({'name': nameTokens.join(' '), 'quantity': 1});
          }
        } else {
          items.add({'name': nameTokens.join(' '), 'quantity': 1});
        }
      } else {
        i++;
      }
    }

    return items;
  }

  /// Extract a quantity from a token, or null if it's not a qty token.
  /// Handles: "2", "2.5", "2pcs", "3x", "x3".
  double? _extractQty(String token) {
    final pure = double.tryParse(token);
    if (pure != null) return pure;

    // Number with suffix: "2pcs", "2pc", "3x"
    final suffixMatch = RegExp(
      r'^(\d+(?:\.\d+)?)\s*(?:x|pcs|pc|pieces?)$',
      caseSensitive: false,
    ).firstMatch(token);
    if (suffixMatch != null) return double.tryParse(suffixMatch.group(1)!);

    // Prefix "x": "x3"
    final prefixMatch = RegExp(
      r'^x(\d+(?:\.\d+)?)$',
      caseSensitive: false,
    ).firstMatch(token);
    if (prefixMatch != null) return double.tryParse(prefixMatch.group(1)!);

    return null;
  }

  bool _isStopWord(String word) {
    const stopWords = {
      'i', 'want', 'need', 'please', 'add', 'buy', 'get', 'give',
      'me', 'the', 'a', 'an', 'some', 'of', 'to',
    };
    return stopWords.contains(word.toLowerCase());
  }

  /// Format a DateTime as YYYY-MM-DD without depending on intl.
  static String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Release model resources.
  Future<void> dispose() async {
    await _engine.dispose();
  }
}
