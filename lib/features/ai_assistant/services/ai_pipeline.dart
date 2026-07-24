import 'package:flutter/foundation.dart';
import 'package:pos/features/ai_assistant/models/ai_models.dart';
import 'package:pos/features/ai_assistant/services/llm_service.dart';
import 'package:pos/features/ai_assistant/services/json_parser.dart';
import 'package:pos/features/ai_assistant/services/intent_validator.dart';
import 'package:pos/features/ai_assistant/services/ai_scope_guard.dart';
import 'package:pos/features/ai_assistant/services/ai_tool_service.dart';
import 'package:pos/features/ai_assistant/services/product_matcher.dart';
import 'package:pos/features/ai_assistant/services/response_formatter.dart';

/// The AI Pipeline orchestrates ALL layers (2→3→4→5→6→7→10) in sequence.
///
/// Flow:
/// 1. User text → LLM (Layer 2)
/// 2. Raw LLM output → JSON Parser (Layer 3)
/// 3. Parsed JSON → Validator (Layer 4)
/// 4. Validated action → Business Logic (Layer 7)
///    a. Query → Tool Service (Layer 5) → Response (Layer 10)
///    b. Transaction → Product Matcher (Layer 6) → Preview (Layer 8, via Bloc)
///    c. Unknown → Fallback response (Layer 10)
class AiPipeline {
  final LlmService _llmService;
  final AiToolService _toolService;
  final AiScopeGuard _scopeGuard;

  /// Cached product catalog (refreshed periodically).
  List<ProductWithVariant>? _cachedCatalog;
  DateTime? _catalogCacheTime;
  static const _cacheDuration = Duration(seconds: 30);

  AiPipeline({
    required LlmService llmService,
    required AiToolService toolService,
    required AiScopeGuard scopeGuard,
  }) : _llmService = llmService,
       _toolService = toolService,
       _scopeGuard = scopeGuard;

  /// Initialize the pipeline (load LLM model if available).
  Future<void> initialize() async {
    await _llmService.initialize();
  }

  /// Process a user message through the full pipeline.
  /// Returns an [AiPipelineResult] with the response text and optional preview.
  ///
  /// Tenant/branch/permission scope is NOT passed in — it is derived
  /// authoritatively from [AiScopeGuard] (session + RBAC) so it can never be
  /// spoofed by the caller.
  Future<AiPipelineResult> processMessage({required String userMessage}) async {
    try {
      // ── Layer 2: LLM Intent Parsing ─────────────────────────
      final rawJson = await _llmService.generateResponse(userMessage);
      debugPrint('AI Pipeline [LLM]: $rawJson');

      // ── Layer 3: JSON Parsing ───────────────────────────────
      final cleaned = AiJsonParser.cleanRawOutput(rawJson);
      Map<String, dynamic>? parsed = AiJsonParser.extractJson(cleaned);

      // Retry once if parsing fails
      if (parsed == null) {
        debugPrint('AI Pipeline [JSON]: First parse failed, retrying...');
        final retryRaw = await _llmService.generateResponse(userMessage);
        final retryCleaned = AiJsonParser.cleanRawOutput(retryRaw);
        parsed = AiJsonParser.extractJson(retryCleaned);
      }

      // ── Layer 4: Validation ─────────────────────────────────
      final validated = AiIntentValidator.validate(parsed);
      debugPrint('AI Pipeline [Validated]: ${validated.action}');

      // ── Layer 7: Business Logic (scoped) ────────────────────
      return await _executeBusinessLogic(validated);
    } catch (e, st) {
      debugPrint('AI Pipeline [Error]: $e\n$st');
      return AiPipelineResult(
        responseText: AiResponseFormatter.formatError(e.toString()),
        type: AiResponseType.error,
      );
    }
  }

  /// Layer 7 — Business Logic: authorize the action against the user's
  /// permissions + module gates, resolve their data scope, then route to the
  /// correct handler. Deny-by-default — anything the [AiScopeGuard] doesn't
  /// allow returns a friendly refusal instead of touching data.
  Future<AiPipelineResult> _executeBusinessLogic(AiParsedResult result) async {
    // ── Write path — async gate (audit-logged), same pos.use the server checks.
    if (result.action == AiAction.createTransaction) {
      final auth = await _scopeGuard.authorizeWrite(AiAction.createTransaction);
      if (!auth.allowed) return _denied(auth.message);
      return _handleCreateTransaction(
        items: result.items,
        scope: _scopeGuard.resolveScope(),
      );
    }

    // ── No data access — plain fallback.
    if (result.action == AiAction.unknown) {
      return AiPipelineResult(
        responseText: AiResponseFormatter.formatUnknownIntent(),
        type: AiResponseType.text,
      );
    }

    // ── Read path — gate the domain, then resolve + inject the data scope.
    final auth = _scopeGuard.authorizeRead(result.action);
    if (!auth.allowed) return _denied(auth.message);
    final scope = _scopeGuard.resolveScope();

    switch (result.action) {
      case AiAction.getSales:
        // Product-scoped sales (e.g. "sales of coke today")
        if (result.product != null) {
          final productResult = await _toolService.getSalesBySpecificProduct(
            scope.businessId,
            scope.userId,
            result.product!,
            result.dateFilter,
            branchId: scope.branchId,
            ownUserId: scope.ownUserId,
          );
          if (productResult != null) {
            return AiPipelineResult(
              responseText: AiResponseFormatter.formatProductSales(
                productResult,
                result.dateFilter,
              ),
              type: AiResponseType.text,
            );
          }
          return AiPipelineResult(
            responseText: AiResponseFormatter.formatProductSalesNotFound(
              result.product!,
              result.dateFilter,
            ),
            type: AiResponseType.text,
          );
        }
        // Category-scoped sales (e.g. "sales of beverages")
        if (result.category != null) {
          final total = await _toolService.getSalesBySpecificCategory(
            scope.businessId,
            scope.userId,
            result.category!,
            result.dateFilter,
            branchId: scope.branchId,
            ownUserId: scope.ownUserId,
          );
          return AiPipelineResult(
            responseText: AiResponseFormatter.formatCategorySales(
              result.category!,
              total,
              result.dateFilter,
            ),
            type: AiResponseType.text,
          );
        }
        // Generic sales total
        final total = await _toolService.getSalesTotal(
          scope.businessId,
          scope.userId,
          result.dateFilter,
          branchId: scope.branchId,
          ownUserId: scope.ownUserId,
        );
        return AiPipelineResult(
          responseText: AiResponseFormatter.formatSalesTotal(
            total,
            result.dateFilter,
          ),
          type: AiResponseType.text,
        );

      case AiAction.getExpenses:
        return AiPipelineResult(
          responseText: AiResponseFormatter.formatExpensesUnavailable(),
          type: AiResponseType.text,
        );

      case AiAction.getSalesByCategory:
        final catResults = await _toolService.getSalesByCategory(
          scope.businessId,
          scope.userId,
          result.dateFilter,
          branchId: scope.branchId,
          ownUserId: scope.ownUserId,
        );
        // Route based on aggregation type
        switch (result.aggregation) {
          case AiAggregationType.highest:
            return AiPipelineResult(
              responseText: AiResponseFormatter.formatHighestCategory(
                catResults,
                result.dateFilter,
              ),
              type: AiResponseType.text,
            );
          case AiAggregationType.lowest:
            return AiPipelineResult(
              responseText: AiResponseFormatter.formatLowestCategory(
                catResults,
                result.dateFilter,
              ),
              type: AiResponseType.text,
            );
          default:
            return AiPipelineResult(
              responseText: AiResponseFormatter.formatSalesByCategory(
                catResults,
                result.dateFilter,
              ),
              type: AiResponseType.text,
            );
        }

      case AiAction.getSalesByProduct:
        final prodResults = await _toolService.getSalesByProduct(
          scope.businessId,
          scope.userId,
          result.dateFilter,
          branchId: scope.branchId,
          ownUserId: scope.ownUserId,
        );
        // Route based on aggregation type
        switch (result.aggregation) {
          case AiAggregationType.highest:
            return AiPipelineResult(
              responseText: AiResponseFormatter.formatHighestProduct(
                prodResults,
                result.dateFilter,
              ),
              type: AiResponseType.text,
            );
          case AiAggregationType.lowest:
            return AiPipelineResult(
              responseText: AiResponseFormatter.formatLowestProduct(
                prodResults,
                result.dateFilter,
              ),
              type: AiResponseType.text,
            );
          default:
            return AiPipelineResult(
              responseText: AiResponseFormatter.formatSalesByProduct(
                prodResults,
                result.dateFilter,
              ),
              type: AiResponseType.text,
            );
        }

      case AiAction.getProductCount:
        final count = await _toolService.getProductCount(scope.businessId);
        return AiPipelineResult(
          responseText: AiResponseFormatter.formatProductCount(count),
          type: AiResponseType.text,
        );

      case AiAction.getActiveProducts:
        final products = await _toolService.getActiveProducts(scope.businessId);
        return AiPipelineResult(
          responseText: AiResponseFormatter.formatActiveProducts(
            products,
            includeStock: scope.includeStock,
          ),
          type: AiResponseType.text,
        );

      case AiAction.getProductsWithoutSales:
        final unsold = await _toolService.getProductsWithoutSales(
          scope.businessId,
          scope.userId,
          result.dateFilter,
          branchId: scope.branchId,
          ownUserId: scope.ownUserId,
        );
        return AiPipelineResult(
          responseText: AiResponseFormatter.formatProductsWithoutSales(
            unsold,
            result.dateFilter,
            includeStock: scope.includeStock,
          ),
          type: AiResponseType.text,
        );

      case AiAction.getTransactionCount:
        final count = await _toolService.getTransactionCount(
          scope.businessId,
          scope.userId,
          result.dateFilter,
          branchId: scope.branchId,
          ownUserId: scope.ownUserId,
        );
        return AiPipelineResult(
          responseText: AiResponseFormatter.formatTransactionCount(
            count,
            result.dateFilter,
          ),
          type: AiResponseType.text,
        );

      // Handled above — unreachable, kept for switch exhaustiveness.
      case AiAction.createTransaction:
      case AiAction.unknown:
        return AiPipelineResult(
          responseText: AiResponseFormatter.formatUnknownIntent(),
          type: AiResponseType.text,
        );
    }
  }

  /// A friendly, non-error refusal message (permission/module/tenant denial).
  AiPipelineResult _denied(String message) =>
      AiPipelineResult(responseText: message, type: AiResponseType.text);

  /// Handle create_transaction intent:
  /// 1. Get/refresh product catalog (Layer 5)
  /// 2. Fuzzy match items (Layer 6)
  /// 3. Build preview (Layer 8 data)
  Future<AiPipelineResult> _handleCreateTransaction({
    required List<AiParsedItem> items,
    required AiScope scope,
  }) async {
    final businessId = scope.businessId;
    // Layer 5: Get product catalog (with caching)
    final catalog = await _getCatalog(businessId);
    debugPrint(
      'AI Pipeline [Catalog]: businessId=$businessId, '
      'products=${catalog.length}, '
      'names=${catalog.map((c) => c.product.name).toSet().join(", ")}',
    );

    if (catalog.isEmpty) {
      return AiPipelineResult(
        responseText:
            'No products found in your inventory. '
            'Please add products first before creating transactions.',
        type: AiResponseType.text,
      );
    }

    // Layer 6: Fuzzy match items against catalog
    debugPrint(
      'AI Pipeline [Items]: ${items.map((i) => '${i.name}×${i.quantity}').join(', ')}',
    );
    final matchResult = ProductMatcher.matchItems(
      parsedItems: items,
      catalog: catalog,
    );

    // Build preview
    final matched = matchResult.matched;
    final unmatched = matchResult.unmatched;
    debugPrint(
      'AI Pipeline [Match]: matched=${matched.length}, '
      'unmatched=${unmatched.join(', ')}',
    );

    if (matched.isEmpty) {
      final catalogNames = catalog.map((c) => c.product.name).toSet().toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return AiPipelineResult(
        responseText: AiResponseFormatter.formatUnmatchedProducts(
          unmatched.isNotEmpty ? unmatched : items.map((i) => i.name).toList(),
          catalogNames: catalogNames,
        ),
        type: AiResponseType.text,
      );
    }

    final subtotal = matched.fold(0.0, (sum, p) => sum + p.lineTotal);
    final totalTax = matched.fold(0.0, (sum, p) => sum + p.lineTax);

    final preview = AiTransactionPreview(
      matchedProducts: matched,
      unmatchedNames: unmatched,
      subtotal: subtotal,
      totalTax: totalTax,
      grandTotal: subtotal + totalTax,
    );

    return AiPipelineResult(
      responseText: AiResponseFormatter.formatPreviewMessage(preview),
      type: AiResponseType.transactionPreview,
      preview: preview,
    );
  }

  /// Layer 9 — Execution: Create the transaction ONLY after user confirms.
  /// Re-authorizes the write (defence-in-depth) and re-derives the scope from
  /// the session — the caller never supplies tenant/branch/author.
  Future<AiPipelineResult> confirmTransaction({
    required AiTransactionPreview preview,
  }) async {
    final auth = await _scopeGuard.authorizeWrite(AiAction.createTransaction);
    if (!auth.allowed) return _denied(auth.message);
    final scope = _scopeGuard.resolveScope();
    try {
      final lineItems = preview.matchedProducts.map((p) {
        return TransactionLineItem(
          variantId: p.variantId,
          productName: p.productName,
          variantName: p.variantName,
          unitPrice: p.unitPrice,
          taxRate: p.taxRate,
          quantity: p.quantity,
        );
      }).toList();

      final txId = await _toolService.createTransaction(
        cashierId: scope.userId,
        businessId: scope.businessId,
        branchId: scope.branchId,
        lineItems: lineItems,
      );

      return AiPipelineResult(
        responseText: AiResponseFormatter.formatTransactionCreated(txId),
        type: AiResponseType.text,
      );
    } catch (e, st) {
      debugPrint('AI Pipeline [Error] in createSale: $e\n$st');
      return AiPipelineResult(
        responseText: AiResponseFormatter.formatError(e.toString()),
        type: AiResponseType.error,
      );
    }
  }

  /// Get product catalog with caching.
  Future<List<ProductWithVariant>> _getCatalog(String businessId) async {
    final now = DateTime.now();
    if (_cachedCatalog != null &&
        _catalogCacheTime != null &&
        now.difference(_catalogCacheTime!) < _cacheDuration) {
      return _cachedCatalog!;
    }

    _cachedCatalog = await _toolService.getProductCatalog(businessId);
    _catalogCacheTime = now;
    return _cachedCatalog!;
  }

  /// Invalidate the product catalog cache.
  void invalidateCatalogCache() {
    _cachedCatalog = null;
    _catalogCacheTime = null;
  }

  void dispose() {
    _llmService.dispose();
  }
}

/// The result from the AI pipeline.
class AiPipelineResult {
  final String responseText;
  final AiResponseType type;
  final AiTransactionPreview? preview;

  const AiPipelineResult({
    required this.responseText,
    required this.type,
    this.preview,
  });
}

enum AiResponseType { text, transactionPreview, error }
