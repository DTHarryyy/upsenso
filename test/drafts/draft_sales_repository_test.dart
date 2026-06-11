import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/draft_sales_dao.dart';
import 'package:pos/features/drafts/data/draft_sales_repository.dart';
import 'package:pos/features/drafts/domain/entities/draft_sale_item.dart';

void main() {
  late AppDatabase db;
  late DraftSalesRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DraftSalesRepository(DraftSalesDao(db));
  });

  tearDown(() async {
    await db.close();
  });

  List<DraftSaleItem> sampleItems() => const [
    DraftSaleItem(
      variantId: 'v1',
      productName: 'Coke',
      variantName: '500ml',
      unitPrice: 20,
      taxRate: 12,
      qty: 2,
      lineTotal: 40,
      lineTax: 4.8,
    ),
  ];

  Future<void> save(String id, {String? label}) => repo.saveDraft(
    id: id,
    businessId: 'biz',
    branchId: 'br',
    cashierId: 'cash',
    label: label,
    subtotal: 40,
    taxAmount: 4.8,
    discountAmount: 0,
    totalAmount: 44.8,
    itemCount: 2,
    discountType: 'percentage',
    discountValue: 10,
    items: sampleItems(),
  );

  test('saveDraft persists header and items', () async {
    await save('d1', label: 'Table 5');

    final draft = await repo.getDraft('d1');
    expect(draft, isNotNull);
    expect(draft!.label, 'Table 5');
    expect(draft.totalAmount, 44.8);
    expect(draft.discountType, 'percentage');

    final items = await repo.getItems('d1');
    expect(items, hasLength(1));
    expect(items.single.variantId, 'v1');
  });

  test('re-saving replaces items and preserves createdAt', () async {
    await save('d1', label: 'First');
    final created = (await repo.getDraft('d1'))!.createdAt;

    await Future<void>.delayed(const Duration(milliseconds: 5));
    await save('d1', label: 'Second');

    final draft = (await repo.getDraft('d1'))!;
    expect(draft.label, 'Second');
    expect(draft.createdAt, created); // unchanged
    // Items were replaced, not duplicated.
    expect(await repo.getItems('d1'), hasLength(1));
  });

  test('open drafts stream excludes converted, resumed and discarded', () async {
    await save('keep');
    await save('convert');
    await save('resume');
    await save('discard');

    await repo.markConverted('convert');
    await repo.markResumed('resume');
    await repo.discard('discard');

    final open = await repo.watchOpenDrafts().first;
    expect(open.map((d) => d.id), ['keep']);

    final count = await repo.watchOpenDraftCount().first;
    expect(count, 1);
  });

  test('branch filter scopes open drafts', () async {
    await save('d1'); // branch 'br'
    await repo.saveDraft(
      id: 'd2',
      businessId: 'biz',
      branchId: 'other',
      cashierId: 'cash',
      subtotal: 10,
      taxAmount: 0,
      discountAmount: 0,
      totalAmount: 10,
      itemCount: 1,
      items: sampleItems(),
    );

    final br = await repo.watchOpenDrafts(branchId: 'br').first;
    expect(br.map((d) => d.id), ['d1']);
  });
}
