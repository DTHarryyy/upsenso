import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/features/reports/data/reports_data.dart';
import 'package:pos/features/reports/data/reports_repository.dart';

/// Regression coverage for refunds reducing recognised revenue. Per the plan:
/// a partial refund nets revenue down by the refunded amount, and a full
/// refund (gross sale fully covered by refund rows) nets to exactly zero.
void main() {
  late AppDatabase db;
  late ReportsRepository repo;

  const businessId = 'biz-1';
  const branchId = 'branch-1';
  const txId = 'tx-1';
  final day = DateTime(2026, 6, 10);
  final customRange = DateTimeRange(start: day, end: day);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = ReportsRepository(
      txnDao: db.transactionsDao,
      variantsDao: db.productVariantsDao,
      productsDao: db.productsDao,
      categoriesDao: db.categoriesDao,
      branchesDao: db.branchesDao,
      levelsDao: db.inventoryLevelsDao,
      ledgerDao: db.stockLedgerDao,
      refundsDao: db.refundsDao,
      prefs: prefs,
    );

    await db.transactionsDao.insertTransaction(
      TransactionsTableCompanion.insert(
        id: txId,
        cashierId: 'cashier-1',
        businessId: const Value(businessId),
        branchId: const Value(branchId),
        totalAmount: 300.0,
        taxAmount: 0.0,
        subtotal: 300.0,
        itemCount: 1,
        createdAt: Value(day.add(const Duration(hours: 10))),
      ),
      const [],
    );
  });

  tearDown(() => db.close());

  Future<void> insertRefund({
    required String id,
    required double amount,
    required DateTime createdAt,
  }) {
    return db.refundsDao.insertRefund(
      RefundsTableCompanion.insert(
        id: id,
        transactionId: txId,
        businessId: businessId,
        branchId: const Value(branchId),
        refundedBy: 'user-1',
        totalAmount: amount,
        createdAt: Value(createdAt),
      ),
      const [],
    );
  }

  test('gross sale with no refunds counts in full', () async {
    final data = await repo.load(
      businessId: businessId,
      period: ReportPeriod.custom,
      customRange: customRange,
    );
    expect(data.totalRevenue, 300.0);
  });

  test('a partial refund reduces revenue by exactly the refunded amount', () async {
    await insertRefund(
      id: 'refund-1',
      amount: 100.0,
      createdAt: day.add(const Duration(hours: 11)),
    );

    final data = await repo.load(
      businessId: businessId,
      period: ReportPeriod.custom,
      customRange: customRange,
    );
    expect(data.totalRevenue, 200.0);
  });

  test('a full refund nets revenue to zero', () async {
    await insertRefund(
      id: 'refund-1',
      amount: 100.0,
      createdAt: day.add(const Duration(hours: 11)),
    );
    await insertRefund(
      id: 'refund-2',
      amount: 200.0,
      createdAt: day.add(const Duration(hours: 12)),
    );

    final data = await repo.load(
      businessId: businessId,
      period: ReportPeriod.custom,
      customRange: customRange,
    );
    expect(data.totalRevenue, 0.0);
  });

  test('branch comparison nets refunds per branch', () async {
    await insertRefund(
      id: 'refund-1',
      amount: 50.0,
      createdAt: day.add(const Duration(hours: 11)),
    );

    final data = await repo.load(
      businessId: businessId,
      period: ReportPeriod.custom,
      customRange: customRange,
    );
    final branch = data.branchStats.singleWhere((b) => b.totalSales == 250.0);
    expect(branch.totalSales, 250.0);
  });
}
