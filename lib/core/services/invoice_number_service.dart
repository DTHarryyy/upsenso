import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pos/core/database/daos/invoice_sequences_dao.dart';
import 'package:pos/core/sync/connectivity_service.dart';

/// Generates production-ready invoice numbers in INV-YYYYMM-NNNNNN format.
///
/// Online path (happy path): calls the Supabase `claim_invoice_number` RPC
/// which increments a server-side atomic counter — guarantees global uniqueness
/// even across multiple devices hitting the same business simultaneously.
///
/// Offline path (fallback): increments a local SQLite counter inside a DB
/// transaction so the same device never reuses a number. If two devices are
/// both offline and later sync, the Supabase UNIQUE index on `invoice_number`
/// catches any collision and the sync layer re-claims a fresh server number.
class InvoiceNumberService {
  final SupabaseClient _supabase;
  final InvoiceSequencesDao _dao;
  // Owned directly (not injected) so checkout can short-circuit the server RPC
  // when offline without a DI wiring change. Zero-arg ConnectivityService is cheap.
  final ConnectivityService _connectivity;

  InvoiceNumberService(
    this._supabase,
    this._dao, [
    ConnectivityService? connectivity,
  ]) : _connectivity = connectivity ?? ConnectivityService();

  static String _monthKey(DateTime dt) =>
      '${dt.year}${dt.month.toString().padLeft(2, '0')}';

  /// Claims the next invoice number for [businessId].
  /// Returns a string like `INV-202606-000042`.
  Future<String> claimNext(String businessId) async {
    final monthKey = _monthKey(DateTime.now());

    // Offline: skip the server RPC entirely so checkout never blocks on a
    // network roundtrip. The local counter keeps numbers unique on this device.
    if (!await _connectivity.isConnected) {
      return _dao.nextLocalInvoiceNumber(businessId, monthKey);
    }

    try {
      final result = await _supabase
          .rpc('claim_invoice_number', params: {
            'p_business_id': businessId,
            'p_month_key': monthKey,
          })
          .timeout(const Duration(milliseconds: 1500));

      final invoiceNumber = result as String;

      // Keep local counter in sync so offline numbers don't collide with this
      // server-assigned value later.
      final seq = _parseSequence(invoiceNumber);
      if (seq != null) {
        await _dao.syncFromServer(
          businessId: businessId,
          monthKey: monthKey,
          serverValue: seq,
        );
      }

      return invoiceNumber;
    } catch (e, st) {
      debugPrint('[InvoiceNumberService] RPC unavailable, using local counter: $e\n$st');
      return _dao.nextLocalInvoiceNumber(businessId, monthKey);
    }
  }

  /// If the transaction was saved with a local (offline) invoice number and
  /// the sync detects a UNIQUE conflict, call this to replace it with a fresh
  /// server number and update the local record.
  Future<String> reclaim(String businessId) async {
    final monthKey = _monthKey(DateTime.now());
    final result = await _supabase.rpc('claim_invoice_number', params: {
      'p_business_id': businessId,
      'p_month_key': monthKey,
    });
    final invoiceNumber = result as String;
    final seq = _parseSequence(invoiceNumber);
    if (seq != null) {
      await _dao.syncFromServer(
        businessId: businessId,
        monthKey: monthKey,
        serverValue: seq,
      );
    }
    return invoiceNumber;
  }

  // Extracts the trailing integer from INV-YYYYMM-NNNNNN.
  static int? _parseSequence(String invoiceNumber) {
    final parts = invoiceNumber.split('-');
    if (parts.length != 3) return null;
    return int.tryParse(parts[2]);
  }
}
