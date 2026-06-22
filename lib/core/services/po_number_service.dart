import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos/core/database/daos/po_number_sequences_dao.dart';
import 'package:pos/core/sync/connectivity_service.dart';

/// Generates sequential, per-business PO numbers in `PO-YYYYMM-NNNN` format.
///
/// Mirrors [InvoiceNumberService]: online claims via the Supabase
/// `claim_po_number` RPC (atomic, multi-device safe); offline falls back to a
/// local SQLite counter so a PO can still be created without a network call.
class PoNumberService {
  final SupabaseClient _supabase;
  final PoNumberSequencesDao _dao;
  final ConnectivityService _connectivity;

  PoNumberService(
    this._supabase,
    this._dao, [
    ConnectivityService? connectivity,
  ]) : _connectivity = connectivity ?? ConnectivityService();

  static String monthKeyFor(DateTime now) =>
      '${now.year}${now.month.toString().padLeft(2, '0')}';

  /// Claims the next PO number for [businessId]. Returns e.g. `PO-202606-0001`.
  Future<String> claimNext(String businessId) async {
    final monthKey = monthKeyFor(DateTime.now());

    // Offline: never block PO creation on the network; the local counter keeps
    // numbers unique on this device.
    if (!await _connectivity.isConnected) {
      return _dao.nextLocalPoNumber(businessId, monthKey);
    }

    try {
      final result = await _supabase
          .rpc('claim_po_number', params: {
            'p_business_id': businessId,
            'p_month_key': monthKey,
          })
          .timeout(const Duration(milliseconds: 1500));

      final poNumber = result as String;

      // Keep the local counter ahead so a later offline create can't collide.
      final seq = _parseSequence(poNumber);
      if (seq != null) {
        await _dao.syncFromServer(
          businessId: businessId,
          monthKey: monthKey,
          serverValue: seq,
        );
      }
      return poNumber;
    } catch (e, st) {
      debugPrint('[PoNumberService] RPC unavailable, using local counter: $e\n$st');
      return _dao.nextLocalPoNumber(businessId, monthKey);
    }
  }

  // Extracts the trailing integer from PO-YYYYMM-NNNN.
  static int? _parseSequence(String poNumber) {
    final match = RegExp(r'^PO-\d{6}-(\d+)$').firstMatch(poNumber);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }
}
