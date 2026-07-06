import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/errors/app_error_mapper.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';
import 'package:pos/features/products/domain/entities/product.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/product_barcodes_dao.dart';
import 'package:pos/core/database/daos/recipe_lines_dao.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/core/utils/barcode_generator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pos/core/services/image_service.dart';
import 'product_form_state.dart';

class ProductFormCubit extends Cubit<ProductFormState> {
  ProductFormCubit({required this.businessId, this.selectedBranchId})
    : super(ProductFormState.initial()) {
    _loadCategories();
  }

  final String businessId;

  /// The branch UUID currently selected in the top-right dropdown.
  /// null means "All Branches" — see [_seedInventoryLevels] for handling.
  final String? selectedBranchId;

  final _categoriesDao = sl<CategoriesDao>();
  final _productsDao = sl<ProductsDao>();
  final _productVariantsDao = sl<ProductVariantsDao>();
  final _productBarcodesDao = sl<ProductBarcodesDao>();
  final _recipeLinesDao = sl<RecipeLinesDao>();
  final _imageService = sl<ImageService>();
  final _levelsDao = sl<InventoryLevelsDao>();

  // ── Category loading ──────────────────────────────────────────────────────

  Future<void> _loadCategories() async {
    final list = await _categoriesDao.getByBusinessId(businessId);
    emit(state.copyWith(categories: list));
  }

  Future<void> reloadCategories() => _loadCategories();

  // ── Mode / toggles ────────────────────────────────────────────────────────

  void switchMode(ProductFormMode mode) {
    if (state.mode == mode) return;
    emit(state.copyWith(mode: mode));
  }

  void setHasVariants(bool value) => emit(state.copyWith(hasVariants: value));

  void setTrackingMethod(TrackingMethod method) {
    emit(state.copyWith(
      trackingMethod: method,
      // Switching off recipe clears the recipe list and re-enables stock.
      recipeLines: method == TrackingMethod.recipe ? state.recipeLines : [],
      trackInventory: method == TrackingMethod.recipe ? false : state.trackInventory,
    ));
  }

  // ── No-variants recipe lines ──────────────────────────────────────────────

  void setRecipeLines(List<RecipeLineFormEntry> lines) =>
      emit(state.copyWith(recipeLines: lines));

  void addRecipeLine(RecipeLineFormEntry entry) {
    final updated = [...state.recipeLines, entry];
    emit(state.copyWith(recipeLines: updated));
  }

  void removeRecipeLine(String ingredientVariantId) {
    final updated = state.recipeLines
        .where((l) => l.ingredientVariantId != ingredientVariantId)
        .toList();
    emit(state.copyWith(recipeLines: updated));
  }

  void updateRecipeLineQty(String ingredientVariantId, double qty) {
    final updated = state.recipeLines.map((l) {
      return l.ingredientVariantId == ingredientVariantId
          ? l.copyWith(quantity: qty)
          : l;
    }).toList();
    emit(state.copyWith(recipeLines: updated));
  }


  void setTrackInventory(bool value) =>
      emit(state.copyWith(trackInventory: value));

  void setTrackExpiry(bool value) {
    if (!value) {
      emit(state.copyWith(trackExpiry: false, clearExpiryDate: true));
    } else {
      emit(state.copyWith(trackExpiry: true));
    }
  }

  void setExpiryDate(DateTime date) => emit(state.copyWith(expiryDate: date));

  void toggleMoreOptions() =>
      emit(state.copyWith(moreOptionsExpanded: !state.moreOptionsExpanded));

  void selectCategory(String? id) =>
      emit(state.copyWith(selectedCategoryId: id));

  // ── Image ─────────────────────────────────────────────────────────────────

  Future<void> pickImage(ImageSource source) async {
    emit(state.copyWith(isUploadingImage: true, clearError: true));
    try {
      final localPath = await _imageService.pickImageLocally(source: source);
      emit(
        state.copyWith(
          isUploadingImage: false,
          imagePath: localPath ?? state.imagePath,
        ),
      );
    } catch (e, st) {
      debugPrint('[ProductFormCubit] Error in pickImage: $e\n$st');
      emit(
        state.copyWith(
          isUploadingImage: false,
          error: AppErrorMapper.message(e),
        ),
      );
    }
  }

  void clearImage() => emit(state.copyWith(clearImagePath: true));

  // ── SKU generation ────────────────────────────────────────────────────────

  String generateSku(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final prefix = trimmed
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .join('');
    final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(
      8,
    );
    return '$prefix-$suffix';
  }

  // ── Barcode generation ────────────────────────────────────────────────────

  /// Generates a valid EAN-13 barcode guaranteed not to collide with any
  /// existing product/variant barcode in this business. Random 11-digit payload
  /// makes collisions astronomically rare; we still re-roll on the off chance.
  Future<String> generateUniqueBarcode() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final code = generateEan13();
      final taken =
          await _productBarcodesDao.codeExists(code, businessId) ||
          await _productVariantsDao.barcodeExists(code, businessId) ||
          await _productsDao.barcodeExists(code, businessId);
      if (!taken) return code;
    }
    return generateEan13();
  }

  /// variantId → its active barcode codes (primary first). Used to prefill the
  /// edit form from the normalized store.
  Future<Map<String, List<String>>> loadBarcodesForVariants(
    List<String> variantIds,
  ) async {
    final result = <String, List<String>>{};
    for (final id in variantIds) {
      final rows = await _productBarcodesDao.getByVariantId(id);
      if (rows.isNotEmpty) result[id] = rows.map((r) => r.code).toList();
    }
    return result;
  }

  /// Returns a user-facing error if a barcode is duplicated within the form or
  /// already belongs to a different product; null when the set is valid.
  /// [productId] is the product being edited (its own variants don't collide).
  Future<String?> _validateBarcodes(
    ProductFormData data,
    bool hasVariants, {
    String? productId,
  }) async {
    final codes = <String>[];
    if (hasVariants) {
      for (final v in data.variants) {
        codes.addAll(v.barcodes.map((c) => c.trim()).where((c) => c.isNotEmpty));
      }
    } else {
      codes.addAll(data.barcodes.map((c) => c.trim()).where((c) => c.isNotEmpty));
    }

    final unique = <String>{};
    for (final code in codes) {
      if (!unique.add(code)) {
        return 'The barcode "$code" is used more than once.';
      }
    }

    final ownVariantIds = <String>{};
    if (productId != null) {
      final existing = await _productVariantsDao.getByProductId(productId);
      ownVariantIds.addAll(existing.map((v) => v.id));
    }
    for (final code in unique) {
      final row = await _productBarcodesDao.getByCode(code, businessId);
      if (row != null && !ownVariantIds.contains(row.variantId)) {
        return 'Barcode "$code" is already used by another product.';
      }
    }
    return null;
  }

  // ── Edit existing product ─────────────────────────────────────────────────

  /// Initialise cubit state from an existing product (called when editing).
  void initEditState(Product product) {
    final method = TrackingMethodX.fromCode(product.trackingMethod);
    emit(
      state.copyWith(
        mode: ProductFormMode.advanced,
        hasVariants: product.hasVariants,
        trackingMethod: method,
        selectedCategoryId: product.categoryId,
        imagePath: product.imagePath,
        trackInventory: false, // updated after loading variants
      ),
    );
  }

  /// Load recipe lines for a no-variants product (Default variant → cubit state).
  Future<void> loadRecipeLinesForProduct(String productId) async {
    final variants = await _productVariantsDao.getByProductId(productId);
    if (variants.isEmpty) {
      // No variant row yet (e.g. mid-creation) — nothing to load.
      emit(state.copyWith(recipeLines: []));
      return;
    }
    final defaultVariant = variants.firstWhere(
      (v) => v.name == 'Default',
      orElse: () => variants.first,
    );
    final rows = await _recipeLinesDao.getByVariantId(defaultVariant.id);
    final entries = rows
        .map(
          (r) => RecipeLineFormEntry(
            ingredientVariantId: r.ingredientVariantId,
            ingredientName: r.ingredientName,
            quantity: r.quantity,
            unit: r.unit,
          ),
        )
        .toList();
    emit(state.copyWith(recipeLines: entries));
  }

  /// Load recipe lines for each active variant (edit mode, variant products).
  /// Returns variantId → lines so the caller can populate VariantForm holders.
  Future<Map<String, List<RecipeLineFormEntry>>> loadVariantRecipeLines(
    List<String> variantIds,
  ) async {
    final result = <String, List<RecipeLineFormEntry>>{};
    for (final id in variantIds) {
      final rows = await _recipeLinesDao.getByVariantId(id);
      if (rows.isNotEmpty) {
        result[id] = rows
            .map((r) => RecipeLineFormEntry(
                  ingredientVariantId: r.ingredientVariantId,
                  ingredientName: r.ingredientName,
                  quantity: r.quantity,
                  unit: r.unit,
                ))
            .toList();
      }
    }
    return result;
  }

  /// Load the variants for a product (used to pre-fill the edit form).
  Future<List<ProductVariantsTableData>> loadVariants(String productId) {
    return _productVariantsDao.getByProductId(productId);
  }

  /// Returns variantId → stock quantity for [variantIds].
  /// - All Branches (null): sums all inventory_levels rows per variant.
  ///   Variants with no rows are absent; callers fall back to
  ///   [ProductVariantsTableData.stock] in that case.
  /// - Specific branch: returns that branch's exact quantity (absent = 0 to caller).
  Future<Map<String, double>> loadBranchStockMap(List<String> variantIds) async {
    final result = <String, double>{};
    if (selectedBranchId == null) {
      for (final id in variantIds) {
        final levels = await _levelsDao.getByVariantId(id);
        if (levels.isNotEmpty) {
          result[id] = levels.fold(0.0, (sum, l) => sum + l.quantity);
        }
      }
      return result;
    }
    for (final id in variantIds) {
      final level = await _levelsDao.getLevel(id, selectedBranchId!);
      if (level != null) result[id] = level.quantity;
    }
    return result;
  }

  // ── Add category ──────────────────────────────────────────────────────────

  Future<String> addCategory(String name) async {
    final newId = await _categoriesDao.insertSingle(
      businessId: businessId,
      name: name,
    );
    await _loadCategories();
    emit(state.copyWith(selectedCategoryId: newId));

    sl<AuditLogService>().log(
      actionType: AuditLogActionType.categoryCreated,
      entityType: 'category',
      entityId: newId,
      entityName: name,
      description: 'Category $name created',
      businessId: businessId,
    );
    return newId;
  }

  // ── Update (edit mode) ────────────────────────────────────────────────────

  Future<void> update(String productId, ProductFormData data) async {
    if (data.isDraft) {
      emit(state.copyWith(isSavingDraft: true, clearError: true));
    } else {
      emit(state.copyWith(isSaving: true, clearError: true));
    }
    try {
      final isAdvanced = state.mode == ProductFormMode.advanced;
      final hasVariants = isAdvanced && state.hasVariants;

      final barcodeError = await _validateBarcodes(
        data,
        hasVariants,
        productId: productId,
      );
      if (barcodeError != null) {
        emit(state.copyWith(
          isSaving: false,
          isSavingDraft: false,
          error: barcodeError,
        ));
        return;
      }

      final tax = (data.taxPercent?.trim().isNotEmpty == true)
          ? double.tryParse(data.taxPercent!)
          : null;

      // Update product row
      await _productsDao.updateProduct(
        productId,
        ProductsTableCompanion(
          name: Value(data.name.trim()),
          categoryId: Value(state.selectedCategoryId),
          sku: Value(
            data.sku?.trim().isNotEmpty == true ? data.sku!.trim() : null,
          ),
          hasVariants: Value(hasVariants),
          tax: Value(tax),
          sellBy: Value(data.sellBy),
          imagePath: Value(data.imagePath),
          isActive: Value(!data.isDraft),
          trackingMethod: Value(data.trackingMethod.code),
          syncStatus: const Value(1), // pendingUpdate
          localUpdatedAt: Value(DateTime.now()),
        ),
      );

      // Snapshot existing inventory levels (keyed by variant name) before
      // touching variants. This lets us re-link levels to whichever variant
      // id ends up representing that name after this edit.
      final oldVariants = await _productVariantsDao.getByProductId(productId);
      // variantName → { branchId → (qty, qtyDecimal) }
      final savedLevels = <String, Map<String, double>>{};
      // variantName → existing id. Reusing the id when a name survives the
      // edit keeps any cart item / recipe line / stock-ledger row pointing at
      // it valid — regenerating a fresh UUID here used to silently orphan
      // them (a held cart item's deduction would just no-op at checkout).
      final oldIdByName = <String, String>{};
      for (final v in oldVariants) {
        oldIdByName[v.name] = v.id;
        final levels = await _levelsDao.getByVariantId(v.id);
        if (levels.isNotEmpty) {
          savedLevels[v.name] = {
            for (final l in levels) l.branchId: l.quantity,
          };
        }
      }
      final reusedIds = <String>{};

      // variantName → newId — used to restore saved levels after insert.
      final variantNameToNewId = <String, String>{};
      final seeds = <({String variantId, double qty})>[];

      if (hasVariants) {
        final companions = <ProductVariantsTableCompanion>[];
        for (final v in data.variants) {
          final name = v.name.trim().isEmpty ? 'Default' : v.name.trim();
          final existingId = oldIdByName[name];
          final id = existingId ?? const Uuid().v4();
          if (existingId != null) reusedIds.add(existingId);
          final vPrice = double.tryParse(v.price) ?? 0.0;
          final vCost = (v.costPrice?.trim().isNotEmpty == true)
              ? double.tryParse(v.costPrice!)
              : null;
          final vRetail = (v.retailPrice?.trim().isNotEmpty == true)
              ? double.tryParse(v.retailPrice!)
              : null;
          final vStock = state.trackInventory
              ? (double.tryParse(v.stock ?? '') ?? 0.0)
              : 0.0;
          final vLowAlert = (v.lowStockAlert?.trim().isNotEmpty == true)
              ? int.tryParse(v.lowStockAlert!)
              : null;
          companions.add(
            ProductVariantsTableCompanion.insert(
              id: id,
              productId: productId,
              businessId: businessId,
              name: name,
              price: Value(vPrice),
              costPrice: Value(vCost),
              retailPrice: Value(vRetail),
              // Barcodes now live in product_barcodes (see replaceForVariant).
              barcode: const Value(null),
              unit: Value(data.unit),
              stock: Value(vStock),
              lowStockAlert: Value(vLowAlert),
              trackStock: Value(state.trackInventory),
              trackExpiry: Value(state.trackExpiry),
              expiryDate: Value(state.trackExpiry ? state.expiryDate : null),
              syncStatus: Value(
                existingId != null
                    ? SyncStatus.pendingUpdate.toInt()
                    : SyncStatus.pendingUpload.toInt(),
              ),
            ),
          );
          variantNameToNewId[name] = id;
          seeds.add((variantId: id, qty: vStock));
        }
        await _productVariantsDao.insertVariants(companions);
      } else if (isAdvanced) {
        final existingId = oldIdByName['Default'];
        final id = existingId ?? const Uuid().v4();
        if (existingId != null) reusedIds.add(existingId);
        // Store the tax-exclusive price. Tax is applied once at the cart layer
        // via the product's tax rate — storing it inclusive here double-taxes.
        final finalPrice = double.tryParse(data.sellingPrice ?? '') ?? 0.0;
        final cost = (data.costPrice?.trim().isNotEmpty == true)
            ? double.tryParse(data.costPrice!)
            : null;
        final retail = (data.retailPrice?.trim().isNotEmpty == true)
            ? double.tryParse(data.retailPrice!)
            : null;
        final stockValue = state.trackInventory
            ? (double.tryParse(data.stock ?? '') ?? 0.0)
            : 0.0;
        final lowAlert = (data.lowStockAlert?.trim().isNotEmpty == true)
            ? int.tryParse(data.lowStockAlert!)
            : null;
        await _productVariantsDao.insertVariant(
          ProductVariantsTableCompanion.insert(
            id: id,
            productId: productId,
            businessId: businessId,
            name: 'Default',
            price: Value(finalPrice),
            costPrice: Value(cost),
            retailPrice: Value(retail),
            // Barcodes now live in product_barcodes (see replaceForVariant).
            barcode: const Value(null),
            unit: Value(data.unit),
            stock: Value(stockValue),
            lowStockAlert: Value(lowAlert),
            trackStock: Value(state.trackInventory),
            trackExpiry: Value(state.trackExpiry),
            expiryDate: Value(state.trackExpiry ? state.expiryDate : null),
            syncStatus: Value(
              existingId != null
                  ? SyncStatus.pendingUpdate.toInt()
                  : SyncStatus.pendingUpload.toInt(),
            ),
          ),
        );
        variantNameToNewId['Default'] = id;
        seeds.add((variantId: id, qty: stockValue));
      } else {
        // Simple mode — no inventory tracking
        final existingId = oldIdByName['Default'];
        final id = existingId ?? const Uuid().v4();
        if (existingId != null) reusedIds.add(existingId);
        final price = double.tryParse(data.simplePrice ?? '') ?? 0.0;
        final simpleBarcode = data.simpleBarcode?.trim();
        await _productVariantsDao.insertVariant(
          ProductVariantsTableCompanion.insert(
            id: id,
            productId: productId,
            businessId: businessId,
            name: 'Default',
            price: Value(price),
            costPrice: const Value(null),
            retailPrice: const Value(null),
            stock: const Value(0.0),
            lowStockAlert: const Value(null),
            barcode: Value(
              simpleBarcode?.isNotEmpty == true ? simpleBarcode : null,
            ),
            trackStock: const Value(false),
            trackExpiry: const Value(false),
            expiryDate: const Value(null),
            syncStatus: Value(
              existingId != null
                  ? SyncStatus.pendingUpdate.toInt()
                  : SyncStatus.pendingUpload.toInt(),
            ),
          ),
        );
        variantNameToNewId['Default'] = id;
      }

      // Remove only variants the new data no longer references — ones we
      // reused above must survive untouched (delete-then-recreate would
      // defeat the id-reuse and re-introduce the stale-reference bug).
      final idsToDelete = oldVariants
          .map((v) => v.id)
          .where((id) => !reusedIds.contains(id))
          .toList();
      await _productVariantsDao.markDeleteByIds(idsToDelete);

      // Barcodes: soft-delete those of removed variants, then reconcile each
      // surviving variant's set into the normalized store.
      for (final id in idsToDelete) {
        await _productBarcodesDao.markDeleteByVariantId(id);
      }
      if (hasVariants) {
        for (final v in data.variants) {
          final name = v.name.trim().isEmpty ? 'Default' : v.name.trim();
          final id = variantNameToNewId[name];
          if (id != null) {
            await _productBarcodesDao.replaceForVariant(id, businessId, v.barcodes);
          }
        }
      } else {
        final id = variantNameToNewId['Default'];
        if (id != null) {
          await _productBarcodesDao.replaceForVariant(id, businessId, data.barcodes);
        }
      }

      // Re-link saved inventory levels to new variant UUIDs.
      // For each new variant, restore all branch levels from before the edit —
      // EXCEPT the selected branch, which gets the value the user typed in the
      // form (handled below by _seedInventoryLevels).
      for (final nameEntry in variantNameToNewId.entries) {
        final name = nameEntry.key;
        final newId = nameEntry.value;
        final saved = savedLevels[name] ?? {};
        for (final branchEntry in saved.entries) {
          final branchId = branchEntry.key;
          if (branchId == selectedBranchId) continue; // form value wins
          await _levelsDao.upsertLevel(
            variantId: newId,
            branchId: branchId,
            businessId: businessId,
            quantity: branchEntry.value,
          );
        }
      }

      // Seed/update inventory_levels for the selected branch with the
      // quantities from the form. No-op when selectedBranchId is null.
      if (state.trackInventory && seeds.isNotEmpty) {
        await _seedInventoryLevels(seeds);
      }

      // Reconcile product_variants.stock with the real inventory_levels sum so
      // the edit form always shows the correct total on the next open, regardless
      // of which branch mode was active during this edit.
      if (state.trackInventory) {
        for (final newId in variantNameToNewId.values) {
          final levels = await _levelsDao.getByVariantId(newId);
          final total = levels.fold(0.0, (sum, l) => sum + l.quantity);
          await _productVariantsDao.updateVariantStock(newId, total);
        }
      }

      // Re-link recipe lines after re-insertion.
      if (data.trackingMethod == TrackingMethod.recipe) {
        if (hasVariants) {
          for (int i = 0; i < seeds.length && i < data.variants.length; i++) {
            final lines = data.variants[i].recipeLines;
            if (lines.isNotEmpty) {
              await _saveRecipeLines(seeds[i].variantId, lines);
            }
          }
        } else {
          final newDefaultId = variantNameToNewId['Default'];
          if (newDefaultId != null && data.recipeLines.isNotEmpty) {
            await _saveRecipeLines(newDefaultId, data.recipeLines);
          }
        }
      }

      // Record per-variant price movement (old → new) — the PRICE_REVERSAL
      // fraud rule needs it, and it can't be reconstructed later.
      final updatedVariants =
          await _productVariantsDao.getByProductId(productId);
      final oldPriceByName = {for (final v in oldVariants) v.name: v.price};
      final priceChanges = [
        for (final v in updatedVariants)
          if (oldPriceByName.containsKey(v.name) &&
              oldPriceByName[v.name] != v.price)
            {
              'variant': v.name,
              'old_price': oldPriceByName[v.name],
              'new_price': v.price,
            },
      ];

      sl<AuditLogService>().log(
        actionType: AuditLogActionType.productUpdated,
        entityType: 'product',
        entityName: data.name.trim(),
        description: 'Product updated: ${data.name.trim()}',
        metadata: {
          if (priceChanges.isNotEmpty) 'price_changes': priceChanges,
        },
        businessId: businessId,
      );

      emit(state.copyWith(isSaving: false, isSavingDraft: false, isSuccess: true));
    } catch (e, st) {
      debugPrint('[ProductFormCubit] Error in update: $e\n$st');
      emit(state.copyWith(isSaving: false, isSavingDraft: false, error: AppErrorMapper.message(e)));
    }
  }

  // ── Draft convenience wrappers ────────────────────────────────────────────

  Future<void> saveDraft(ProductFormData data) =>
      save(ProductFormData(
        name: data.name,
        simplePrice: data.simplePrice,
        simpleBarcode: data.simpleBarcode,
        sellingPrice: data.sellingPrice,
        retailPrice: data.retailPrice,
        costPrice: data.costPrice,
        taxPercent: data.taxPercent,
        stock: data.stock,
        lowStockAlert: data.lowStockAlert,
        sellBy: data.sellBy,
        unit: data.unit,
        barcodes: data.barcodes,
        sku: data.sku,
        variants: data.variants,
        imagePath: data.imagePath,
        trackingMethod: data.trackingMethod,
        recipeLines: data.recipeLines,
        isDraft: true,
      ));

  Future<void> updateDraft(String productId, ProductFormData data) =>
      update(productId, ProductFormData(
        name: data.name,
        simplePrice: data.simplePrice,
        simpleBarcode: data.simpleBarcode,
        sellingPrice: data.sellingPrice,
        retailPrice: data.retailPrice,
        costPrice: data.costPrice,
        taxPercent: data.taxPercent,
        stock: data.stock,
        lowStockAlert: data.lowStockAlert,
        sellBy: data.sellBy,
        unit: data.unit,
        barcodes: data.barcodes,
        sku: data.sku,
        variants: data.variants,
        imagePath: data.imagePath,
        trackingMethod: data.trackingMethod,
        recipeLines: data.recipeLines,
        isDraft: true,
      ));

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> save(ProductFormData data) async {
    if (data.isDraft) {
      emit(state.copyWith(isSavingDraft: true, clearError: true));
    } else {
      emit(state.copyWith(isSaving: true, clearError: true));
    }
    try {
      final productId = const Uuid().v4();
      final isAdvanced = state.mode == ProductFormMode.advanced;
      final isFraction = data.sellBy == 'fraction';
      final hasVariants = isAdvanced && state.hasVariants;

      final barcodeError = await _validateBarcodes(data, hasVariants);
      if (barcodeError != null) {
        emit(state.copyWith(
          isSaving: false,
          isSavingDraft: false,
          error: barcodeError,
        ));
        return;
      }

      // Parse tax (stored at product level)
      final tax = (data.taxPercent?.trim().isNotEmpty == true)
          ? double.tryParse(data.taxPercent!)
          : null;

      // Insert product row — product-level barcode is never used when hasVariants,
      // since POS lookup uses variant-level barcodes.
      await _productsDao.insertProduct(
        ProductsTableCompanion.insert(
          id: productId,
          businessId: businessId,
          name: data.name.trim(),
          categoryId: Value(state.selectedCategoryId),
          sku: Value(
            data.sku?.trim().isNotEmpty == true ? data.sku!.trim() : null,
          ),
          barcode: const Value(null),
          hasVariants: Value(hasVariants),
          tax: Value(tax),
          sellBy: Value(data.sellBy),
          imagePath: Value(data.imagePath),
          isActive: Value(!data.isDraft),
          trackingMethod: Value(data.trackingMethod.code),
        ),
      );

      // Collects (variantId, initialQty, initialQtyDecimal) for inventory seeding.
      final seeds = <({String variantId, double qty})>[];

      if (hasVariants) {
        // Advanced + variants ON: one row per variant with per-variant barcode.
        final companions = <ProductVariantsTableCompanion>[];
        for (final v in data.variants) {
          final id = const Uuid().v4();
          final vPrice = double.tryParse(v.price) ?? 0.0;
          final vCost = (v.costPrice?.trim().isNotEmpty == true)
              ? double.tryParse(v.costPrice!)
              : null;
          final vRetail = (v.retailPrice?.trim().isNotEmpty == true)
              ? double.tryParse(v.retailPrice!)
              : null;
          final vStock = state.trackInventory
              ? (double.tryParse(v.stock ?? '') ?? 0.0)
              : 0.0;
          final vLowAlert = (v.lowStockAlert?.trim().isNotEmpty == true)
              ? int.tryParse(v.lowStockAlert!)
              : null;
          companions.add(
            ProductVariantsTableCompanion.insert(
              id: id,
              productId: productId,
              businessId: businessId,
              name: v.name.trim().isEmpty ? 'Default' : v.name.trim(),
              price: Value(vPrice),
              costPrice: Value(vCost),
              retailPrice: Value(vRetail),
              // Barcodes now live in product_barcodes (see replaceForVariant).
              barcode: const Value(null),
              unit: Value(data.unit),
              stock: Value(vStock),
              lowStockAlert: Value(vLowAlert),
              trackStock: Value(state.trackInventory),
              trackExpiry: Value(state.trackExpiry),
              expiryDate: Value(state.trackExpiry ? state.expiryDate : null),
            ),
          );
          seeds.add((variantId: id, qty: vStock));
        }
        await _productVariantsDao.insertVariants(companions);
      } else if (isAdvanced) {
        // Advanced + variants OFF: single "Default" variant.
        final id = const Uuid().v4();
        // Store the tax-exclusive price. Tax is applied once at the cart layer
        // via the product's tax rate — storing it inclusive here double-taxes.
        final finalPrice = double.tryParse(data.sellingPrice ?? '') ?? 0.0;
        final cost = (data.costPrice?.trim().isNotEmpty == true)
            ? double.tryParse(data.costPrice!)
            : null;
        final retail = (data.retailPrice?.trim().isNotEmpty == true)
            ? double.tryParse(data.retailPrice!)
            : null;
        final stockValue = state.trackInventory
            ? (double.tryParse(data.stock ?? '') ?? 0.0)
            : 0.0;
        final lowAlert = (data.lowStockAlert?.trim().isNotEmpty == true)
            ? int.tryParse(data.lowStockAlert!)
            : null;
        await _productVariantsDao.insertVariant(
          ProductVariantsTableCompanion.insert(
            id: id,
            productId: productId,
            businessId: businessId,
            name: 'Default',
            price: Value(finalPrice),
            costPrice: Value(cost),
            retailPrice: Value(retail),
            // Barcodes now live in product_barcodes (see replaceForVariant).
            barcode: const Value(null),
            unit: Value(data.unit),
            stock: Value(stockValue),
            lowStockAlert: Value(lowAlert),
            trackStock: Value(state.trackInventory),
            trackExpiry: Value(state.trackExpiry),
            expiryDate: Value(state.trackExpiry ? state.expiryDate : null),
          ),
        );
        seeds.add((variantId: id, qty: stockValue));
      } else {
        // Simple mode: no inventory tracking — skip seeding entirely.
        final price = double.tryParse(data.simplePrice ?? '') ?? 0.0;
        final simpleBarcode = data.simpleBarcode?.trim();
        await _productVariantsDao.insertVariant(
          ProductVariantsTableCompanion.insert(
            id: const Uuid().v4(),
            productId: productId,
            businessId: businessId,
            name: 'Default',
            price: Value(price),
            costPrice: const Value(null),
            retailPrice: const Value(null),
            stock: const Value(0.0),
            lowStockAlert: const Value(null),
            barcode: Value(
              simpleBarcode?.isNotEmpty == true ? simpleBarcode : null,
            ),
            trackStock: const Value(false),
            trackExpiry: const Value(false),
            expiryDate: const Value(null),
          ),
        );
      }

      // Persist barcodes into the normalized store (before the branch-assignment
      // early-return below, so a deferred-stock save still writes them).
      if (hasVariants) {
        for (int i = 0; i < seeds.length && i < data.variants.length; i++) {
          await _productBarcodesDao.replaceForVariant(
            seeds[i].variantId,
            businessId,
            data.variants[i].barcodes,
          );
        }
      } else if (seeds.isNotEmpty) {
        await _productBarcodesDao.replaceForVariant(
          seeds.first.variantId,
          businessId,
          data.barcodes,
        );
      }

      // Seed inventory_levels for tracked variants after product creation.
      if (state.trackInventory && seeds.isNotEmpty) {
        final hasActualStock = seeds.any((s) => s.qty > 0);

        if (selectedBranchId == null && hasActualStock) {
          // All Branches + real opening stock → defer seeding; show dialog so
          // the user can nominate which branch receives the entered quantity.
          emit(
            state.copyWith(
              isSaving: false,
              isSavingDraft: false,
              isSuccess: true,
              pendingBranchAssignment: (
                variants: seeds,
                isFraction: isFraction,
              ),
            ),
          );
          return;
        }

        await _seedInventoryLevels(seeds);
      }

      // Save recipe lines per variant (variants mode) or for the single
      // Default variant (no-variants mode).
      if (data.trackingMethod == TrackingMethod.recipe) {
        if (hasVariants) {
          for (int i = 0; i < seeds.length && i < data.variants.length; i++) {
            final lines = data.variants[i].recipeLines;
            if (lines.isNotEmpty) {
              await _saveRecipeLines(seeds[i].variantId, lines);
            }
          }
        } else if (data.recipeLines.isNotEmpty && seeds.isNotEmpty) {
          await _saveRecipeLines(seeds.first.variantId, data.recipeLines);
        }
      }

      sl<AuditLogService>().log(
        actionType: AuditLogActionType.productCreated,
        entityType: 'product',
        entityName: data.name.trim(),
        description: data.isDraft
            ? 'Product saved as draft: ${data.name.trim()}'
            : 'Product created: ${data.name.trim()}',
        metadata: {'is_draft': data.isDraft},
        businessId: businessId,
      );

      emit(state.copyWith(isSaving: false, isSavingDraft: false, isSuccess: true));
    } catch (e, st) {
      debugPrint('[ProductFormCubit] Error in save: $e\n$st');
      emit(state.copyWith(isSaving: false, isSavingDraft: false, error: AppErrorMapper.message(e)));
    }
  }

  // ── Inventory seeding ─────────────────────────────────────────────────────

  /// Seeds [inventory_levels] for the specific branch selected at save time.
  /// When [selectedBranchId] is null (All Branches), this is a no-op — the
  /// branch assignment dialog handles seeding via [assignInventoryToBranch].
  Future<void> _seedInventoryLevels(
    List<({String variantId, double qty})> variants,
  ) async {
    if (selectedBranchId == null) return;

    for (final v in variants) {
      await _levelsDao.upsertLevel(
        variantId: v.variantId,
        branchId: selectedBranchId!,
        businessId: businessId,
        quantity: v.qty,
      );
    }
  }

  /// Called by the All-Branches assignment dialog after the user picks a branch.
  /// Writes inventory_levels rows for the chosen branch using the opening-stock
  /// quantities that were entered in the form.
  Future<void> assignInventoryToBranch(String branchId) async {
    final pending = state.pendingBranchAssignment;
    if (pending == null) return;
    for (final v in pending.variants) {
      await _levelsDao.upsertLevel(
        variantId: v.variantId,
        branchId: branchId,
        businessId: businessId,
        quantity: v.qty,
      );
    }
    emit(state.copyWith(clearPendingBranchAssignment: true));
  }

  // ── Recipe lines ──────────────────────────────────────────────────────────

  Future<void> _saveRecipeLines(
    String variantId,
    List<RecipeLineFormEntry> lines,
  ) {
    final companions = lines
        .map(
          (l) => RecipeLinesTableCompanion.insert(
            id: const Uuid().v4(),
            businessId: businessId,
            productVariantId: variantId,
            ingredientVariantId: l.ingredientVariantId,
            ingredientName: l.ingredientName,
            quantity: Value(l.quantity),
            unit: Value(l.unit),
          ),
        )
        .toList();
    return _recipeLinesDao.replaceForVariant(variantId, companions);
  }
}
