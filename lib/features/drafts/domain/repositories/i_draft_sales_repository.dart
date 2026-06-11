import 'package:pos/features/drafts/domain/entities/draft_sale.dart';
import 'package:pos/features/drafts/domain/entities/draft_sale_item.dart';

/// Contract for held / suspended sales storage. Local-first; no remote access.
abstract interface class IDraftSalesRepository {
  /// Open drafts (newest first), optionally scoped to a branch.
  Stream<List<DraftSale>> watchOpenDrafts({String? branchId});

  /// Reactive count of open drafts (POS badge).
  Stream<int> watchOpenDraftCount({String? branchId});

  /// Create or replace a held sale. [id] is supplied by the caller so a
  /// resumed-then-re-held draft keeps its identity.
  Future<void> saveDraft({
    required String id,
    String? businessId,
    String? branchId,
    required String cashierId,
    String? label,
    String? customerName,
    required double subtotal,
    required double taxAmount,
    required double discountAmount,
    required double totalAmount,
    required int itemCount,
    String? discountType,
    double? discountValue,
    required List<DraftSaleItem> items,
  });

  Future<DraftSale?> getDraft(String id);

  Future<List<DraftSaleItem>> getItems(String id);

  /// Mark converted + soft-delete (called after a successful checkout).
  Future<void> markConverted(String id);

  /// Mark resumed + soft-delete (called when popped back into the live cart).
  Future<void> markResumed(String id);

  /// Discard (void + soft-delete).
  Future<void> discard(String id);
}
