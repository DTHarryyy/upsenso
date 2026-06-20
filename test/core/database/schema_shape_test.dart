import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';

/// Locks the canonical shape of the tables that previously drifted from the
/// generated schema (the "Mismatch detected" report). If someone reintroduces
/// the dead transaction_hash column or recreates invoice_sequences with the
/// millisecond default, this fails instead of surfacing in the in-app validator.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<String> createSql(String table) async {
    final row = await db.customSelect(
      "SELECT sql FROM sqlite_master WHERE type='table' AND name = ?",
      variables: [Variable<String>(table)],
    ).getSingle();
    return (row.data['sql'] as String).toLowerCase();
  }

  test('transactions has no dead transaction_hash column', () async {
    final sql = await createSql('transactions');
    expect(sql, isNot(contains('transaction_hash')));
    expect(sql, contains('invoice_number'));
    expect(sql, contains('business_id'));
  });

  test('invoice_sequences.updated_at defaults to seconds, not milliseconds',
      () async {
    final sql = await createSql('invoice_sequences');
    // Drift's currentDateAndTime renders CURRENT_TIMESTAMP (seconds). The buggy
    // v40 migration used strftime('%s','now') * 1000 (milliseconds).
    expect(sql, isNot(contains('* 1000')));
    expect(sql, contains('current_timestamp'));
  });

  test('product_variants keeps the unit column', () async {
    final sql = await createSql('product_variants');
    expect(sql, contains('unit'));
  });
}
