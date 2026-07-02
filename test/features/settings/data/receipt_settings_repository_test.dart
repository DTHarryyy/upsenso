import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/business/data/datasources/business_remote_ds.dart';
import 'package:pos/features/settings/data/datasources/receipt_settings_remote_ds.dart';
import 'package:pos/features/settings/data/receipt_settings_repository.dart';
import 'package:pos/features/settings/domain/receipt_settings.dart';

class MockReceiptSettingsRemoteDs extends Mock
    implements ReceiptSettingsRemoteDs {}

class MockBusinessRemoteDs extends Mock implements BusinessRemoteDs {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late AppDatabase db;
  late MockReceiptSettingsRemoteDs remote;
  late MockBusinessRemoteDs businessRemote;
  late MockConnectivityService connectivity;
  late ReceiptSettingsRepository repo;

  const businessId = 'biz-1';
  // Deliberately different from businessId — mirrors a legacy row created
  // before `id` was guaranteed to equal `businessId`.
  const rowId = 'row-id-not-equal-to-business-id';

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = MockReceiptSettingsRemoteDs();
    businessRemote = MockBusinessRemoteDs();
    connectivity = MockConnectivityService();
    when(() => connectivity.isConnected).thenAnswer((_) async => true);
    repo = ReceiptSettingsRepository(
      dao: db.receiptSettingsDao,
      remote: remote,
      connectivity: connectivity,
      businessRemote: businessRemote,
    );
  });

  tearDown(() => db.close());

  Future<void> insertPendingRow() {
    return db.receiptSettingsDao.upsert(
      ReceiptSettingsTableCompanion.insert(
        id: rowId,
        businessId: businessId,
        storeName: const Value('Test Store'),
        syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
      ),
    );
  }

  group('syncPending', () {
    test(
      'pushes and marks synced a row whose id differs from its businessId',
      () async {
        await insertPendingRow();
        when(() => remote.upsert(any())).thenAnswer((_) async {});

        await repo.syncPending();

        final captured = verify(() => remote.upsert(captureAny())).captured;
        expect(captured.single['business_id'], businessId);

        final row = await db.receiptSettingsDao.getByBusinessId(businessId);
        expect(row!.syncStatus, SyncStatus.synced.toInt());
      },
    );

    test('marks the row failed when the push throws', () async {
      await insertPendingRow();
      when(() => remote.upsert(any())).thenThrow(Exception('network error'));

      await repo.syncPending();

      final row = await db.receiptSettingsDao.getByBusinessId(businessId);
      expect(row!.syncStatus, SyncStatus.failed.toInt());
    });
  });

  group('save', () {
    test('pushes using the businessId, not the row id', () async {
      when(() => remote.upsert(any())).thenAnswer((_) async {});

      await repo.save(
        ReceiptSettings(
          id: rowId,
          businessId: businessId,
          storeName: 'Test Store',
          updatedAt: DateTime.now(),
        ),
      );

      await untilCalled(() => remote.upsert(any()));
      final captured = verify(() => remote.upsert(captureAny())).captured;
      expect(captured.single['business_id'], businessId);
    });
  });
}
