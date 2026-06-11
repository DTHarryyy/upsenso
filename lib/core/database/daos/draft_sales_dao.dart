import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/draft_sales_table.dart';
import 'package:pos/core/database/tables/draft_sale_items_table.dart';

part 'draft_sales_dao.g.dart';

/// Data access for held / suspended sales. All writes are local; nothing here
/// touches Supabase (Phase 1 drafts are device-local).
@DriftAccessor(tables: [DraftSalesTable, DraftSaleItemsTable])
class DraftSalesDao extends DatabaseAccessor<AppDatabase>
    with _$DraftSalesDaoMixin {
  DraftSalesDao(super.db);

  /// Atomically replaces a draft and all its line-items. Used for both create
  /// and re-save (resume → edit → hold again with the same id).
  Future<void> upsertDraft(
    DraftSalesTableCompanion draft,
    List<DraftSaleItemsTableCompanion> items,
  ) async {
    await transaction(() async {
      await into(draftSalesTable).insertOnConflictUpdate(draft);
      await (delete(
        draftSaleItemsTable,
      )..where((t) => t.draftId.equals(draft.id.value))).go();
      if (items.isNotEmpty) {
        await batch((b) {
          for (final item in items) {
            b.insert(draftSaleItemsTable, item);
          }
        });
      }
    });
  }

  /// Watch all open (not converted / not discarded) drafts, newest first.
  Stream<List<DraftSalesTableData>> watchOpenDrafts({String? branchId}) {
    final query = select(draftSalesTable)
      ..where((t) => t.status.equals('open') & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      ]);
    if (branchId != null) {
      query.where((t) => t.branchId.equals(branchId));
    }
    return query.watch();
  }

  /// Reactive count of open drafts (for the POS badge), optionally per-branch.
  Stream<int> watchOpenDraftCount({String? branchId}) {
    final countExp = draftSalesTable.id.count();
    final query = selectOnly(draftSalesTable)
      ..addColumns([countExp])
      ..where(
        draftSalesTable.status.equals('open') &
            draftSalesTable.deletedAt.isNull(),
      );
    if (branchId != null) {
      query.where(draftSalesTable.branchId.equals(branchId));
    }
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<DraftSalesTableData?> getById(String id) {
    return (select(
      draftSalesTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<DraftSaleItemsTableData>> getItems(String draftId) {
    return (select(
      draftSaleItemsTable,
    )..where((t) => t.draftId.equals(draftId))).get();
  }

  /// Marks a draft converted and soft-deletes it (kept for the audit trail).
  Future<void> markConverted(String id) async {
    await (update(draftSalesTable)..where((t) => t.id.equals(id))).write(
      DraftSalesTableCompanion(
        status: const Value('converted'),
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Marks a draft resumed and soft-deletes it. Resuming pops the held sale
  /// back into the live cart, so it leaves the held list immediately.
  Future<void> markResumed(String id) async {
    await (update(draftSalesTable)..where((t) => t.id.equals(id))).write(
      DraftSalesTableCompanion(
        status: const Value('resumed'),
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Marks a draft voided and soft-deletes it.
  Future<void> discard(String id) async {
    await (update(draftSalesTable)..where((t) => t.id.equals(id))).write(
      DraftSalesTableCompanion(
        status: const Value('voided'),
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Wipe everything (logout / account switch).
  Future<void> clearAll() async {
    await delete(draftSaleItemsTable).go();
    await delete(draftSalesTable).go();
  }
}
