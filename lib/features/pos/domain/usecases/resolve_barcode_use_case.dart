import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';

// ── Result types ──────────────────────────────────────────────────────────────

sealed class BarcodeResult {
  const BarcodeResult();
}

/// A variant was found and is ready to add to the cart.
final class BarcodeResolved extends BarcodeResult {
  final String variantId;
  final String productName;

  /// Empty string for simple (single-variant) products.
  final String variantLabel;
  final double unitPrice;
  final double? taxRate;

  BarcodeResolved({
    required this.variantId,
    required this.productName,
    required this.variantLabel,
    required this.unitPrice,
    this.taxRate,
  });
}

/// The scanned barcode belongs to a variant that is inactive.
final class BarcodeInactive extends BarcodeResult {
  const BarcodeInactive();
}

/// Product found via product-level barcode but has no active variants.
final class BarcodeNoVariants extends BarcodeResult {
  final String productName;
  const BarcodeNoVariants(this.productName);
}

/// Product has multiple active variants — user must scan a variant barcode.
final class BarcodeAmbiguous extends BarcodeResult {
  final String productName;
  const BarcodeAmbiguous(this.productName);
}

/// No product or variant matched the scanned barcode.
final class BarcodeUnknown extends BarcodeResult {
  const BarcodeUnknown();
}

// ── Use case ──────────────────────────────────────────────────────────────────

/// Resolves a raw barcode string into a typed [BarcodeResult].
///
/// Lookup order:
/// 1. Variant-level barcode (most specific).
/// 2. Product-level barcode (fallback for simple products).
///
/// All database errors are caught and rethrown as [BarcodeResolutionException]
/// so callers don't need to know about database internals.
class ResolveBarcodeUseCase {
  final ProductVariantsDao _variantsDao;
  final ProductsDao _productsDao;

  const ResolveBarcodeUseCase({
    required ProductVariantsDao variantsDao,
    required ProductsDao productsDao,
  })  : _variantsDao = variantsDao,
        _productsDao = productsDao;

  Future<BarcodeResult> call(String barcode, String businessId) async {
    try {
      // 1. Try variant-level barcode first (most specific match).
      final variant = await _variantsDao.getByBarcode(barcode, businessId);
      if (variant != null) {
        if (!variant.isActive) return const BarcodeInactive();

        final product = await _productsDao.getById(variant.productId);
        return BarcodeResolved(
          variantId: variant.id,
          productName: product?.name ?? variant.name,
          variantLabel: (product?.hasVariants ?? false) ? variant.name : '',
          unitPrice: variant.price,
          taxRate: product?.tax,
        );
      }

      // 2. Fallback: product-level barcode (simple products only).
      final product = await _productsDao.getByBarcode(barcode, businessId);
      if (product != null) {
        final variants = await _variantsDao.getByProductId(product.id);
        final active = variants.where((v) => v.isActive).toList();

        if (active.isEmpty) return BarcodeNoVariants(product.name);
        if (active.length > 1) return BarcodeAmbiguous(product.name);

        final v = active.first;
        return BarcodeResolved(
          variantId: v.id,
          productName: product.name,
          variantLabel: '',
          unitPrice: v.price,
          taxRate: product.tax,
        );
      }

      return const BarcodeUnknown();
    } catch (e, stack) {
      throw BarcodeResolutionException(e, stack);
    }
  }
}

/// Wraps any database / IO error that occurs during barcode resolution.
class BarcodeResolutionException implements Exception {
  final Object cause;
  final StackTrace stack;
  const BarcodeResolutionException(this.cause, this.stack);

  @override
  String toString() => 'BarcodeResolutionException: $cause';
}
