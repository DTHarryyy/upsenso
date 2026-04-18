import 'package:drift/drift.dart' show Value;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pos/core/services/image_service.dart';
import 'product_form_state.dart';

class ProductFormCubit extends Cubit<ProductFormState> {
  ProductFormCubit({
    required this.businessId,
    this.selectedBranchId,
  }) : super(ProductFormState.initial()) {
    _loadCategories();
  }

  final String businessId;

  /// The branch UUID currently selected in the top-right dropdown.
  /// null means "All Branches" — see [_seedInventoryLevels] for handling.
  final String? selectedBranchId;

  final _categoriesDao = sl<CategoriesDao>();
  final _productsDao = sl<ProductsDao>();
  final _productVariantsDao = sl<ProductVariantsDao>();
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

  void setTrackInventory(bool value) =>
      emit(state.copyWith(trackInventory: value));

  void setTrackExpiry(bool value) {
    if (!value) {
      emit(state.copyWith(trackExpiry: false, clearExpiryDate: true));
    } else {
      emit(state.copyWith(trackExpiry: true));
    }
  }

  void setExpiryDate(DateTime date) =>
      emit(state.copyWith(expiryDate: date));

  void toggleMoreOptions() =>
      emit(state.copyWith(moreOptionsExpanded: !state.moreOptionsExpanded));

  void selectCategory(String? id) =>
      emit(state.copyWith(selectedCategoryId: id));

  // ── Image ─────────────────────────────────────────────────────────────────

  Future<void> pickImage(ImageSource source) async {
    final path = await _imageService.pickAndSaveImage(source: source);
    if (path != null) emit(state.copyWith(imagePath: path));
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
    final suffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '$prefix-$suffix';
  }

  // ── Edit existing product ─────────────────────────────────────────────────

  /// Initialise cubit state from an existing product (called when editing).
  void initEditState(ProductsTableData product) {
    emit(state.copyWith(
      mode: product.hasVariants ? ProductFormMode.advanced : ProductFormMode.simple,
      hasVariants: product.hasVariants,
      selectedCategoryId: product.categoryId,
      imagePath: product.imagePath,
      trackInventory: false, // updated after loading variants
    ));
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
  Future<Map<String, int>> loadBranchStockMap(List<String> variantIds) async {
    final result = <String, int>{};
    if (selectedBranchId == null) {
      for (final id in variantIds) {
        final levels = await _levelsDao.getByVariantId(id);
        if (levels.isNotEmpty) {
          result[id] = levels.fold(0, (sum, l) => sum + l.quantity);
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
    return newId;
  }

  // ── Update (edit mode) ────────────────────────────────────────────────────

  Future<void> update(String productId, ProductFormData data) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      final isAdvanced = state.mode == ProductFormMode.advanced;
      final isFraction = data.sellBy == 'fraction';
      final hasVariants = isAdvanced && state.hasVariants;

      final tax = (data.taxPercent?.trim().isNotEmpty == true)
          ? double.tryParse(data.taxPercent!)
          : null;

      // Update product row
      await _productsDao.updateProduct(
        productId,
        ProductsTableCompanion(
          name: Value(data.name.trim()),
          categoryId: Value(state.selectedCategoryId),
          sku: Value(data.sku?.trim().isNotEmpty == true ? data.sku!.trim() : null),
          hasVariants: Value(hasVariants),
          tax: Value(tax),
          sellBy: Value(data.sellBy),
          imagePath: Value(data.imagePath),
          syncStatus: const Value(1), // pendingUpdate
        ),
      );

      // Snapshot existing inventory levels (keyed by variant name) before
      // deleting variants. This lets us re-link levels to new variant UUIDs
      // so other branches don't lose their stock when one branch edits.
      final oldVariants = await _productVariantsDao.getByProductId(productId);
      // variantName → { branchId → (qty, qtyDecimal) }
      final savedLevels =
          <String, Map<String, ({int qty, double? qtyDec})>>{};
      for (final v in oldVariants) {
        final levels = await _levelsDao.getByVariantId(v.id);
        if (levels.isNotEmpty) {
          savedLevels[v.name] = {
            for (final l in levels)
              l.branchId: (qty: l.quantity, qtyDec: l.quantityDecimal),
          };
        }
      }

      // Delete all existing variants and re-insert from form data
      await _productVariantsDao.deleteByProductId(productId);

      final variantBarcode = data.barcodes
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .join(',');

      // variantName → newId — used to restore saved levels after insert.
      final variantNameToNewId = <String, String>{};
      final seeds = <({String variantId, int qty, double? qtyDecimal})>[];

      if (hasVariants) {
        final companions = <ProductVariantsTableCompanion>[];
        for (final v in data.variants) {
          final id = const Uuid().v4();
          final name = v.name.trim().isEmpty ? 'Default' : v.name.trim();
          final vPrice = double.tryParse(v.price) ?? 0.0;
          final vCost = (v.costPrice?.trim().isNotEmpty == true)
              ? double.tryParse(v.costPrice!)
              : null;
          final vStockInt = (state.trackInventory && !isFraction)
              ? (int.tryParse(v.stock ?? '') ?? 0)
              : 0;
          final vStockReal = (state.trackInventory && isFraction)
              ? double.tryParse(v.stock ?? '')
              : null;
          final vLowAlert = (v.lowStockAlert?.trim().isNotEmpty == true)
              ? int.tryParse(v.lowStockAlert!)
              : null;
          final vBarcode = (v.barcode?.trim().isNotEmpty == true)
              ? v.barcode!.trim()
              : null;
          companions.add(ProductVariantsTableCompanion.insert(
            id: id,
            productId: productId,
            businessId: businessId,
            name: name,
            price: Value(vPrice),
            costPrice: Value(vCost),
            retailPrice: const Value(null),
            barcode: Value(vBarcode),
            stock: Value(vStockInt),
            stockDecimal: Value(vStockReal),
            lowStockAlert: Value(vLowAlert),
            trackStock: Value(state.trackInventory),
            trackExpiry: Value(state.trackExpiry),
            expiryDate: Value(state.trackExpiry ? state.expiryDate : null),
          ));
          variantNameToNewId[name] = id;
          seeds.add((variantId: id, qty: vStockInt, qtyDecimal: vStockReal));
        }
        await _productVariantsDao.insertVariants(companions);
      } else if (isAdvanced) {
        final id = const Uuid().v4();
        final price = double.tryParse(data.sellingPrice ?? '') ?? 0.0;
        // Apply tax to get the tax-inclusive price stored & displayed to customers.
        final taxRate = tax != null ? tax / 100.0 : 0.0;
        final finalPrice = taxRate > 0 ? price * (1 + taxRate) : price;
        final cost = (data.costPrice?.trim().isNotEmpty == true)
            ? double.tryParse(data.costPrice!)
            : null;
        final retail = (data.retailPrice?.trim().isNotEmpty == true)
            ? double.tryParse(data.retailPrice!)
            : null;
        final stockInt = (state.trackInventory && !isFraction)
            ? (int.tryParse(data.stock ?? '') ?? 0)
            : 0;
        final stockReal = (state.trackInventory && isFraction)
            ? double.tryParse(data.stock ?? '')
            : null;
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
            barcode: Value(variantBarcode.isNotEmpty ? variantBarcode : null),
            stock: Value(stockInt),
            stockDecimal: Value(stockReal),
            lowStockAlert: Value(lowAlert),
            trackStock: Value(state.trackInventory),
            trackExpiry: Value(state.trackExpiry),
            expiryDate: Value(state.trackExpiry ? state.expiryDate : null),
          ),
        );
        variantNameToNewId['Default'] = id;
        seeds.add((variantId: id, qty: stockInt, qtyDecimal: stockReal));
      } else {
        // Simple mode — no inventory tracking
        final id = const Uuid().v4();
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
            stock: const Value(0),
            stockDecimal: const Value(null),
            lowStockAlert: const Value(null),
            barcode: Value(simpleBarcode?.isNotEmpty == true ? simpleBarcode : null),
            trackStock: const Value(false),
            trackExpiry: const Value(false),
            expiryDate: const Value(null),
          ),
        );
        variantNameToNewId['Default'] = id;
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
            quantity: branchEntry.value.qty,
            quantityDecimal: branchEntry.value.qtyDec,
          );
        }
      }

      // Seed/update inventory_levels for the selected branch with the
      // quantities from the form. No-op when selectedBranchId is null.
      if (state.trackInventory && seeds.isNotEmpty) {
        await _seedInventoryLevels(seeds, isFraction);
      }

      // Reconcile product_variants.stock with the real inventory_levels sum so
      // the edit form always shows the correct total on the next open, regardless
      // of which branch mode was active during this edit.
      if (state.trackInventory) {
        for (final newId in variantNameToNewId.values) {
          final levels = await _levelsDao.getByVariantId(newId);
          final total = levels.fold(0, (sum, l) => sum + l.quantity);
          await _productVariantsDao.updateVariantStock(newId, total);
        }
      }

      emit(state.copyWith(isSaving: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: e.toString()));
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> save(ProductFormData data) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      final productId = const Uuid().v4();
      final isAdvanced = state.mode == ProductFormMode.advanced;
      final isFraction = data.sellBy == 'fraction';
      final hasVariants = isAdvanced && state.hasVariants;

      // Build barcode string for the Default variant (Advanced + No Variants).
      // When hasVariants=true, barcodes live at variant level — not product level.
      final variantBarcode = data.barcodes
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .join(',');

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
          sku: Value(data.sku?.trim().isNotEmpty == true ? data.sku!.trim() : null),
          barcode: const Value(null),
          hasVariants: Value(hasVariants),
          tax: Value(tax),
          sellBy: Value(data.sellBy),
          imagePath: Value(data.imagePath),
          isActive: const Value(true),
        ),
      );

      // Collects (variantId, initialQty, initialQtyDecimal) for inventory seeding.
      final seeds = <({String variantId, int qty, double? qtyDecimal})>[];

      if (hasVariants) {
        // Advanced + variants ON: one row per variant with per-variant barcode.
        final companions = <ProductVariantsTableCompanion>[];
        for (final v in data.variants) {
          final id = const Uuid().v4();
          final vPrice = double.tryParse(v.price) ?? 0.0;
          final vCost = (v.costPrice?.trim().isNotEmpty == true)
              ? double.tryParse(v.costPrice!)
              : null;
          final vStockInt = (state.trackInventory && !isFraction)
              ? (int.tryParse(v.stock ?? '') ?? 0)
              : 0;
          final vStockReal = (state.trackInventory && isFraction)
              ? double.tryParse(v.stock ?? '')
              : null;
          final vLowAlert = (v.lowStockAlert?.trim().isNotEmpty == true)
              ? int.tryParse(v.lowStockAlert!)
              : null;
          final vBarcode = (v.barcode?.trim().isNotEmpty == true)
              ? v.barcode!.trim()
              : null;
          companions.add(ProductVariantsTableCompanion.insert(
            id: id,
            productId: productId,
            businessId: businessId,
            name: v.name.trim().isEmpty ? 'Default' : v.name.trim(),
            price: Value(vPrice),
            costPrice: Value(vCost),
            retailPrice: const Value(null),
            barcode: Value(vBarcode),
            stock: Value(vStockInt),
            stockDecimal: Value(vStockReal),
            lowStockAlert: Value(vLowAlert),
            trackStock: Value(state.trackInventory),
            trackExpiry: Value(state.trackExpiry),
            expiryDate: Value(state.trackExpiry ? state.expiryDate : null),
          ));
          seeds.add((variantId: id, qty: vStockInt, qtyDecimal: vStockReal));
        }
        await _productVariantsDao.insertVariants(companions);
      } else if (isAdvanced) {
        // Advanced + variants OFF: single "Default" variant.
        final id = const Uuid().v4();
        final price = double.tryParse(data.sellingPrice ?? '') ?? 0.0;
        // Apply tax to get the tax-inclusive price stored & displayed to customers.
        final taxRate = tax != null ? tax / 100.0 : 0.0;
        final finalPrice = taxRate > 0 ? price * (1 + taxRate) : price;
        final cost = (data.costPrice?.trim().isNotEmpty == true)
            ? double.tryParse(data.costPrice!)
            : null;
        final retail = (data.retailPrice?.trim().isNotEmpty == true)
            ? double.tryParse(data.retailPrice!)
            : null;
        final stockInt = (state.trackInventory && !isFraction)
            ? (int.tryParse(data.stock ?? '') ?? 0)
            : 0;
        final stockReal = (state.trackInventory && isFraction)
            ? double.tryParse(data.stock ?? '')
            : null;
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
            barcode: Value(variantBarcode.isNotEmpty ? variantBarcode : null),
            stock: Value(stockInt),
            stockDecimal: Value(stockReal),
            lowStockAlert: Value(lowAlert),
            trackStock: Value(state.trackInventory),
            trackExpiry: Value(state.trackExpiry),
            expiryDate: Value(state.trackExpiry ? state.expiryDate : null),
          ),
        );
        seeds.add((variantId: id, qty: stockInt, qtyDecimal: stockReal));
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
            stock: const Value(0),
            stockDecimal: const Value(null),
            lowStockAlert: const Value(null),
            barcode: Value(simpleBarcode?.isNotEmpty == true ? simpleBarcode : null),
            trackStock: const Value(false),
            trackExpiry: const Value(false),
            expiryDate: const Value(null),
          ),
        );
      }

      // Seed inventory_levels for tracked variants after product creation.
      if (state.trackInventory && seeds.isNotEmpty) {
        final hasActualStock = seeds.any(
          (s) => s.qty > 0 || (s.qtyDecimal != null && s.qtyDecimal! > 0),
        );

        if (selectedBranchId == null && hasActualStock) {
          // All Branches + real opening stock → defer seeding; show dialog so
          // the user can nominate which branch receives the entered quantity.
          emit(state.copyWith(
            isSaving: false,
            isSuccess: true,
            pendingBranchAssignment: (variants: seeds, isFraction: isFraction),
          ));
          return;
        }

        await _seedInventoryLevels(seeds, isFraction);
      }

      emit(state.copyWith(isSaving: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: e.toString()));
    }
  }

  // ── Inventory seeding ─────────────────────────────────────────────────────

  /// Seeds [inventory_levels] for the specific branch selected at save time.
  /// When [selectedBranchId] is null (All Branches), this is a no-op — the
  /// branch assignment dialog handles seeding via [assignInventoryToBranch].
  Future<void> _seedInventoryLevels(
    List<({String variantId, int qty, double? qtyDecimal})> variants,
    bool isFraction,
  ) async {
    if (selectedBranchId == null) return;

    for (final v in variants) {
      await _levelsDao.upsertLevel(
        variantId: v.variantId,
        branchId: selectedBranchId!,
        businessId: businessId,
        quantity: v.qty,
        quantityDecimal: isFraction ? v.qtyDecimal : null,
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
        quantityDecimal: pending.isFraction ? v.qtyDecimal : null,
      );
    }
    emit(state.copyWith(clearPendingBranchAssignment: true));
  }
}
