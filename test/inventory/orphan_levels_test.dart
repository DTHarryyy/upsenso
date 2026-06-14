import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';

// Orphan detection: inventory levels whose variant/branch no longer exist
// locally can never sync. findOrphans surfaces them for admin review and must
// never touch valid rows or delete anything.
void main() {
  late AppDatabase db;
  late InventoryLevelsDao levels;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    levels = InventoryLevelsDao(db);
  });

  tearDown(() async => db.close());

  Future<void> addVariant(String id) => db.into(db.productVariantsTable).insert(
        ProductVariantsTableCompanion.insert(
          id: id,
          productId: 'p1',
          businessId: 'biz',
          name: id,
        ),
      );

  Future<void> addBranch(String id) => db.into(db.branchesTable).insert(
        BranchesTableCompanion.insert(id: id, businessId: 'biz', name: id),
      );

  test('finds levels with a missing variant or branch, ignores valid ones',
      () async {
    await addVariant('v1');
    await addBranch('b1');

    // Valid: both parents exist.
    await levels.upsertLevel(
        variantId: 'v1', branchId: 'b1', businessId: 'biz', quantity: 5);
    // Orphan: variant 'vX' does not exist.
    await levels.upsertLevel(
        variantId: 'vX', branchId: 'b1', businessId: 'biz', quantity: 1);
    // Orphan: branch 'bX' does not exist.
    await levels.upsertLevel(
        variantId: 'v1', branchId: 'bX', businessId: 'biz', quantity: 1);

    final orphans = await levels.findOrphans('biz');

    expect(orphans, hasLength(2));
    expect(
      orphans.map((o) => '${o.variantId}:${o.branchId}').toSet(),
      {'vX:b1', 'v1:bX'},
    );
  });

  test('returns empty when every level has its parents', () async {
    await addVariant('v1');
    await addBranch('b1');
    await levels.upsertLevel(
        variantId: 'v1', branchId: 'b1', businessId: 'biz', quantity: 5);

    expect(await levels.findOrphans('biz'), isEmpty);
  });
}
