import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:pos/core/audit/audit_chain_verifier.dart'
    show ChainHeadsFetcher;
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/device/device_identity_service.dart';

/// Fetches server rows of one device chain by seq range — injected as a
/// function so core/ stays independent of the feature data layer.
typedef ChainRowsFetcher = Future<List<Map<String, dynamic>>> Function(
  String businessId,
  String deviceUid, {
  required int fromSeq,
  required int toSeq,
  int limit,
});

/// Heals the holes a created_at-keyset audit pull structurally cannot see.
///
/// The delta pull pages on client-supplied created_at: a device draining an
/// offline backlog (or a chain-conflict holdback) inserts server rows whose
/// timestamps are already BEHIND every other device's watermark, so those
/// rows are never pulled again. The owner's mirror is then permanently
/// missing them — mid-chain seq holes read as `seqGap` (a critical false
/// tamper flag) and a missing REFUND_CREATED tail is exactly the "refund
/// with no audit trail" false positive from 2026-07-03.
///
/// Repair is seq-driven, so it is immune to timestamp order:
/// 1. Mid-chain gaps in every retained chain are refetched by seq range.
///    Own chain included — the writer never skips a seq, so an own-chain gap
///    can only be historical prune damage, and refilling it is safe.
/// 2. Stale TAILS (server head above local head) are extended for OTHER
///    devices' chains only. The own chain's tail is deliberately left to the
///    writer + verifier: pulling seqs the local writer may allocate next
///    would fork the chain, and a genuinely missing own tail is the
///    truncation/storage-loss signal the verifier must still be able to see.
///
/// Rows the server genuinely does not have stay missing — the gap then
/// persists and the tamper flag it produces is a true detection. Work per
/// cycle is budgeted; contiguity is preserved by always filling oldest-first,
/// so partial repairs shrink a hole instead of splitting it.
class AuditMirrorRepair {
  final AuditLogsDao _dao;
  final DeviceIdentityService _deviceIdentityService;
  final ChainHeadsFetcher? _fetchChainHeads;
  final ChainRowsFetcher _fetchChainRows;

  /// Upper bound on rows fetched per sync cycle — a huge backlog heals over
  /// a few cycles rather than stalling one.
  static const int maxRowsPerCycle = 1500;
  static const int _pageSize = 500;

  AuditMirrorRepair({
    required AuditLogsDao dao,
    required DeviceIdentityService deviceIdentityService,
    required ChainRowsFetcher fetchChainRows,
    ChainHeadsFetcher? fetchChainHeads,
  })  : _dao = dao,
        _deviceIdentityService = deviceIdentityService,
        _fetchChainRows = fetchChainRows,
        _fetchChainHeads = fetchChainHeads;

  /// Returns the number of rows restored. Never throws — a failed repair
  /// just leaves the mirror as it was for the next cycle.
  Future<int> repair(String businessId) async {
    var repaired = 0;
    var budget = maxRowsPerCycle;
    try {
      final myUid = await _deviceIdentityService.getDeviceUid();

      final gaps = await _dao.getChainGaps(businessId);
      for (final gap in gaps) {
        if (budget <= 0) break;
        final filled = await _fillRange(
          businessId,
          gap.deviceUid,
          gap.fromSeq,
          gap.toSeq,
          budget,
        );
        repaired += filled;
        budget -= filled;
      }

      if (_fetchChainHeads != null && budget > 0) {
        final localHeads = await _dao.getLocalChainHeads(businessId);
        for (final head in await _fetchChainHeads()) {
          if (budget <= 0) break;
          final uid = head['device_uid'] as String?;
          final serverSeq = (head['max_seq'] as num?)?.toInt();
          if (uid == null || serverSeq == null) continue;
          if (uid == myUid) continue; // the local writer owns this tail
          final localMax = localHeads[uid];
          // A chain with no local rows at all is a retired/never-pulled
          // device — backfilling its history is the retention window's call,
          // not repair's.
          if (localMax == null || serverSeq <= localMax) continue;
          final filled = await _fillRange(
            businessId,
            uid,
            localMax + 1,
            serverSeq,
            budget,
          );
          repaired += filled;
          budget -= filled;
        }
      }

      if (repaired > 0) {
        debugPrint(
          '[AuditMirrorRepair] restored $repaired late-arriving audit row(s)',
        );
      }
    } catch (e, st) {
      debugPrint('[AuditMirrorRepair] Error in repair: $e\n$st');
    }
    return repaired;
  }

  /// Fills [fromSeq, toSeq] oldest-first within [budget]; stops early when
  /// the server returns nothing for a sub-range (the hole is real there).
  Future<int> _fillRange(
    String businessId,
    String deviceUid,
    int fromSeq,
    int toSeq,
    int budget,
  ) async {
    var next = fromSeq;
    var filled = 0;
    while (next <= toSeq && filled < budget) {
      final pageEnd = math.min(toSeq, next + _pageSize - 1);
      final rows = await _fetchChainRows(
        businessId,
        deviceUid,
        fromSeq: next,
        toSeq: pageEnd,
        limit: _pageSize,
      );
      if (rows.isEmpty) break;
      var maxSeen = next - 1;
      for (final row in rows) {
        await _dao.upsertFromServer(row);
        final seq = (row['seq'] as num?)?.toInt();
        if (seq != null && seq > maxSeen) maxSeen = seq;
      }
      filled += rows.length;
      // The server may hold fewer rows than the range spans; if the page
      // came back short of its end, anything left in it is genuinely absent.
      if (rows.length < math.min(_pageSize, pageEnd - next + 1)) break;
      next = maxSeen + 1;
    }
    return filled;
  }
}
