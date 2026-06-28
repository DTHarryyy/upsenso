import 'package:flutter/foundation.dart';

import 'package:pos/core/database/daos/refund_settings_dao.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/features/pos/data/datasources/refunds_remote_ds.dart';

/// Local read cache for refund_settings — see [RefundSettingsTable] for why
/// this is pull-only. Lets the refund sheet read the approval threshold
/// instantly and offline instead of blocking on a network call at refund time.
class RefundSettingsRepository {
  final RefundSettingsDao _dao;
  final RefundsRemoteDs _remote;
  final ConnectivityService _connectivity;

  RefundSettingsRepository({
    required RefundSettingsDao dao,
    required RefundsRemoteDs remote,
    required ConnectivityService connectivity,
  }) : _dao = dao,
       _remote = remote,
       _connectivity = connectivity;

  Future<({bool requireApproval, double threshold})?> get(
    String businessId,
  ) async {
    final row = await _dao.getByBusinessId(businessId);
    if (row == null) return null;
    return (
      requireApproval: row.requireApproval,
      threshold: row.approvalThreshold,
    );
  }

  Stream<({bool requireApproval, double threshold})?> watch(
    String businessId,
  ) {
    return _dao.watchByBusinessId(businessId).map(
      (row) => row == null
          ? null
          : (requireApproval: row.requireApproval, threshold: row.approvalThreshold),
    );
  }

  /// Best-effort refresh of the cache. Never throws — an offline or failed
  /// pull just leaves the previous cached value (or no row) in place.
  Future<void> pullFromServer(String businessId) async {
    final online = await _connectivity.isConnected;
    if (!online) return;
    try {
      final settings = await _remote.fetchRefundSettings(businessId);
      if (settings != null) {
        await _dao.upsertFromServer(
          businessId: businessId,
          requireApproval: settings.requireApproval,
          threshold: settings.threshold,
        );
      }
    } catch (e, st) {
      debugPrint('[RefundSettings] Pull failed: $e\n$st');
    }
  }

  Future<void> clearAll() => _dao.clearAll();
}
