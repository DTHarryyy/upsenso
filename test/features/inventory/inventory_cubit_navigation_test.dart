import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pos/features/inventory/data/inventory_data.dart';
import 'package:pos/features/inventory/domain/repositories/i_inventory_repository.dart';
import 'package:pos/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:pos/features/inventory/presentation/cubit/inventory_state.dart';

class _MockInventoryRepository extends Mock implements IInventoryRepository {}

const _low = InventoryItem(
  variantId: 'low',
  productId: 'product-low',
  productName: 'Low item',
  variantName: 'Default',
  stockByBranch: {'branch-1': 1},
  totalStock: 1,
  reorderLevel: 5,
);

const _healthy = InventoryItem(
  variantId: 'healthy',
  productId: 'product-healthy',
  productName: 'Healthy item',
  variantName: 'Default',
  stockByBranch: {'branch-1': 20},
  totalStock: 20,
  reorderLevel: 5,
);

void main() {
  late _MockInventoryRepository repository;

  setUp(() {
    repository = _MockInventoryRepository();
    when(
      () => repository.load(
        businessId: any(named: 'businessId'),
        branchId: any(named: 'branchId'),
      ),
    ).thenAnswer(
      (_) async => const InventoryData(
        items: [_low, _healthy],
        branches: [BranchInfo(id: 'branch-1', name: 'Main')],
      ),
    );
    when(
      () => repository.watchChanges(any()),
    ).thenAnswer((_) => const Stream.empty());
  });

  test('focused navigation shows the requested variant', () async {
    final cubit = InventoryCubit(
      repository,
      initialStatusFilter: StockStatus.lowStock,
      initialFocusedVariantId: 'healthy',
    );
    addTearDown(cubit.close);

    await cubit.startWatching(businessId: 'business-1', branchId: 'branch-1');

    final state = cubit.state as InventoryLoaded;
    expect(state.displayItems.map((item) => item.variantId), ['healthy']);
  });

  test('stale focused navigation falls back to the low-stock filter', () async {
    final cubit = InventoryCubit(
      repository,
      initialStatusFilter: StockStatus.lowStock,
      initialFocusedVariantId: 'deleted-variant',
    );
    addTearDown(cubit.close);

    await cubit.startWatching(businessId: 'business-1', branchId: 'branch-1');

    final state = cubit.state as InventoryLoaded;
    expect(state.displayItems.map((item) => item.variantId), ['low']);
  });
}
