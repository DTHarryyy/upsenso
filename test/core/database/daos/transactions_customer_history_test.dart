import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> sale({
    required String id,
    String businessId = 'biz-1',
    String? customerId,
    String status = 'completed',
    double total = 100,
    required DateTime createdAt,
  }) {
    return db.transactionsDao.insertTransaction(
      TransactionsTableCompanion.insert(
        id: id,
        cashierId: 'cashier-1',
        businessId: Value(businessId),
        customerId: Value(customerId),
        totalAmount: total,
        taxAmount: 0,
        subtotal: total,
        itemCount: 1,
        status: Value(status),
        createdAt: Value(createdAt),
      ),
      const [],
    );
  }

  group('watchByCustomerId', () {
    test('returns only the customer\'s completed sales, newest first',
        () async {
      await sale(
        id: 't1',
        customerId: 'cust-1',
        createdAt: DateTime(2026, 6, 1),
      );
      await sale(
        id: 't2',
        customerId: 'cust-1',
        createdAt: DateTime(2026, 6, 3),
      );
      // Different customer, a voided sale, a walk-in, and another tenant —
      // all must be excluded.
      await sale(
        id: 't3',
        customerId: 'cust-2',
        createdAt: DateTime(2026, 6, 2),
      );
      await sale(
        id: 't4',
        customerId: 'cust-1',
        status: 'voided',
        createdAt: DateTime(2026, 6, 4),
      );
      await sale(id: 't5', createdAt: DateTime(2026, 6, 5)); // walk-in
      await sale(
        id: 't6',
        businessId: 'biz-2',
        customerId: 'cust-1',
        createdAt: DateTime(2026, 6, 6),
      );

      final rows = await db.transactionsDao
          .watchByCustomerId(businessId: 'biz-1', customerId: 'cust-1')
          .first;

      expect(rows.map((r) => r.id), ['t2', 't1']);
    });
  });
}
