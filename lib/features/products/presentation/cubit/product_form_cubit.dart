import 'package:drift/drift.dart' show Value;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'product_form_state.dart';

class ProductFormCubit extends Cubit<ProductFormState> {
  ProductFormCubit({required this.businessId})
      : super(ProductFormState.initial()) {
    _loadCategories();
  }

  final String businessId;
  final _categoriesDao = sl<CategoriesDao>();
  final _productsDao = sl<ProductsDao>();
  final _productVariantsDao = sl<ProductVariantsDao>();

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

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> save(ProductFormData data) async {
    emit(state.copyWith(isSaving: true, clearError: true));
    try {
      final productId = const Uuid().v4();
      final isAdvanced = state.mode == ProductFormMode.advanced;
      final isFraction = data.sellBy == 'fraction';
      final hasVariants = isAdvanced && state.hasVariants;

      // Build barcode string (comma-separated non-empty entries)
      final barcode = data.barcodes
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .join(',');

      // Parse tax (stored at product level)
      final tax = (data.taxPercent?.trim().isNotEmpty == true)
          ? double.tryParse(data.taxPercent!)
          : null;

      // Insert product row
      await _productsDao.insertProduct(
        ProductsTableCompanion.insert(
          id: productId,
          businessId: businessId,
          name: data.name.trim(),
          categoryId: Value(state.selectedCategoryId),
          sku: Value(data.sku?.trim().isNotEmpty == true ? data.sku!.trim() : null),
          barcode: Value(barcode.isNotEmpty ? barcode : null),
          hasVariants: Value(hasVariants),
          tax: Value(tax),
          sellBy: Value(data.sellBy),
          isActive: const Value(true),
        ),
      );

      if (hasVariants) {
        // Advanced + variants ON: one row per variant
        final companions = data.variants.map((v) {
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
          return ProductVariantsTableCompanion.insert(
            id: const Uuid().v4(),
            productId: productId,
            businessId: businessId,
            name: v.name.trim().isEmpty ? 'Default' : v.name.trim(),
            price: Value(vPrice),
            costPrice: Value(vCost),
            retailPrice: const Value(null),
            stock: Value(vStockInt),
            stockDecimal: Value(vStockReal),
            lowStockAlert: Value(vLowAlert),
            trackExpiry: Value(state.trackExpiry),
            expiryDate: Value(
              state.trackExpiry ? state.expiryDate?.toIso8601String() : null,
            ),
          );
        }).toList();
        await _productVariantsDao.insertVariants(companions);
      } else if (isAdvanced) {
        // Advanced + variants OFF: single "Default" variant with full pricing
        final price = double.tryParse(data.sellingPrice ?? '') ?? 0.0;
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
            id: const Uuid().v4(),
            productId: productId,
            businessId: businessId,
            name: 'Default',
            price: Value(price),
            costPrice: Value(cost),
            retailPrice: Value(retail),
            stock: Value(stockInt),
            stockDecimal: Value(stockReal),
            lowStockAlert: Value(lowAlert),
            trackExpiry: Value(state.trackExpiry),
            expiryDate: Value(
              state.trackExpiry ? state.expiryDate?.toIso8601String() : null,
            ),
          ),
        );
      } else {
        // Simple mode: one "Default" variant, no inventory
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
            trackExpiry: const Value(false),
            expiryDate: const Value(null),
          ),
        );
      }

      emit(state.copyWith(isSaving: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: e.toString()));
    }
  }
}
