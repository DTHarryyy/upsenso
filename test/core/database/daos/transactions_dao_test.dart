import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/sync/sync_status.dart';

void main() {
  late AppDatabase db;
  late TransactionsDao dao;
  const biz = 'biz-1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = TransactionsDao(db);
  });

  tearDown(() => db.close());

  Future<void> insertLocal(
    String id, {
    SyncStatus status = SyncStatus.synced,
    String? customerId,
    double discountAmount = 0,
    int itemCount = 0,
  }) {
    return db.into(db.transactionsTable).insert(
          TransactionsTableCompanion.insert(
            id: id,
            businessId: Value(biz),
            cashierId: 'cashier-1',
            totalAmount: 100,
            discountAmount: Value(discountAmount),
            taxAmount: 0,
            subtotal: 100,
            itemCount: itemCount,
            customerId: Value(customerId),
            syncStatus: Value(status.toInt()),
          ),
        );
  }

  Map<String, dynamic> serverRow({
    required String id,
    String? customerId,
    double discountAmount = 0,
    double totalAmount = 200,
    double taxAmount = 20,
  }) {
    return {
      'id': id,
      'business_id': biz,
      'branch_id': null,
      'shift_id': null,
      'cashier_id': 'cashier-1',
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'status': 'completed',
      'payment_method': 'cash',
      'invoice_number': 'INV-1',
      'customer_id': customerId,
      'created_at': DateTime.utc(2026, 1, 1).toIso8601String(),
    };
  }

  group('upsertFromServer — new row', () {
    test('carries customer_id and discount_amount from the server', () async {
      await dao.upsertFromServer(
        serverRow(id: 'tx-1', customerId: 'cust-1', discountAmount: 15),
      );

      final row = await (db.select(
        db.transactionsTable,
      )..where((t) => t.id.equals('tx-1'))).getSingle();

      expect(row.customerId, 'cust-1');
      expect(row.discountAmount, 15);
    });

    test(
      'reconstructs subtotal as total + discount - tax (no server column)',
      () async {
        await dao.upsertFromServer(
          serverRow(
            id: 'tx-2',
            totalAmount: 200,
            discountAmount: 15,
            taxAmount: 20,
          ),
        );

        final row = await (db.select(
          db.transactionsTable,
        )..where((t) => t.id.equals('tx-2'))).getSingle();

        expect(row.subtotal, 195); // 200 + 15 - 20
      },
    );

    test('inserts with itemCount 0, pending recomputeItemCounts', () async {
      await dao.upsertFromServer(serverRow(id: 'tx-3'));

      final row = await (db.select(
        db.transactionsTable,
      )..where((t) => t.id.equals('tx-3'))).getSingle();

      expect(row.itemCount, 0);
    });
  });

  group('upsertFromServer — existing row', () {
    test('never clobbers a row that has not reached the server yet', () async {
      await insertLocal(
        'tx-4',
        status: SyncStatus.pendingUpload,
        customerId: null,
      );

      await dao.upsertFromServer(
        serverRow(id: 'tx-4', customerId: 'cust-should-not-apply'),
      );

      final row = await (db.select(
        db.transactionsTable,
      )..where((t) => t.id.equals('tx-4'))).getSingle();

      // Local pendingUpload row is untouched — the push pass owns it.
      expect(row.customerId, isNull);
      expect(row.syncStatus, SyncStatus.pendingUpload.toInt());
    });

    test('updates customer_id and discount_amount on a synced row', () async {
      await insertLocal('tx-5', status: SyncStatus.synced, customerId: null);

      await dao.upsertFromServer(
        serverRow(id: 'tx-5', customerId: 'cust-2', discountAmount: 10),
      );

      final row = await (db.select(
        db.transactionsTable,
      )..where((t) => t.id.equals('tx-5'))).getSingle();

      expect(row.customerId, 'cust-2');
      expect(row.discountAmount, 10);
    });
  });

  group('recomputeItemCounts', () {
    Future<void> insertItem(String id, String txId, double qty) {
      return db.into(db.transactionItemsTable).insert(
            TransactionItemsTableCompanion.insert(
              id: id,
              transactionId: txId,
              variantId: 'variant-1',
              productName: 'Product',
              variantName: 'Default',
              unitPrice: 10,
              qty: qty,
              lineTotal: 10 * qty,
              lineTax: 0,
            ),
          );
    }

    test(
      'whole-qty lines count by qty; fractional lines count as one',
      () async {
        await insertLocal('tx-6', itemCount: 0);
        await insertItem('item-1', 'tx-6', 3);
        await insertItem('item-2', 'tx-6', 2);
        await insertItem('item-3', 'tx-6', 0.75); // weighed line

        await dao.recomputeItemCounts(['tx-6']);

        final row = await (db.select(
          db.transactionsTable,
        )..where((t) => t.id.equals('tx-6'))).getSingle();

        expect(row.itemCount, 6); // 3 + 2 + 1
      },
    );

    test('does not overwrite a row whose itemCount is already set', () async {
      await insertLocal('tx-7', itemCount: 99);
      await insertItem('item-4', 'tx-7', 1);

      await dao.recomputeItemCounts(['tx-7']);

      final row = await (db.select(
        db.transactionsTable,
      )..where((t) => t.id.equals('tx-7'))).getSingle();

      expect(row.itemCount, 99);
    });
  });

  group('backfillCustomerNames', () {
    Future<void> insertCustomer(String id, String name) {
      return db.into(db.customersTable).insert(
            CustomersTableCompanion.insert(id: id, businessId: biz, name: name),
          );
    }

    test('fills a blank customer_name from the customers table', () async {
      await insertCustomer('cust-3', 'Jordan Rivera');
      await insertLocal('tx-8', customerId: 'cust-3');

      await dao.backfillCustomerNames(biz);

      final row = await (db.select(
        db.transactionsTable,
      )..where((t) => t.id.equals('tx-8'))).getSingle();

      expect(row.customerName, 'Jordan Rivera');
    });

    test('leaves an existing snapshot alone (frozen at sale time)', () async {
      await insertCustomer('cust-4', 'New Name');
      await insertLocal('tx-9', customerId: 'cust-4');
      await (db.update(
        db.transactionsTable,
      )..where((t) => t.id.equals('tx-9'))).write(
        const TransactionsTableCompanion(
          customerName: Value('Name At Sale Time'),
        ),
      );

      await dao.backfillCustomerNames(biz);

      final row = await (db.select(
        db.transactionsTable,
      )..where((t) => t.id.equals('tx-9'))).getSingle();

      expect(row.customerName, 'Name At Sale Time');
    });
  });

  group('queueCustomerIdBackfill', () {
    test('re-queues synced rows that have a customerId', () async {
      await insertLocal('tx-10', status: SyncStatus.synced, customerId: 'c1');
      await insertLocal('tx-11', status: SyncStatus.synced, customerId: null);
      await insertLocal(
        'tx-12',
        status: SyncStatus.pendingUpload,
        customerId: 'c2',
      );

      final requeued = await dao.queueCustomerIdBackfill();

      expect(requeued, 1);
      final row10 = await (db.select(
        db.transactionsTable,
      )..where((t) => t.id.equals('tx-10'))).getSingle();
      final row11 = await (db.select(
        db.transactionsTable,
      )..where((t) => t.id.equals('tx-11'))).getSingle();

      expect(row10.syncStatus, SyncStatus.pendingUpload.toInt());
      expect(row11.syncStatus, SyncStatus.synced.toInt()); // no customerId
    });
  });
}
