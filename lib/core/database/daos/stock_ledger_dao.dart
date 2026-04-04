import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/stock_ledger_table.dart';

part 'stock_ledger_dao.g.dart';

@DriftAccessor(tables: [StockLedgerTable])
class StockLedgerDao extends DatabaseAccessor<AppDatabase>
    with _$StockLedgerDaoMixin {
  StockLedgerDao(super.db);

  /// Insert a new ledger entry.
  Future<void> insertEntry(StockLedgerTableCompanion companion) {
    return into(stockLedgerTable).insert(companion);
  }

  /// Get all ledger entries for a variant (newest first).
  Future<List<StockLedgerTableData>> getByVariantId(String variantId) {
    return (select(stockLedgerTable)
          ..where((t) => t.variantId.equals(variantId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Get all ledger entries for a business (newest first).
  Future<List<StockLedgerTableData>> getByBusinessId(String businessId) {
    return (select(stockLedgerTable)
          ..where((t) => t.businessId.equals(businessId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Watch all entries for a business — used to trigger inventory UI refresh.
  Stream<List<StockLedgerTableData>> watchByBusinessId(String businessId) {
    return (select(stockLedgerTable)
          ..where((t) => t.businessId.equals(businessId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Get pending-upload entries for sync.
  Future<List<StockLedgerTableData>> getPendingSync() {
    return (select(stockLedgerTable)
          ..where((t) => t.syncStatus.isIn([0, 4])))
        .get();
  }

  /// Clear all entries (e.g. on logout).
  Future<void> clearAll() {
    return delete(stockLedgerTable).go();
  }
}
