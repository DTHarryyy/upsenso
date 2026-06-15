import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/receipt_settings_dao.dart';

// A server pull must NOT overwrite a receipt_settings row that still has
// unsynced local edits. The offline business-logo flow stores the picked file
// in logoLocalPath with an empty logoUrl (= "needs upload"); a pull landing
// before the sync would otherwise wipe that file reference and reset the row to
// synced, silently dropping the queued logo. The DAO guard prevents this.
void main() {
  late AppDatabase db;
  late ReceiptSettingsDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = ReceiptSettingsDao(db);
  });

  tearDown(() async => db.close());

  Map<String, dynamic> serverRow({String logoUrl = ''}) => {
        'id': 'biz',
        'business_id': 'biz',
        'logo_url': logoUrl,
        'updated_at': '2026-06-14T00:00:00.000Z',
      };

  Future<void> insertLocal({
    required int syncStatus,
    String logoLocalPath = '',
    String logoUrl = '',
  }) {
    return dao.upsert(
      ReceiptSettingsTableCompanion.insert(
        id: 'biz',
        businessId: 'biz',
        logoLocalPath: Value(logoLocalPath),
        logoUrl: Value(logoUrl),
        syncStatus: Value(syncStatus),
      ),
    );
  }

  test('logo picked offline (pendingUpdate) survives a server pull', () async {
    await insertLocal(
      syncStatus: 1, // pendingUpdate
      logoLocalPath: '/tmp/logo.png',
    );

    await dao.upsertFromServer(serverRow(logoUrl: 'https://server/old.png'));

    final row = await dao.getByBusinessId('biz');
    expect(row!.logoLocalPath, '/tmp/logo.png'); // queued file kept
    expect(row.logoUrl, ''); // not overwritten by the server URL
    expect(row.syncStatus, 1); // still pending → will push on next sync
  });

  test('synced row IS refreshed but keeps its local logo file', () async {
    await insertLocal(
      syncStatus: 3, // synced
      logoLocalPath: '/tmp/logo.png',
      logoUrl: 'https://server/old.png',
    );

    await dao.upsertFromServer(serverRow(logoUrl: 'https://server/new.png'));

    final row = await dao.getByBusinessId('biz');
    expect(row!.logoUrl, 'https://server/new.png'); // refreshed from server
    expect(row.logoLocalPath, '/tmp/logo.png'); // kept for offline display
  });

  test('first server pull inserts the row when none exists', () async {
    await dao.upsertFromServer(serverRow(logoUrl: 'https://server/a.png'));

    final row = await dao.getByBusinessId('biz');
    expect(row, isNotNull);
    expect(row!.logoUrl, 'https://server/a.png');
    expect(row.logoLocalPath, '');
  });
}
