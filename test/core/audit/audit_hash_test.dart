import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/audit/audit_hash.dart';

void main() {
  final createdAt = DateTime.utc(2026, 7, 3, 12, 34, 56);

  String payload({
    String metadataJson = '{"amount":150.5,"count":3}',
    String? entityId = 'b3b8c9d0-1234-4abc-9def-0123456789ab',
    DateTime? at,
    String description = 'Sale of ₱150.50',
    int seq = 7,
  }) {
    return canonicalAuditPayload(
      actionType: 'SALE_CREATED',
      branchId: 'branch-1',
      businessId: 'biz-1',
      createdAt: at ?? createdAt,
      description: description,
      deviceUid: 'dev-uid-1',
      entityId: entityId,
      entityType: 'transaction',
      metadataJson: metadataJson,
      seq: seq,
      userId: 'user-1',
    );
  }

  group('canonicalAuditPayload', () {
    test('is stable for identical input', () {
      expect(payload(), payload());
    });

    test('is independent of metadata key order, including nested maps', () {
      final a = payload(
        metadataJson: '{"b":1,"a":{"y":2,"x":[1,2,{"k":true}]}}',
      );
      final b = payload(
        metadataJson: '{"a":{"x":[1,2,{"k":true}],"y":2},"b":1}',
      );
      expect(a, b);
    });

    test('emits sorted top-level keys with no whitespace', () {
      final p = payload(metadataJson: '{}');
      expect(
        p,
        '{"action_type":"SALE_CREATED","branch_id":"branch-1",'
        '"business_id":"biz-1","created_at":"2026-07-03T12:34:56.000Z",'
        '"description":"Sale of ₱150.50","device_uid":"dev-uid-1",'
        '"entity_id":"b3b8c9d0-1234-4abc-9def-0123456789ab",'
        '"entity_type":"transaction","metadata":{},"seq":7,"user_id":"user-1"}',
      );
    });

    test('normalizes non-UUID entity ids to null, matching the sync mapper',
        () {
      final withCode = payload(entityId: 'INV-000123');
      final withNull = payload(entityId: null);
      expect(withCode, withNull);
      expect(withCode, contains('"entity_id":null'));

      final withUuid = payload();
      expect(
        withUuid,
        contains('"entity_id":"b3b8c9d0-1234-4abc-9def-0123456789ab"'),
      );
    });

    test('encodes integer-valued doubles identically to ints', () {
      // A VM writer may hold 5 as int while a jsonb roundtrip yields 5.0 —
      // both must hash the same.
      final asInt = payload(metadataJson: '{"qty":5}');
      final asDouble = payload(metadataJson: '{"qty":5.0}');
      expect(asInt, asDouble);
      expect(asInt, contains('"qty":5'));
    });

    test('keeps fractional doubles as-is', () {
      expect(payload(), contains('"amount":150.5'));
    });

    test('corrupted metadata hashes deterministically instead of throwing',
        () {
      final broken = payload(metadataJson: '{not json');
      expect(broken, payload(metadataJson: '{not json'));
      expect(broken, isNot(payload(metadataJson: '{}')));
    });

    test('converts non-UTC timestamps and keeps fixed millisecond format', () {
      // Same instant expressed in a +08:00 wall time.
      final manila = DateTime.utc(2026, 7, 3, 12, 34, 56).toLocal();
      expect(payload(at: manila), payload());
      expect(payload(), contains('"created_at":"2026-07-03T12:34:56.000Z"'));
    });
  });

  group('canonicalization v2 (empty branch/user → null)', () {
    String p(String branchId, String userId, {int version = kAuditHashVersion}) {
      return canonicalAuditPayload(
        actionType: 'SALE_CREATED',
        branchId: branchId,
        businessId: 'biz-1',
        createdAt: createdAt,
        description: 'x',
        deviceUid: 'dev-uid-1',
        entityId: null,
        entityType: 'transaction',
        metadataJson: '{}',
        seq: 1,
        userId: userId,
        version: version,
      );
    }

    test('v2 hashes empty branch/user as null, matching the synced NULL', () {
      // The device stores '' but the mapper ships NULL; v2 makes the roundtrip
      // invariant explicit so a server-side re-verify never false-mismatches.
      expect(p('', ''), contains('"branch_id":null'));
      expect(p('', ''), contains('"user_id":null'));
      expect(p('', 'user-1'), contains('"user_id":"user-1"'));
    });

    test('v1 preserves the historical empty-string form (grandfathered)', () {
      expect(p('', '', version: 1), contains('"branch_id":""'));
      expect(p('', '', version: 1), contains('"user_id":""'));
    });

    test('v1 and v2 differ for empty fields but agree for populated ones', () {
      expect(p('', ''), isNot(p('', '', version: 1)));
      expect(p('branch-1', 'user-1'), p('branch-1', 'user-1', version: 1));
    });
  });

  group('auditChainTimestamp', () {
    test('truncates to whole seconds in UTC', () {
      final t = DateTime.utc(2026, 7, 3, 12, 34, 56, 789, 123);
      final truncated = auditChainTimestamp(t);
      expect(truncated, DateTime.utc(2026, 7, 3, 12, 34, 56));
      expect(truncated.isUtc, isTrue);
    });
  });

  group('auditEntryHash', () {
    test('produces a 64-hex sha256 and changes with any input', () {
      final h1 = auditEntryHash(
        prevHash: kAuditGenesisHash,
        canonicalPayload: payload(),
      );
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(h1), isTrue);

      final differentPayload = auditEntryHash(
        prevHash: kAuditGenesisHash,
        canonicalPayload: payload(description: 'edited'),
      );
      final differentPrev = auditEntryHash(
        prevHash: h1,
        canonicalPayload: payload(),
      );
      expect(h1, isNot(differentPayload));
      expect(h1, isNot(differentPrev));
    });

    test('genesis sentinel is 64 zeros', () {
      expect(kAuditGenesisHash, '0' * 64);
      expect(kAuditGenesisHash.length, 64);
    });
  });

  group('isCanonicalUuid', () {
    test('accepts 8-4-4-4-12 hex, rejects everything else', () {
      expect(isCanonicalUuid('b3b8c9d0-1234-4abc-9def-0123456789ab'), isTrue);
      expect(isCanonicalUuid('B3B8C9D0-1234-4ABC-9DEF-0123456789AB'), isTrue);
      expect(isCanonicalUuid('INV-000123'), isFalse);
      expect(isCanonicalUuid(''), isFalse);
      expect(isCanonicalUuid(null), isFalse);
    });
  });
}
