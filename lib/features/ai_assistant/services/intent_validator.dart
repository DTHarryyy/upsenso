import 'package:pos/features/ai_assistant/models/ai_models.dart';

/// Layer 4 — Validation: Validates parsed AI results and fixes minor issues.
class AiIntentValidator {
  /// Validate and normalize a parsed result from the LLM JSON.
  /// Fixes recoverable issues (default qty, remove empty items).
  /// Returns a clean, validated [AiParsedResult].
  static AiParsedResult validate(Map<String, dynamic>? json) {
    if (json == null) return AiParsedResult.unknown();

    final action = _parseAction(json['action']);
    final dateFilter = _parseDateFilter(json['filters']);
    final category = _parseCategory(json['filters']);
    final product = _parseProduct(json['filters']);
    final aggregation = _parseAggregation(json['aggregation']);
    final items = _parseItems(json['items']);

    // Validate items for transaction
    if (action == AiAction.createTransaction) {
      if (items.isEmpty) return AiParsedResult.unknown();
      return AiParsedResult(
        action: action,
        dateFilter: dateFilter,
        category: category,
        product: product,
        aggregation: aggregation,
        items: items,
      );
    }

    return AiParsedResult(
      action: action,
      dateFilter: dateFilter,
      category: category,
      product: product,
      aggregation: aggregation,
      items: const [],
    );
  }

  static AiAction _parseAction(dynamic value) {
    if (value is! String) return AiAction.unknown;
    switch (value.toUpperCase().trim()) {
      case 'GET_SALES':
        return AiAction.getSales;
      case 'GET_EXPENSES':
        return AiAction.getExpenses;
      case 'GET_SALES_BY_CATEGORY':
        return AiAction.getSalesByCategory;
      case 'GET_SALES_BY_PRODUCT':
        return AiAction.getSalesByProduct;
      case 'GET_PRODUCT_COUNT':
        return AiAction.getProductCount;
      case 'GET_ACTIVE_PRODUCTS':
        return AiAction.getActiveProducts;
      case 'GET_PRODUCTS_WITHOUT_SALES':
        return AiAction.getProductsWithoutSales;
      case 'GET_TRANSACTION_COUNT':
        return AiAction.getTransactionCount;
      case 'CREATE_TRANSACTION':
        return AiAction.createTransaction;
      default:
        return AiAction.unknown;
    }
  }

  static AiDateFilter _parseDateFilter(dynamic filters) {
    if (filters is! Map<String, dynamic>) return const AiDateFilter();
    final date = filters['date'];
    if (date is! Map<String, dynamic>) return const AiDateFilter();

    final type = _parseDateType(date['type']);

    switch (type) {
      case AiDateType.today:
        return AiDateFilter.today();
      case AiDateType.specific:
        final raw = date['value'];
        DateTime? value;
        if (raw is String) {
          value = _tryParseDate(raw);
        }
        return AiDateFilter(type: AiDateType.specific, value: value);
      case AiDateType.range:
        DateTime? start, end;
        if (date['start'] is String) {
          start = _tryParseDate(date['start'] as String);
        }
        if (date['end'] is String) {
          end = _tryParseDate(date['end'] as String);
        }
        return AiDateFilter(type: AiDateType.range, start: start, end: end);
      case AiDateType.none:
        return const AiDateFilter();
    }
  }

  /// Parse YYYY-MM-DD without depending on intl.
  static DateTime? _tryParseDate(String raw) {
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  static AiDateType _parseDateType(dynamic value) {
    if (value is! String) return AiDateType.none;
    switch (value.toLowerCase().trim()) {
      case 'today':
        return AiDateType.today;
      case 'specific':
        return AiDateType.specific;
      case 'range':
        return AiDateType.range;
      default:
        return AiDateType.none;
    }
  }

  static String? _parseCategory(dynamic filters) {
    if (filters is! Map<String, dynamic>) return null;
    final cat = filters['category'];
    if (cat is String && cat.trim().isNotEmpty) return cat.trim();
    return null;
  }

  static String? _parseProduct(dynamic filters) {
    if (filters is! Map<String, dynamic>) return null;
    final prod = filters['product'];
    if (prod is String && prod.trim().isNotEmpty) return prod.trim();
    return null;
  }

  static AiAggregationType _parseAggregation(dynamic aggregation) {
    if (aggregation is! Map<String, dynamic>) return AiAggregationType.total;
    final type = aggregation['type'];
    if (type is! String) return AiAggregationType.total;
    switch (type.toLowerCase().trim()) {
      case 'highest':
        return AiAggregationType.highest;
      case 'lowest':
        return AiAggregationType.lowest;
      case 'per_category':
        return AiAggregationType.perCategory;
      case 'per_product':
        return AiAggregationType.perProduct;
      default:
        return AiAggregationType.total;
    }
  }

  static List<AiParsedItem> _parseItems(dynamic value) {
    if (value is! List) return [];

    final items = <AiParsedItem>[];
    for (final raw in value) {
      if (raw is! Map<String, dynamic>) continue;

      final item = AiParsedItem.fromJson(raw);

      // Skip empty names
      if (item.name.isEmpty) continue;

      // Fix: quantity must be > 0, default to 1
      final fixedItem = item.quantity <= 0 ? item.copyWith(quantity: 1) : item;

      // Avoid duplicates — merge quantities
      final existing = items.indexWhere(
        (i) => i.name.toLowerCase() == fixedItem.name.toLowerCase(),
      );
      if (existing >= 0) {
        items[existing] = items[existing].copyWith(
          quantity: items[existing].quantity + fixedItem.quantity,
        );
      } else {
        items.add(fixedItem);
      }
    }

    return items;
  }
}
