import 'package:pos/core/utils/business_clock.dart';

// Models for the AI Assistant pipeline.

/// All supported actions the AI can detect from user input.
enum AiAction {
  getSales,
  getExpenses,
  getSalesByCategory,
  getSalesByProduct,
  getProductCount,
  getActiveProducts,
  getProductsWithoutSales,
  getTransactionCount,
  createTransaction,
  unknown,
}

/// Aggregation type for sales queries.
enum AiAggregationType { total, highest, lowest, perCategory, perProduct }

/// Date filter type detected from user input.
enum AiDateType { today, specific, range, none }

/// Structured date filter extracted from user input.
class AiDateFilter {
  final AiDateType type;

  /// For [AiDateType.specific]: the exact date.
  final DateTime? value;

  /// For [AiDateType.range]: inclusive start date.
  final DateTime? start;

  /// For [AiDateType.range]: inclusive end date.
  final DateTime? end;

  const AiDateFilter({
    this.type = AiDateType.none,
    this.value,
    this.start,
    this.end,
  });

  factory AiDateFilter.none() => const AiDateFilter();

  factory AiDateFilter.today() => const AiDateFilter(type: AiDateType.today);

  /// Resolve the effective start/end for database queries.
  /// All resolved dates are start-of-day inclusive.
  ({DateTime start, DateTime end}) resolve() {
    final now = BusinessClock.now();
    switch (type) {
      case AiDateType.today:
        final sod = DateTime(now.year, now.month, now.day);
        return (start: sod, end: now);
      case AiDateType.specific:
        final d = value ?? now;
        final sod = DateTime(d.year, d.month, d.day);
        final eod = sod.add(const Duration(days: 1));
        return (start: sod, end: eod);
      case AiDateType.range:
        final s = start ?? DateTime(now.year, now.month, now.day);
        final e = end ?? now;
        final eod = DateTime(e.year, e.month, e.day).add(
          const Duration(days: 1),
        );
        return (start: s, end: eod);
      case AiDateType.none:
        // No date filter — return all-time range
        return (start: DateTime(2000), end: now);
    }
  }
}

/// Represents a single item parsed from user input.
class AiParsedItem {
  final String name;
  final double quantity;

  const AiParsedItem({required this.name, required this.quantity});

  AiParsedItem copyWith({String? name, double? quantity}) {
    return AiParsedItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'quantity': quantity};

  factory AiParsedItem.fromJson(Map<String, dynamic> json) {
    return AiParsedItem(
      name: (json['name'] as String?)?.trim() ?? '',
      quantity: _parseQuantity(json['quantity']),
    );
  }

  static double _parseQuantity(dynamic value) {
    if (value == null) return 1;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 1;
    return 1;
  }
}

/// The structured result from the LLM after parsing + validation.
class AiParsedResult {
  final AiAction action;
  final AiDateFilter dateFilter;
  final String? category;
  final String? product;
  final AiAggregationType aggregation;
  final List<AiParsedItem> items;

  const AiParsedResult({
    required this.action,
    this.dateFilter = const AiDateFilter(),
    this.category,
    this.product,
    this.aggregation = AiAggregationType.total,
    required this.items,
  });

  factory AiParsedResult.unknown() => const AiParsedResult(
    action: AiAction.unknown,
    items: [],
  );
}

/// A matched product ready for transaction preview.
class AiMatchedProduct {
  final String productId;
  final String variantId;
  final String productName;
  final String variantName;
  final double unitPrice;
  final double? taxRate;
  final double quantity;
  final int availableStock;
  final bool trackStock;

  /// All active variants for this product (populated when hasVariants is true).
  final List<AiVariantOption> availableVariants;

  const AiMatchedProduct({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.unitPrice,
    this.taxRate,
    required this.quantity,
    required this.availableStock,
    this.trackStock = false,
    this.availableVariants = const [],
  });

  /// Whether the user needs to pick a variant.
  bool get needsVariantSelection => availableVariants.length > 1;

  double get lineTotal => unitPrice * quantity;
  double get lineTax => unitPrice * quantity * (taxRate ?? 0) / 100;

  /// Create a copy with a different selected variant.
  AiMatchedProduct selectVariant(AiVariantOption variant) {
    return AiMatchedProduct(
      productId: productId,
      variantId: variant.variantId,
      productName: productName,
      variantName: variant.variantName,
      unitPrice: variant.price,
      taxRate: taxRate,
      quantity: quantity,
      availableStock: variant.stock,
      trackStock: variant.trackStock,
      availableVariants: availableVariants,
    );
  }
}

/// A selectable variant option shown in the transaction preview.
class AiVariantOption {
  final String variantId;
  final String variantName;
  final double price;
  final int stock;
  final bool trackStock;

  const AiVariantOption({
    required this.variantId,
    required this.variantName,
    required this.price,
    required this.stock,
    this.trackStock = false,
  });
}

/// The preview data shown before confirming a transaction.
class AiTransactionPreview {
  final List<AiMatchedProduct> matchedProducts;
  final List<String> unmatchedNames;
  final double subtotal;
  final double totalTax;
  final double grandTotal;

  const AiTransactionPreview({
    required this.matchedProducts,
    required this.unmatchedNames,
    required this.subtotal,
    required this.totalTax,
    required this.grandTotal,
  });
}

/// A chat message in the AI assistant conversation.
class AiChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AiMessageType type;
  final AiTransactionPreview? transactionPreview;

  AiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.type,
    this.transactionPreview,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum AiMessageType { text, loading, transactionPreview, error }
