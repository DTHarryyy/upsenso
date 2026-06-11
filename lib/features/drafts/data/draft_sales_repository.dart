import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/draft_sales_dao.dart';
import 'package:pos/features/drafts/domain/entities/draft_sale.dart';
import 'package:pos/features/drafts/domain/entities/draft_sale_item.dart';
import 'package:pos/features/drafts/domain/repositories/i_draft_sales_repository.dart';

/// Drift-backed implementation of [IDraftSalesRepository].
/// Maps Drift rows to pure domain entities so the presentation layer never
/// sees generated table types.
class DraftSalesRepository implements IDraftSalesRepository {
  final DraftSalesDao _dao;
  static const _uuid = Uuid();

  const DraftSalesRepository(this._dao);

  @override
  Stream<List<DraftSale>> watchOpenDrafts({String? branchId}) {
    return _dao
        .watchOpenDrafts(branchId: branchId)
        .map((rows) => rows.map(_mapDraft).toList());
  }

  @override
  Stream<int> watchOpenDraftCount({String? branchId}) =>
      _dao.watchOpenDraftCount(branchId: branchId);

  @override
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
  }) async {
    final now = DateTime.now();
    final existing = await _dao.getById(id);

    final draft = DraftSalesTableCompanion.insert(
      id: id,
      businessId: Value(businessId),
      branchId: Value(branchId),
      cashierId: cashierId,
      label: Value(label),
      customerName: Value(customerName),
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: Value(discountAmount),
      totalAmount: totalAmount,
      itemCount: itemCount,
      discountType: Value(discountType),
      discountValue: Value(discountValue),
      // Preserve the original createdAt across re-saves; only bump updatedAt.
      createdAt: Value(existing?.createdAt ?? now),
      updatedAt: Value(now),
    );

    final itemCompanions = items
        .map(
          (i) => DraftSaleItemsTableCompanion.insert(
            id: _uuid.v4(),
            draftId: id,
            variantId: i.variantId,
            productName: i.productName,
            variantName: i.variantName,
            unitPrice: i.unitPrice,
            taxRate: Value(i.taxRate),
            qty: i.qty,
            lineTotal: i.lineTotal,
            lineTax: i.lineTax,
          ),
        )
        .toList();

    await _dao.upsertDraft(draft, itemCompanions);
  }

  @override
  Future<DraftSale?> getDraft(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _mapDraft(row);
  }

  @override
  Future<List<DraftSaleItem>> getItems(String id) async {
    final rows = await _dao.getItems(id);
    return rows.map(_mapItem).toList();
  }

  @override
  Future<void> markConverted(String id) => _dao.markConverted(id);

  @override
  Future<void> markResumed(String id) => _dao.markResumed(id);

  @override
  Future<void> discard(String id) => _dao.discard(id);

  // ── Mappers ────────────────────────────────────────────────────────────────

  static DraftSale _mapDraft(DraftSalesTableData r) => DraftSale(
    id: r.id,
    label: r.label,
    customerName: r.customerName,
    subtotal: r.subtotal,
    taxAmount: r.taxAmount,
    discountAmount: r.discountAmount,
    totalAmount: r.totalAmount,
    itemCount: r.itemCount,
    discountType: r.discountType,
    discountValue: r.discountValue,
    branchId: r.branchId,
    cashierId: r.cashierId,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  static DraftSaleItem _mapItem(DraftSaleItemsTableData r) => DraftSaleItem(
    variantId: r.variantId,
    productName: r.productName,
    variantName: r.variantName,
    unitPrice: r.unitPrice,
    taxRate: r.taxRate,
    qty: r.qty,
    lineTotal: r.lineTotal,
    lineTax: r.lineTax,
  );
}
