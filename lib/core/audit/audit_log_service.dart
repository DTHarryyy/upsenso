import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:pos/core/audit/audit_hash.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/database/daos/audit_outbox_dao.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/database/daos/devices_dao.dart';
import 'package:pos/core/device/device_identity_service.dart';
import 'package:pos/core/device/device_info_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';

/// Fetches the server-side chain head for this device — used once per
/// (session, business) when the local chain is empty, so a reinstalled app
/// resumes its old chain instead of restarting at seq 1 (which would
/// conflict forever with the server's ux_audit_chain index).
typedef AuditChainHeadResolver = Future<({int seq, String hash})?> Function(
  String deviceUid,
);

/// Lightweight, fire-and-forget service for writing audit log entries.
///
/// Usage from any module:
/// ```dart
/// sl<AuditLogService>().log(
///   actionType: AuditLogActionType.saleCreated,
///   entityType: 'transaction',
///   entityId: tx.id,
///   description: 'Sale of \$${tx.totalAmount}',
///   metadata: {'total': tx.totalAmount, 'items': items.length},
/// );
/// ```
///
/// All writes are local-first (Drift). The SyncService picks them up in the
/// background and pushes them to Supabase.
///
/// Every entry is part of a per-(business, device) tamper-evident hash chain
/// (see audit_hash.dart): writes are serialized through an internal queue and
/// the seq allocation + insert happen in one Drift transaction, so the chain
/// can never fork or skip on-device.
class AuditLogService {
  final AuditLogsDao _dao;
  final AuditOutboxDao? _outboxDao;
  final DevicesDao? _devicesDao;
  final AuthContextDao _authContextDao;
  final ActiveBusinessContext _activeBusinessContext;
  final DeviceInfoService _deviceInfoService;
  final DeviceIdentityService _deviceIdentityService;
  final AuditChainHeadResolver? _chainHeadResolver;
  static const _uuid = Uuid();

  /// Chain writes are strictly sequential; concurrent log() calls queue here.
  Future<void> _tail = Future.value();

  /// Businesses whose empty-chain resume check already ran this session.
  final Set<String> _resumeCheckedFor = {};

  AuditLogService({
    required AuditLogsDao dao,
    required AuthContextDao authContextDao,
    required ActiveBusinessContext activeBusinessContext,
    required DeviceInfoService deviceInfoService,
    required DeviceIdentityService deviceIdentityService,
    AuditOutboxDao? outboxDao,
    DevicesDao? devicesDao,
    AuditChainHeadResolver? chainHeadResolver,
  })  : _dao = dao,
        _outboxDao = outboxDao,
        _devicesDao = devicesDao,
        _authContextDao = authContextDao,
        _activeBusinessContext = activeBusinessContext,
        _deviceInfoService = deviceInfoService,
        _deviceIdentityService = deviceIdentityService,
        _chainHeadResolver = chainHeadResolver;

  /// Stages an audit entry INSIDE the caller's open Drift transaction, so the
  /// business write and its audit intent commit or roll back together — the
  /// structural fix for "refund exists, audit row doesn't" (2026-07-03 FP
  /// incident). The staged row becomes a real chained entry on the next
  /// [drainOutbox]; [businessId] is captured here and trusted at drain time,
  /// bypassing the active-context tenant guard (the context may have moved on
  /// by then, but this value was transactionally correct).
  ///
  /// A direct chained write in-transaction is NOT possible: chain writes
  /// serialize through [_tail] and allocate seq in their own transaction —
  /// awaiting that while holding the caller's transaction would deadlock on
  /// Drift's single executor.
  Future<void> enqueueInTransaction({
    required AuditLogActionType actionType,
    required String entityType,
    required String businessId,
    required String description,
    String? entityId,
    String? entityName,
    String? userName,
    Map<String, dynamic> metadata = const {},
    String? branchId,
    String? userId,
  }) async {
    final outbox = _outboxDao;
    if (outbox == null) {
      throw StateError('AuditLogService was constructed without an outbox');
    }
    await outbox.enqueue(jsonEncode({
      'action_type_name': actionType.name,
      'entity_type': entityType,
      'entity_id': entityId,
      'entity_name': entityName,
      'user_name': userName,
      'description': description,
      'metadata': metadata,
      'business_id': businessId,
      'branch_id': branchId,
      'user_id': userId,
      'enqueued_at': DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
    }));
  }

  /// Turns staged outbox rows into chained audit entries, FIFO, deleting each
  /// staged row in the same transaction as its chained insert (crash-safe and
  /// idempotent). A failed row is retained with attempts++/last_error — never
  /// silently dropped. Called post-commit by the writers, at sweep start, and
  /// before each audit push.
  Future<void> drainOutbox() {
    final outbox = _outboxDao;
    if (outbox == null) return Future.value();
    final task = _tail.then((_) async {
      try {
        final pending = await outbox.getPending();
        for (final row in pending) {
          Map<String, dynamic> p;
          AuditLogActionType actionType;
          try {
            p = Map<String, dynamic>.from(jsonDecode(row.payload) as Map);
            actionType = AuditLogActionType.values
                .byName(p['action_type_name'] as String);
          } catch (e) {
            await outbox.markAttempt(row.id, 'unreadable payload: $e');
            continue;
          }
          final enqueuedAtUnix = (p['enqueued_at'] as num?)?.toInt();
          final ok = await _write(
            actionType: actionType,
            entityType: p['entity_type'] as String? ?? 'unknown',
            entityId: p['entity_id'] as String?,
            entityName: p['entity_name'] as String?,
            userName: p['user_name'] as String?,
            description: p['description'] as String? ?? '',
            metadata: Map<String, dynamic>.from(
              p['metadata'] as Map? ?? const {},
            ),
            businessId: p['business_id'] as String?,
            branchId: p['branch_id'] as String?,
            userId: p['user_id'] as String?,
            trustExplicitBusinessId: true,
            eventTime: enqueuedAtUnix != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    enqueuedAtUnix * 1000,
                    isUtc: true,
                  )
                : null,
            afterInsert: () => outbox.deleteById(row.id),
          );
          if (!ok) {
            await outbox.markAttempt(row.id, 'chained write failed — see log');
          }
        }
      } catch (e, st) {
        debugPrint('[AuditLogService] Error in drainOutbox: $e\n$st');
      }
    });
    _tail = task;
    return task;
  }

  /// Write an audit log entry.  Fire-and-forget — errors are swallowed so
  /// audit logging never breaks the caller's flow.
  ///
  /// [businessId], [branchId], [userId] can be omitted; they are resolved
  /// from the cached auth context when not provided.
  /// [entityName] is the human-readable name of the affected entity
  /// (e.g. product name, user display name).
  Future<void> log({
    required AuditLogActionType actionType,
    required String entityType,
    String? entityId,
    String? entityName,
    String? userName,
    required String description,
    Map<String, dynamic> metadata = const {},
    String? businessId,
    String? branchId,
    String? userId,
  }) {
    final task = _tail.then(
      (_) => _write(
        actionType: actionType,
        entityType: entityType,
        entityId: entityId,
        entityName: entityName,
        userName: userName,
        description: description,
        metadata: metadata,
        businessId: businessId,
        branchId: branchId,
        userId: userId,
      ),
    );
    _tail = task;
    return task;
  }

  /// Returns whether the chained write landed. [trustExplicitBusinessId]
  /// marks outbox-sourced entries: their businessId was captured inside the
  /// original transaction, so the active-context tenant guard must not drop
  /// them (dropping was the silent audit hole behind the 2026-07-03 orphan
  /// false positives). [eventTime] preserves the ENQUEUE time as the row's
  /// created_at so a drained entry stays temporally next to the record it
  /// describes. [afterInsert] joins the chained insert's transaction.
  Future<bool> _write({
    required AuditLogActionType actionType,
    required String entityType,
    String? entityId,
    String? entityName,
    String? userName,
    required String description,
    required Map<String, dynamic> metadata,
    String? businessId,
    String? branchId,
    String? userId,
    bool trustExplicitBusinessId = false,
    DateTime? eventTime,
    Future<void> Function()? afterInsert,
  }) async {
    try {
      // Resolve from the AUTHORITATIVE active session first; fall back to the
      // single cached auth row only for cold-start writes before AuthBloc has
      // bound the active context. Never resolve a tenant from a "first row"
      // lookup of an arbitrary account.
      final active = _activeBusinessContext;
      final ctx = active.hasBusiness ? null : await _authContextDao.getAny();
      final activeBusinessId = active.businessId ?? ctx?.businessId;

      final resolvedBusinessId = businessId ?? activeBusinessId ?? '';
      final resolvedBranchId = branchId ?? active.branchId ?? ctx?.branchId ?? '';
      final resolvedUserId = userId ?? active.userId ?? ctx?.userId ?? '';
      // Prefer explicitly supplied name, then active/cached full name.
      final resolvedUserName = userName ?? active.fullName ?? ctx?.fullName;
      final resolvedBranchNameSource =
          active.branchName ?? ctx?.branchName;
      // Use branch name from context; fall back to 'All Branches' when the
      // resolved user has no assigned branch (Business Owner / all-branch access).
      final resolvedBranchName =
          resolvedBranchNameSource?.trim().isNotEmpty == true
          ? resolvedBranchNameSource
          : (resolvedBranchId.isEmpty ? 'All Branches' : null);

      if (resolvedBusinessId.isEmpty) {
        debugPrint(
          '[AuditLogService] skipped ${actionType.value} — no session bound',
        );
        return false;
      }

      // Chain label is persisted per uid — browserName detection flaps
      // between sessions and would scatter one chain across apparent devices.
      final deviceLabel = await _deviceIdentityService
          .getChainLabel(() => _deviceInfoService.getDeviceLabel());

      // Tenant guard: if a session is active, never write a log attributed to a
      // different business than the active one. Drop it rather than corrupt
      // another tenant's audit trail. Outbox entries are exempt — their
      // businessId was captured transactionally with the record they describe.
      if (!trustExplicitBusinessId &&
          activeBusinessId != null &&
          activeBusinessId.isNotEmpty &&
          resolvedBusinessId != activeBusinessId) {
        debugPrint(
          '[AuditLogService] Error in _write: dropped ${actionType.value} for '
          '$resolvedBusinessId — active business is $activeBusinessId',
        );
        return false;
      }

      final enrichedMetadata = {
        ...metadata,
        if (resolvedUserName != null && resolvedUserName.isNotEmpty)
          '_user_name': resolvedUserName,
        if (resolvedBranchName != null && resolvedBranchName.isNotEmpty)
          '_branch_name': resolvedBranchName,
        if (entityName != null && entityName.isNotEmpty)
          '_entity_name': entityName,
      };
      // The exact string that is stored is the string that gets hashed —
      // writer and verifier must never re-encode independently.
      final metadataJson = jsonEncode(enrichedMetadata);

      var deviceUid = await _deviceIdentityService.getDeviceUid();
      final resume = await _resolveResume(resolvedBusinessId, deviceUid);
      deviceUid = resume.deviceUid;
      final resumeBase = resume.resumeBase;

      // Drift stores DateTimes at second precision; hash exactly what will
      // be read back.
      final createdAt = auditChainTimestamp(eventTime ?? DateTime.now());

      final seq = await _dao.insertChained(
        businessId: resolvedBusinessId,
        deviceUid: deviceUid,
        resumeBase: resumeBase,
        also: afterInsert,
        buildRow: (seq, prevHash) {
          final payload = canonicalAuditPayload(
            actionType: actionType.value,
            branchId: resolvedBranchId,
            businessId: resolvedBusinessId,
            createdAt: createdAt,
            description: description,
            deviceUid: deviceUid,
            entityId: entityId,
            entityType: entityType,
            metadataJson: metadataJson,
            seq: seq,
            userId: resolvedUserId,
          );
          final hash =
              auditEntryHash(prevHash: prevHash, canonicalPayload: payload);
          return AuditLogsTableCompanion.insert(
            id: _uuid.v4(),
            businessId: resolvedBusinessId,
            branchId: resolvedBranchId,
            userId: resolvedUserId,
            actionType: actionType.value,
            entityType: entityType,
            entityId: Value(entityId),
            description: description,
            metadata: Value(metadataJson),
            deviceId: Value(deviceLabel),
            createdAt: Value(createdAt),
            seq: Value(seq),
            prevHash: Value(prevHash),
            entryHash: Value(hash),
            deviceUid: Value(deviceUid),
            hashVersion: const Value(kAuditHashVersion),
          );
        },
      );
      // Eviction sentinel: lives in prefs/localStorage, NOT the DB — a later
      // DB head below this value means browser storage loss, not tampering.
      await _deviceIdentityService.setLastLocalHeadSeq(
        resolvedBusinessId,
        deviceUid,
        seq,
      );
      // Normalized device identity (one row per uid) — the label lives here
      // now, not repeated on every audit row.
      await _devicesDao?.touch(
        deviceUid: deviceUid,
        businessId: resolvedBusinessId,
        label: deviceLabel,
        platform: _deviceInfoService.platform,
      );
      return true;
    } catch (e, st) {
      // Audit logging must never crash the caller — but it must be LOUD:
      // a swallowed failure here is an invisible hole in the audit trail.
      debugPrint('[AuditLogService] Error in _write: $e\n$st');
      return false;
    }
  }

  /// Genesis-resume (runs once per session per business).
  ///
  /// An empty local chain has two indistinguishable causes: a genuine first
  /// run, OR a reinstall / wiped local DB whose `device_uid` survived (iOS
  /// Keychain, web localStorage) while the server still holds this uid's
  /// chain. Reusing the stored uid and starting at seq 1 is the ONE unsafe
  /// option — it collides with every synced row of the old chain forever
  /// (the bug that produced the 2026-07-03 false-tamper flood).
  ///
  /// Resolution when the local chain is empty:
  /// 1. Server *positively confirms* a head → reuse the uid, resume at head+1.
  /// 2. No confirmed head, uid was **freshly minted** this session → a globally
  ///    unique uuid can't already be on the server, so genesis at seq 1 is
  ///    safe (the true first-run path).
  /// 3. No confirmed head, uid was **restored from storage** → it may secretly
  ///    own a server chain we couldn't confirm (wiped local DB + lagging
  ///    auth/RPC — the 2026-07-03 regression). Restarting it at seq 1 would
  ///    collide forever, so mint a FRESH uid instead. The old chain stays
  ///    intact server-side and goes visibly silent.
  Future<({String deviceUid, ({int seq, String hash})? resumeBase})>
      _resolveResume(String businessId, String deviceUid) async {
    if (_resumeCheckedFor.contains(businessId)) {
      return (deviceUid: deviceUid, resumeBase: null);
    }
    _resumeCheckedFor.add(businessId);

    // Happy path: local chain has rows → just continue it.
    final localHead = await _dao.getChainHead(businessId, deviceUid);
    if (localHead != null) return (deviceUid: deviceUid, resumeBase: null);

    final restored = _deviceIdentityService.wasRestoredFromStorage;

    ({int seq, String hash})? serverHead;
    if (_chainHeadResolver != null) {
      try {
        serverHead = await _chainHeadResolver(deviceUid);
      } catch (e, st) {
        debugPrint('[AUDIT] chain-head resolve failed: $e\n$st');
        serverHead = null;
      }
    }

    // (1) Confirmed server head → resume.
    if (serverHead != null) {
      return (deviceUid: deviceUid, resumeBase: serverHead);
    }

    // (2) Freshly-minted uid → safe to start a genesis chain under it.
    if (!restored) {
      return (deviceUid: deviceUid, resumeBase: null);
    }

    // (3) Restored uid, unconfirmed head → collision risk → rotate.
    final fresh = await _deviceIdentityService.rotate();
    debugPrint(
      '[AUDIT] restored device uid with an empty local chain and no confirmed '
      'server head — started fresh uid $fresh to avoid a chain collision',
    );
    return (deviceUid: fresh, resumeBase: null);
  }

  /// Heals a chain that restarted and now collides with the server (the
  /// `ux_audit_chain` push conflict, T13's benign case: wiped local DB +
  /// surviving `device_uid`). Re-chains this device's unsynced tail so it
  /// continues *past* the server head instead of overwriting it — no audit
  /// events lost, the stuck queue drains, and no false tamper flag.
  ///
  /// Called from the sync path when an `AuditChainConflictException` is
  /// caught. Idempotent: safe to re-run (always yields one contiguous chain
  /// from `serverHead+1`). Aborts quietly if the server head can't be
  /// confirmed (offline) — the next sync cycle retries.
  Future<void> reconcileConflictedTail(String businessId) async {
    try {
      if (_chainHeadResolver == null) return;
      final deviceUid = await _deviceIdentityService.getDeviceUid();

      final serverHead = await _chainHeadResolver(deviceUid);
      if (serverHead == null) return; // can't confirm — retry next cycle

      final rows = await _dao.getUnsyncedByDevice(businessId, deviceUid);
      if (rows.isEmpty) return;

      await _dao.transaction(() async {
        var seq = serverHead.seq;
        var prevHash = serverHead.hash;
        for (final row in rows) {
          seq += 1;
          // Transplanted rows keep their original created_at (they really
          // happened then) but get a `_rechained` marker so TIME_REVERSAL can
          // tell a reconciled block from a rolled-back device clock — the
          // exact false positive observed in prod on 2026-07-03 (seq 55→56
          // regressing 5 minutes). The row is re-hashed anyway (seq and
          // prev_hash change), so stamping metadata keeps the chain valid.
          final metadataJson = _withRechainedMarker(row.metadata);
          final payload = canonicalAuditPayload(
            actionType: row.actionType,
            branchId: row.branchId,
            businessId: row.businessId,
            createdAt: row.createdAt,
            description: row.description,
            deviceUid: deviceUid,
            entityId: row.entityId,
            entityType: row.entityType,
            metadataJson: metadataJson,
            seq: seq,
            userId: row.userId,
          );
          final entryHash =
              auditEntryHash(prevHash: prevHash, canonicalPayload: payload);
          await _dao.rewriteChainRow(
            id: row.id,
            seq: seq,
            prevHash: prevHash,
            entryHash: entryHash,
            metadata: metadataJson,
            hashVersion: kAuditHashVersion,
          );
          prevHash = entryHash;
        }
      });
      await _deviceIdentityService.setLastLocalHeadSeq(
        businessId,
        deviceUid,
        serverHead.seq + rows.length,
      );
      debugPrint(
        '[AUDIT] reconciled ${rows.length} conflicted row(s) from '
        'seq ${serverHead.seq + 1}',
      );
      // Chained trace of the reconcile itself — a transplanted block is a
      // notable chain event and should be explainable later.
      await log(
        actionType: AuditLogActionType.auditChainReconciled,
        entityType: 'audit_chain',
        description:
            'Re-chained ${rows.length} conflicted audit entr(ies) after seq '
            '${serverHead.seq} (benign same-device chain restart)',
        metadata: {
          'device_uid': deviceUid,
          'from_seq': serverHead.seq + 1,
          'to_seq': serverHead.seq + rows.length,
          'count': rows.length,
        },
        businessId: businessId,
      );
    } catch (e, st) {
      debugPrint('[AUDIT] reconcileConflictedTail failed: $e\n$st');
    }
  }

  /// Adds `_rechained: true` to a stored metadata JSON string, tolerating
  /// legacy non-object metadata (kept as `_original`).
  static String _withRechainedMarker(String metadataJson) {
    Object? decoded;
    try {
      decoded = metadataJson.isEmpty ? <String, Object?>{} : jsonDecode(metadataJson);
    } on FormatException {
      decoded = null;
    }
    final map = decoded is Map
        ? Map<String, Object?>.from(decoded)
        : <String, Object?>{'_original': ?decoded};
    map['_rechained'] = true;
    return jsonEncode(map);
  }
}
