import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/sync/backfill_service.dart';

/// §7.2 first-sync backfill: on Free→paid, previously-synced business rows must
/// be re-queued for upload so the re-sync pushes a complete snapshot, while
/// identity-plane rows and already-pending rows are left alone.
void main() {
  late AppDatabase db;
  late BackfillService backfill;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    backfill = BackfillService(db);
  });
  tearDown(() => db.close());

  Future<int> statusOf(String table, String id) async {
    final row = await db
        .customSelect('SELECT sync_status AS s FROM $table WHERE id = ?',
            variables: [Variable.withString(id)])
        .getSingle();
    return row.data['s'] as int;
  }

  test('re-queues synced business rows, leaves pending + identity rows alone',
      () async {
    // Business-data table (categories): one synced, one already pending.
    await db.customStatement(
      "INSERT INTO categories (id, business_id, name, sort_order, sync_status) "
      "VALUES ('c-synced', 'b1', 'A', 0, 3), ('c-pending', 'b1', 'B', 0, 0)",
    );
    // Identity-plane table (branches) — must NOT be re-queued.
    await db.customStatement(
      "INSERT INTO branches (id, business_id, name, sync_status) "
      "VALUES ('br1', 'b1', 'Main', 3)",
    );

    await backfill.markAllForUpload();

    expect(await statusOf('categories', 'c-synced'), 0, // synced → pendingUpload
        reason: 'synced business row is re-queued');
    expect(await statusOf('categories', 'c-pending'), 0,
        reason: 'already-pending row stays pending');
    expect(await statusOf('branches', 'br1'), 3,
        reason: 'identity-plane branch row is untouched');
  });

  test('is idempotent — a second run changes nothing further', () async {
    await db.customStatement(
      "INSERT INTO categories (id, business_id, name, sort_order, sync_status) "
      "VALUES ('c1', 'b1', 'A', 0, 3)",
    );
    await backfill.markAllForUpload();
    await backfill.markAllForUpload();
    expect(await statusOf('categories', 'c1'), 0);
  });
}
