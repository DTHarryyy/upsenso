import 'package:flutter/foundation.dart';

import 'package:pos/core/audit/audit_hash.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/database/daos/devices_dao.dart';
import 'package:pos/core/device/device_identity_service.dart';

/// Fetches per-device chain heads from the server (get_audit_chain_heads
/// RPC) — injected as a function so core/ stays independent of the feature
/// data layer. Null when offline verification is all that's possible.
typedef ChainHeadsFetcher = Future<List<Map<String, dynamic>>> Function();

enum AuditChainBreakReason {
  /// Recomputed hash differs from the stored entry_hash — row content was
  /// altered after it was written.
  hashMismatch,

  /// prev_hash doesn't match the previous row's entry_hash (or genesis).
  linkMismatch,

  /// seq is not previous+1 — rows were deleted from the middle of the chain.
  seqGap,

  /// The server holds MORE of this device's own chain than the device does —
  /// the synced tail was deleted locally.
  truncatedTail,

  /// Like [truncatedTail], but the eviction sentinel (prefs/localStorage —
  /// a store the browser clears independently of IndexedDB) shows this
  /// device once held a higher head than its DB does now: the history is
  /// missing through browser storage loss, not deliberate deletion.
  storageLoss,
}

class AuditChainBreak {
  final String deviceUid;
  final int seq;
  final AuditChainBreakReason reason;
  final String? expected;
  final String? actual;

  const AuditChainBreak({
    required this.deviceUid,
    required this.seq,
    required this.reason,
    this.expected,
    this.actual,
  });

  @override
  String toString() =>
      'AuditChainBreak(${reason.name} device=$deviceUid seq=$seq)';
}

/// Per-device verification summary — the verify UI renders one of these per
/// chain, labelled with the device's human-readable name.
class AuditChainDeviceReport {
  final String deviceUid;
  final String deviceLabel;
  final bool isThisDevice;
  final int? firstCheckedSeq;
  final int? localHeadSeq;
  final int? serverHeadSeq;
  final DateTime? lastAt;
  final int checkedCount;
  final List<AuditChainBreak> breaks;

  /// Distinct non-empty branch_ids over the BROKEN rows (falling back to the
  /// whole retained chain when breaks carry no branch) — lets a tamper flag
  /// name the branch(es) actually affected instead of "All branches".
  final Set<String> branchIds;

  const AuditChainDeviceReport({
    required this.deviceUid,
    required this.deviceLabel,
    required this.isThisDevice,
    required this.firstCheckedSeq,
    required this.localHeadSeq,
    required this.serverHeadSeq,
    required this.lastAt,
    required this.checkedCount,
    required this.breaks,
    this.branchIds = const {},
  });

  bool get isClean => breaks.isEmpty;
}

class AuditChainVerifyResult {
  final List<AuditChainDeviceReport> devices;

  /// False when the server heads couldn't be fetched (offline / no
  /// permission) — truncation of this device's synced tail is then unchecked.
  final bool serverCheckRan;

  const AuditChainVerifyResult({
    required this.devices,
    required this.serverCheckRan,
  });

  bool get isClean => devices.every((d) => d.isClean);
  int get totalBreaks => devices.fold(0, (n, d) => n + d.breaks.length);
}

/// Re-walks every locally retained device chain and recomputes each link.
///
/// Trust boundaries, stated plainly:
/// - The earliest retained row of a chain is the trusted start — the 90-day
///   prune makes `seq 1` unavailable eventually, so a chain that begins at
///   seq N is only checked from N forward. Full history lives on the server.
/// - TRUNCATED_TAIL is only decidable for THIS device's own chain: for other
///   devices, a lower local head just means "not pulled recently".
/// - Server-origin rows (permission triggers) have no seq and are exempt —
///   they never went through a device chain.
/// - A report from a compromised device can't be trusted by definition; the
///   owner's device, which pulls all audit rows, is the authoritative
///   place to run this.
class AuditChainVerifier {
  final AuditLogsDao _dao;
  final DevicesDao? _devicesDao;
  final DeviceIdentityService _deviceIdentityService;
  final ChainHeadsFetcher? _fetchChainHeads;

  AuditChainVerifier({
    required AuditLogsDao dao,
    required DeviceIdentityService deviceIdentityService,
    DevicesDao? devicesDao,
    ChainHeadsFetcher? fetchChainHeads,
  })  : _dao = dao,
        _devicesDao = devicesDao,
        _deviceIdentityService = deviceIdentityService,
        _fetchChainHeads = fetchChainHeads;

  Future<AuditChainVerifyResult> verify({required String businessId}) async {
    final rows = await _dao.getChainedRows(businessId);
    final myUid = await _deviceIdentityService.getDeviceUid();
    // Canonical labels from the normalized directory; fall back to the label
    // stored on the chain's newest row for uids not (yet) in the directory.
    final deviceLabels =
        await _devicesDao?.labelsByBusiness(businessId) ?? const {};

    final byDevice = <String, List<AuditLogRow>>{};
    for (final row in rows) {
      byDevice.putIfAbsent(row.deviceUid!, () => []).add(row);
    }

    var serverCheckRan = false;
    final serverHeads = <String, ({int seq, DateTime? lastAt})>{};
    if (_fetchChainHeads != null) {
      try {
        for (final head in await _fetchChainHeads()) {
          final uid = head['device_uid'] as String?;
          final seq = (head['max_seq'] as num?)?.toInt();
          if (uid == null || seq == null) continue;
          final lastAtRaw = head['last_at'] as String?;
          serverHeads[uid] = (
            seq: seq,
            lastAt: lastAtRaw != null ? DateTime.tryParse(lastAtRaw) : null,
          );
        }
        serverCheckRan = true;
      } catch (e, st) {
        debugPrint('[AuditChainVerifier] server head fetch failed: $e\n$st');
      }
    }

    final reports = <AuditChainDeviceReport>[];
    final localUids = byDevice.keys.toSet();

    for (final entry in byDevice.entries) {
      final uid = entry.key;
      final chain = entry.value;
      final breaks = _walkChain(uid, chain);

      final localHead = chain.last.seq!;
      final serverHead = serverHeads[uid];
      if (serverCheckRan && uid == myUid && serverHead != null &&
          serverHead.seq > localHead) {
        // The eviction sentinel lives in prefs/localStorage: when it also
        // remembers a higher head, the DB (IndexedDB on web) was evicted by
        // the browser — storage loss, not deliberate truncation.
        final sentinel = await _deviceIdentityService.getLastLocalHeadSeq(
          businessId,
          uid,
        );
        final evicted = sentinel != null && sentinel > localHead;
        breaks.add(AuditChainBreak(
          deviceUid: uid,
          seq: localHead,
          reason: evicted
              ? AuditChainBreakReason.storageLoss
              : AuditChainBreakReason.truncatedTail,
          expected: 'server head seq ${serverHead.seq}',
          actual: 'local head seq $localHead'
              '${evicted ? ' (sentinel remembers $sentinel)' : ''}',
        ));
      }

      // Branch attribution for the report: broken rows first, whole chain as
      // the fallback (a truncation break points past the retained rows).
      final breakSeqs = {for (final b in breaks) b.seq};
      var branchIds = {
        for (final row in chain)
          if (breakSeqs.contains(row.seq) && row.branchId.isNotEmpty)
            row.branchId,
      };
      if (branchIds.isEmpty) {
        branchIds = {
          for (final row in chain)
            if (row.branchId.isNotEmpty) row.branchId,
        };
      }

      reports.add(AuditChainDeviceReport(
        deviceUid: uid,
        deviceLabel: deviceLabels[uid] ?? chain.last.deviceId,
        isThisDevice: uid == myUid,
        firstCheckedSeq: chain.first.seq,
        localHeadSeq: localHead,
        serverHeadSeq: serverHead?.seq,
        lastAt: serverHead?.lastAt ?? chain.last.createdAt,
        checkedCount: chain.length,
        breaks: breaks,
        branchIds: branchIds,
      ));
    }

    // Devices the server knows but this device has no rows for — normal on
    // non-owner devices (audit pull is owner-only) and for retired devices;
    // shown for awareness, never counted as a break.
    for (final entry in serverHeads.entries) {
      if (localUids.contains(entry.key)) continue;
      reports.add(AuditChainDeviceReport(
        deviceUid: entry.key,
        deviceLabel: deviceLabels[entry.key] ?? 'Other device',
        isThisDevice: entry.key == myUid,
        firstCheckedSeq: null,
        localHeadSeq: null,
        serverHeadSeq: entry.value.seq,
        lastAt: entry.value.lastAt,
        checkedCount: 0,
        breaks: const [],
      ));
    }

    return AuditChainVerifyResult(
      devices: reports,
      serverCheckRan: serverCheckRan,
    );
  }

  List<AuditChainBreak> _walkChain(String uid, List<AuditLogRow> chain) {
    final breaks = <AuditChainBreak>[];

    for (var i = 0; i < chain.length; i++) {
      final row = chain[i];
      final seq = row.seq!;

      if (i == 0) {
        // Earliest retained row: only a true genesis can be link-checked;
        // a pruned chain start (seq > 1) is the trusted anchor.
        if (seq == 1 && row.prevHash != kAuditGenesisHash) {
          breaks.add(AuditChainBreak(
            deviceUid: uid,
            seq: seq,
            reason: AuditChainBreakReason.linkMismatch,
            expected: kAuditGenesisHash,
            actual: row.prevHash,
          ));
        }
      } else {
        final prev = chain[i - 1];
        if (seq != prev.seq! + 1) {
          breaks.add(AuditChainBreak(
            deviceUid: uid,
            seq: seq,
            reason: AuditChainBreakReason.seqGap,
            expected: 'seq ${prev.seq! + 1}',
            actual: 'seq $seq',
          ));
          // The gap already explains the broken link — don't double-report.
        } else if (row.prevHash != prev.entryHash) {
          breaks.add(AuditChainBreak(
            deviceUid: uid,
            seq: seq,
            reason: AuditChainBreakReason.linkMismatch,
            expected: prev.entryHash,
            actual: row.prevHash,
          ));
        }
      }

      // Rows without a hash_version predate canonicalization v2 (pre-fix
      // metadata double-encoding / ''-vs-NULL drift): their canonical form
      // can no longer be reproduced bit-exactly, so recomputing would mass-
      // false-positive history. Link + seq checks above still cover them;
      // only v2+ rows get the full content recompute.
      final version = row.hashVersion;
      if (version == null || version < 2) continue;

      final payload = canonicalAuditPayload(
        actionType: row.actionType,
        branchId: row.branchId,
        businessId: row.businessId,
        createdAt: row.createdAt,
        description: row.description,
        deviceUid: uid,
        entityId: row.entityId,
        entityType: row.entityType,
        metadataJson: row.metadata,
        seq: seq,
        userId: row.userId,
        version: version,
      );
      final recomputed = auditEntryHash(
        prevHash: row.prevHash ?? kAuditGenesisHash,
        canonicalPayload: payload,
      );
      if (recomputed != row.entryHash) {
        breaks.add(AuditChainBreak(
          deviceUid: uid,
          seq: seq,
          reason: AuditChainBreakReason.hashMismatch,
          expected: row.entryHash,
          actual: recomputed,
        ));
      }
    }

    return breaks;
  }
}
