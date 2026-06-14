import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';

// Regression for H-4: a pull must not flip a local sale that hasn't been pushed
// yet to "synced" — doing so would stop it from ever uploading (a lost sale).
void main() {
  late AppDatabase db;
  late TransactionsDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = TransactionsDao(db);
  });

  tearDown(() async => db.close());

  Map<String, dynamic> serverRow(double total) => {
        'id': 't1',
        'cashier_id': 'c1',
        'branch_id': 'b1',
        'shift_id': null,
        'total_amount': total,
        'tax_amount': 0.0,
        'payment_method': 'cash',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

  Future<void> insertLocal({required int syncStatus, required double total}) {
    return dao.insertTransaction(
      TransactionsTableCompanion.insert(
        id: 't1',
        cashierId: 'c1',
        totalAmount: total,
        taxAmount: 0.0,
        subtotal: total,
        itemCount: 1,
        syncStatus: Value(syncStatus),
      ),
      const [],
    );
  }

  test('unsynced local sale is preserved and stays pending on pull', () async {
    await insertLocal(syncStatus: 0, total: 50.0); // pendingUpload

    await dao.upsertFromServer(serverRow(999.0));

    final tx = await (db.select(db.transactionsTable)
          ..where((t) => t.id.equals('t1')))
        .getSingleOrNull();
    expect(tx!.syncStatus, 0, reason: 'must remain pendingUpload');
    expect(tx.totalAmount, 50.0, reason: 'local data must be preserved');
  });

  test('synced local sale is refreshed from the server', () async {
    await insertLocal(syncStatus: 3, total: 50.0); // synced

    await dao.upsertFromServer(serverRow(75.0));

    final tx = await (db.select(db.transactionsTable)
          ..where((t) => t.id.equals('t1')))
        .getSingleOrNull();
    expect(tx!.totalAmount, 75.0);
  });
}
