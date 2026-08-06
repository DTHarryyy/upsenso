import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';

void main() {
  late AppDatabase db;
  late InventoryLevelsDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = InventoryLevelsDao(db);
  });

  tearDown(() => db.close());

  test(
    'outgoing stock clamps by default but can explicitly go negative',
    () async {
      await dao.upsertLevel(
        variantId: 'variant-1',
        branchId: 'branch-1',
        businessId: 'business-1',
        quantity: 1,
      );

      await dao.adjustQuantity(
        variantId: 'variant-1',
        branchId: 'branch-1',
        businessId: 'business-1',
        delta: -3,
      );
      expect((await dao.getLevel('variant-1', 'branch-1'))?.quantity, 0);

      await dao.upsertLevel(
        variantId: 'variant-1',
        branchId: 'branch-1',
        businessId: 'business-1',
        quantity: 1,
      );
      await dao.adjustQuantity(
        variantId: 'variant-1',
        branchId: 'branch-1',
        businessId: 'business-1',
        delta: -3,
        allowNegativeStock: true,
      );
      expect((await dao.getLevel('variant-1', 'branch-1'))?.quantity, -2);
    },
  );
}
