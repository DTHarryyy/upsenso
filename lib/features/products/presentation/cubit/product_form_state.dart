import 'package:pos/core/database/app_database.dart';

enum ProductFormMode { simple, advanced }

class ProductFormState {
  final ProductFormMode mode;
  final bool hasVariants;
  final bool trackInventory;
  final bool trackExpiry;
  final DateTime? expiryDate;
  final bool moreOptionsExpanded;
  final String? selectedCategoryId;
  final List<CategoriesTableData> categories;
  final bool isSaving;
  final bool isSuccess;
  final String? error;

  const ProductFormState({
    required this.mode,
    required this.hasVariants,
    required this.trackInventory,
    required this.trackExpiry,
    this.expiryDate,
    required this.moreOptionsExpanded,
    this.selectedCategoryId,
    required this.categories,
    required this.isSaving,
    required this.isSuccess,
    this.error,
  });

  factory ProductFormState.initial() => const ProductFormState(
        mode: ProductFormMode.simple,
        hasVariants: false,
        trackInventory: false,
        trackExpiry: false,
        expiryDate: null,
        moreOptionsExpanded: false,
        selectedCategoryId: null,
        categories: [],
        isSaving: false,
        isSuccess: false,
        error: null,
      );

  ProductFormState copyWith({
    ProductFormMode? mode,
    bool? hasVariants,
    bool? trackInventory,
    bool? trackExpiry,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    bool? moreOptionsExpanded,
    String? selectedCategoryId,
    bool clearCategoryId = false,
    List<CategoriesTableData>? categories,
    bool? isSaving,
    bool? isSuccess,
    String? error,
    bool clearError = false,
  }) {
    return ProductFormState(
      mode: mode ?? this.mode,
      hasVariants: hasVariants ?? this.hasVariants,
      trackInventory: trackInventory ?? this.trackInventory,
      trackExpiry: trackExpiry ?? this.trackExpiry,
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      moreOptionsExpanded: moreOptionsExpanded ?? this.moreOptionsExpanded,
      selectedCategoryId: clearCategoryId
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      categories: categories ?? this.categories,
      isSaving: isSaving ?? this.isSaving,
      isSuccess: isSuccess ?? this.isSuccess,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── DTOs passed from UI to cubit.save() ──────────────────────────────────────

class VariantFormData {
  final String name;
  final String price;
  final String? costPrice;
  final String? stock;
  final String? lowStockAlert;

  const VariantFormData({
    required this.name,
    required this.price,
    this.costPrice,
    this.stock,
    this.lowStockAlert,
  });
}

class ProductFormData {
  // Simple mode
  final String? simplePrice;
  final String? simpleBarcode;

  // Advanced no-variants
  final String? sellingPrice;
  final String? retailPrice;
  final String? costPrice;
  final String? taxPercent;
  final String? stock;
  final String? lowStockAlert;

  // Shared
  final String name;
  final String sellBy;
  final List<String> barcodes;
  final String? sku;
  final List<VariantFormData> variants;

  const ProductFormData({
    required this.name,
    this.simplePrice,
    this.simpleBarcode,
    this.sellingPrice,
    this.retailPrice,
    this.costPrice,
    this.taxPercent,
    this.stock,
    this.lowStockAlert,
    required this.sellBy,
    required this.barcodes,
    this.sku,
    required this.variants,
  });
}
