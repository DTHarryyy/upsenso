import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/features/audit_logs/data/audit_log_sync_mapper.dart';

// Regression: BUSINESS_MODULE_CHANGED logs stored the module code ("pos",
// "inventory", …) in entity_id, but the remote column is uuid-typed and
// rejected them (22P02), so the rows retried forever. The mapper must drop any
// non-uuid entity_id to null while still emitting the row.
void main() {
  late AppDatabase db;
  late AuditLogsDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = AuditLogsDao(db);
  });

  tearDown(() async => db.close());

  Future<AuditLogRow> insertLog({String? entityId}) async {
    final id = 'log-${entityId ?? 'none'}';
    await dao.insert(
      AuditLogsTableCompanion.insert(
        id: id,
        businessId: 'biz-1',
        branchId: '',
        userId: '',
        actionType: 'BUSINESS_MODULE_CHANGED',
        entityType: 'module',
        entityId: Value(entityId),
        description: 'module changed',
      ),
    );
    final rows = await dao.getByBusiness('biz-1');
    return rows.firstWhere((r) => r.id == id);
  }

  test('module code entity_id is dropped to null', () async {
    final row = auditLogToRemoteRow(await insertLog(entityId: 'pos'));
    expect(row['entity_id'], isNull);
    expect(row['action_type'], 'BUSINESS_MODULE_CHANGED');
  });

  test('valid uuid entity_id is preserved', () async {
    const uuid = 'eee843d7-a13e-4799-a207-5641457aa548';
    final row = auditLogToRemoteRow(await insertLog(entityId: uuid));
    expect(row['entity_id'], uuid);
  });

  test('null entity_id stays null', () async {
    final row = auditLogToRemoteRow(await insertLog(entityId: null));
    expect(row['entity_id'], isNull);
  });

  test('empty branch_id and user_id map to null', () async {
    final row = auditLogToRemoteRow(await insertLog(entityId: null));
    expect(row['branch_id'], isNull);
    expect(row['user_id'], isNull);
  });

  group('isUuid', () {
    test('accepts a canonical v4 uuid', () {
      expect(isUuid('95a75278-e251-41a9-8d8f-e03d97623b16'), isTrue);
    });

    test('rejects module codes and other non-uuids', () {
      for (final code in ['pos', 'inventory', 'expenses', '', 'not-a-uuid']) {
        expect(isUuid(code), isFalse, reason: code);
      }
    });

    test('rejects null', () {
      expect(isUuid(null), isFalse);
    });
  });
}
