import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/features/audit_logs/data/audit_log_sync_mapper.dart';

/// Regression for the 2026-07-03 metadata double-encoding bug: the local
/// column stores JSON *text*, the server column is *jsonb*. Pushing the raw
/// string stored a jsonb string scalar; pulling it back and jsonEncode-ing
/// again double-encoded it, which broke both the audit-log detail view and
/// (worse) hash verification of pulled rows → false AUDIT_TAMPER flags.
void main() {
  const metadataJson = '{"amount":150.5,"count":3,"reason":"damaged"}';

  test('push decodes metadata to an object, not a jsonb string scalar', () {
    final decoded = decodeMetadataForRemote(metadataJson);
    expect(decoded, isA<Map>());
    expect((decoded as Map)['amount'], 150.5);
  });

  test('push tolerates malformed metadata without throwing', () {
    expect(decodeMetadataForRemote('{not json'), <String, dynamic>{});
    expect(decodeMetadataForRemote(''), <String, dynamic>{});
  });

  group('pull normalizes metadata to single-encoded local text', () {
    late AppDatabase db;
    late AuditLogsDao dao;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      dao = AuditLogsDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    Map<String, dynamic> serverRow(Object? metadata) => {
          'id': 'a1',
          'business_id': 'biz1',
          'branch_id': 'br1',
          'user_id': 'u1',
          'action_type': 'SALE_CREATED',
          'entity_type': 'transaction',
          'entity_id': null,
          'description': 'test',
          'metadata': metadata,
          'device_id': 'Device',
          'created_at': DateTime.utc(2026, 7, 3).toIso8601String(),
        };

    Future<String> storedMetadata() async {
      final rows = await dao.getByBusiness('biz1');
      return rows.single.metadata;
    }

    test('a jsonb object (well-formed row) stores as parseable text', () async {
      // The Supabase client decodes jsonb objects to a Dart Map.
      await dao.upsertFromServer(serverRow(jsonDecode(metadataJson)));
      final stored = await storedMetadata();
      expect(jsonDecode(stored), isA<Map>());
      expect((jsonDecode(stored) as Map)['count'], 3);
    });

    test('a legacy jsonb string scalar is NOT double-encoded', () async {
      // A double-encoded server row comes back to the client as a String
      // that already IS the JSON text.
      await dao.upsertFromServer(serverRow(metadataJson));
      final stored = await storedMetadata();
      // One decode must yield the Map — not a String (which would mean the
      // old double-encoding bug survived).
      final once = jsonDecode(stored);
      expect(once, isA<Map>(), reason: 'metadata was double-encoded');
      expect((once as Map)['reason'], 'damaged');
    });

    test('null metadata falls back to an empty object', () async {
      await dao.upsertFromServer(serverRow(null));
      expect(jsonDecode(await storedMetadata()), <String, dynamic>{});
    });
  });
}
