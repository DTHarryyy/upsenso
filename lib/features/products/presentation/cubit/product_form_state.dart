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
  final bool isSavingDraft;
  final bool isUploadingImage;
  final bool isSuccess;
  final String? error;
  final String? imagePath;

  /// Set after a successful new-product save when "All Branches" was active
  /// and the user entered opening stock > 0. The UI shows a branch-selection
  /// dialog so the user can nominate which branch receives the stock.
  final ({
    List<({String variantId, int qty, double? qtyDecimal})> variants,
    bool isFraction,
  })? pendingBranchAssignment;

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
    required this.isSavingDraft,
    required this.isUploadingImage,
    required this.isSuccess,
    this.error,
    this.imagePath,
    this.pendingBranchAssignment,
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
        isSavingDraft: false,
        isUploadingImage: false,
        isSuccess: false,
        error: null,
        imagePath: null,
        pendingBranchAssignment: null,
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
    bool? isSavingDraft,
    bool? isUploadingImage,
    bool? isSuccess,
    String? error,
    bool clearError = false,
    String? imagePath,
    bool clearImagePath = false,
    ({
      List<({String variantId, int qty, double? qtyDecimal})> variants,
      bool isFraction,
    })? pendingBranchAssignment,
    bool clearPendingBranchAssignment = false,
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
      isSavingDraft: isSavingDraft ?? this.isSavingDraft,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
      isSuccess: isSuccess ?? this.isSuccess,
      error: clearError ? null : (error ?? this.error),
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      pendingBranchAssignment: clearPendingBranchAssignment
          ? null
          : (pendingBranchAssignment ?? this.pendingBranchAssignment),
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
  final String? barcode;

  const VariantFormData({
    required this.name,
    required this.price,
    this.costPrice,
    this.stock,
    this.lowStockAlert,
    this.barcode,
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
  final String? imagePath;

  /// When true the product is saved with isActive=false (not visible on POS).
  final bool isDraft;

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
    this.imagePath,
    this.isDraft = false,
  });
}
