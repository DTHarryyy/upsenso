import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/receipt_settings_dao.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/settings/data/datasources/receipt_settings_remote_ds.dart';
import 'package:pos/features/settings/domain/receipt_settings.dart';

class ReceiptSettingsRepository {
  final ReceiptSettingsDao _dao;
  final ReceiptSettingsRemoteDs _remote;
  final ConnectivityService _connectivity;

  ReceiptSettingsRepository({
    required ReceiptSettingsDao dao,
    required ReceiptSettingsRemoteDs remote,
    required ConnectivityService connectivity,
  }) : _dao = dao,
       _remote = remote,
       _connectivity = connectivity;

  // ── Read ─────────────────────────────────────────────────────────────────

  Stream<ReceiptSettings?> watch(String businessId) {
    return _dao
        .watchByBusinessId(businessId)
        .map((row) => row == null ? null : _fromRow(row));
  }

  Future<ReceiptSettings?> get(String businessId) async {
    final row = await _dao.getByBusinessId(businessId);
    return row == null ? null : _fromRow(row);
  }

  // ── Write (offline-first) ────────────────────────────────────────────────

  /// Saves locally first → marks pending → fire-and-forget remote push.
  Future<void> save(ReceiptSettings s) async {
    final existing = await _dao.getByBusinessId(s.businessId);
    final isNew = existing == null;
    final status = isNew ? SyncStatus.pendingUpload : SyncStatus.pendingUpdate;
    final now = DateTime.now();

    await _dao.upsert(_toCompanion(s, now, status));

    final online = await _connectivity.isConnected;
    if (online) unawaited(_pushToRemote(s.id));
  }

  /// Upload logo → Supabase Storage → persist public URL locally.
  Future<String> uploadLogo({
    required String businessId,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final online = await _connectivity.isConnected;
    if (!online) {
      throw Exception('Logo upload requires an internet connection.');
    }

    final url = await _remote.uploadLogo(
      businessId: businessId,
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );

    // Persist URL locally so it shows even offline afterwards.
    final existing = await _dao.getByBusinessId(businessId);
    if (existing != null) {
      await _dao.upsert(
        existing
            .toCompanion(true)
            .copyWith(
              logoUrl: Value(url),
              syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
              localUpdatedAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
      );
    }
    return url;
  }

  // ── Sync (called by SyncService) ─────────────────────────────────────────

  Future<void> syncPending() async {
    final pending = await _dao.getPendingSync();
    for (final row in pending) {
      try {
        await _pushToRemote(row.id);
      } catch (e) {
        debugPrint('[ReceiptSettings] Push failed for ${row.id}: $e');
        await _dao.updateSyncStatus(
          id: row.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }
  }

  Future<void> pullFromServer(String businessId) async {
    final online = await _connectivity.isConnected;
    if (!online) return;
    try {
      final data = await _remote.getByBusinessId(businessId);
      if (data != null) await _dao.upsertFromServer(data);
    } catch (e) {
      debugPrint('[ReceiptSettings] Pull failed: $e');
    }
  }

  Stream<int> watchPendingSyncCount() => _dao.watchPendingSyncCount();

  Future<void> clearAll() => _dao.clearAll();

  // ── Private ──────────────────────────────────────────────────────────────

  Future<void> _pushToRemote(String id) async {
    final row = await _dao.getByBusinessId(id);
    if (row == null) return;
    await _remote.upsert({
      'id': row.id,
      'business_id': row.businessId,
      'business_name': row.businessName,
      'store_name': row.storeName,
      'owner_name': row.ownerName,
      'address': row.address,
      'contact_number': row.contactNumber,
      'email': row.email,
      'website': row.website,
      'tin_number': row.tinNumber,
      'permit_number': row.permitNumber,
      'header_text': row.headerText,
      'footer_text': row.footerText,
      'return_policy': row.returnPolicy,
      'custom_notes': row.customNotes,
      'show_logo': row.showLogo,
      'logo_url': row.logoUrl,
      'show_qr_code': row.showQrCode,
      'show_tax_breakdown': row.showTaxBreakdown,
      'show_cashier_name': row.showCashierName,
      'show_customer_name': row.showCustomerName,
      'show_date_time': row.showDateTime,
      'show_order_id': row.showOrderId,
      'paper_size': row.paperSize,
      'font_size': row.fontSize,
      'text_alignment': row.textAlignment,
      'auto_print_after_checkout': row.autoPrintAfterCheckout,
      'print_duplicate_copy': row.printDuplicateCopy,
      'thermal_printer_enabled': row.thermalPrinterEnabled,
      'currency_symbol': row.currencySymbol,
      'tax_percentage': row.taxPercentage,
      'service_charge_percentage': row.serviceChargePercentage,
      'vat_inclusive': row.vatInclusive,
      'updated_at': row.updatedAt.toIso8601String(),
    });
    await _dao.updateSyncStatus(id: row.id, status: SyncStatus.synced);
  }

  // ── Mappers ──────────────────────────────────────────────────────────────

  static ReceiptSettings _fromRow(ReceiptSettingsRow r) => ReceiptSettings(
    id: r.id,
    businessId: r.businessId,
    businessName: r.businessName,
    storeName: r.storeName,
    ownerName: r.ownerName,
    address: r.address,
    contactNumber: r.contactNumber,
    email: r.email,
    website: r.website,
    tinNumber: r.tinNumber,
    permitNumber: r.permitNumber,
    headerText: r.headerText,
    footerText: r.footerText,
    returnPolicy: r.returnPolicy,
    customNotes: r.customNotes,
    showLogo: r.showLogo,
    logoLocalPath: r.logoLocalPath,
    logoUrl: r.logoUrl,
    showQrCode: r.showQrCode,
    showTaxBreakdown: r.showTaxBreakdown,
    showCashierName: r.showCashierName,
    showCustomerName: r.showCustomerName,
    showDateTime: r.showDateTime,
    showOrderId: r.showOrderId,
    paperSize: r.paperSize,
    fontSize: r.fontSize,
    textAlignment: r.textAlignment,
    autoPrintAfterCheckout: r.autoPrintAfterCheckout,
    printDuplicateCopy: r.printDuplicateCopy,
    thermalPrinterEnabled: r.thermalPrinterEnabled,
    currencySymbol: r.currencySymbol,
    taxPercentage: r.taxPercentage,
    serviceChargePercentage: r.serviceChargePercentage,
    vatInclusive: r.vatInclusive,
    updatedAt: r.updatedAt,
  );

  static ReceiptSettingsTableCompanion _toCompanion(
    ReceiptSettings s,
    DateTime now,
    SyncStatus status,
  ) {
    return ReceiptSettingsTableCompanion.insert(
      id: s.id,
      businessId: s.businessId,
      businessName: Value(s.businessName),
      storeName: Value(s.storeName),
      ownerName: Value(s.ownerName),
      address: Value(s.address),
      contactNumber: Value(s.contactNumber),
      email: Value(s.email),
      website: Value(s.website),
      tinNumber: Value(s.tinNumber),
      permitNumber: Value(s.permitNumber),
      headerText: Value(s.headerText),
      footerText: Value(s.footerText),
      returnPolicy: Value(s.returnPolicy),
      customNotes: Value(s.customNotes),
      showLogo: Value(s.showLogo),
      logoLocalPath: Value(s.logoLocalPath),
      logoUrl: Value(s.logoUrl),
      showQrCode: Value(s.showQrCode),
      showTaxBreakdown: Value(s.showTaxBreakdown),
      showCashierName: Value(s.showCashierName),
      showCustomerName: Value(s.showCustomerName),
      showDateTime: Value(s.showDateTime),
      showOrderId: Value(s.showOrderId),
      paperSize: Value(s.paperSize),
      fontSize: Value(s.fontSize),
      textAlignment: Value(s.textAlignment),
      autoPrintAfterCheckout: Value(s.autoPrintAfterCheckout),
      printDuplicateCopy: Value(s.printDuplicateCopy),
      thermalPrinterEnabled: Value(s.thermalPrinterEnabled),
      currencySymbol: Value(s.currencySymbol),
      taxPercentage: Value(s.taxPercentage),
      serviceChargePercentage: Value(s.serviceChargePercentage),
      vatInclusive: Value(s.vatInclusive),
      updatedAt: Value(now),
      syncStatus: Value(status.toInt()),
      localUpdatedAt: Value(now),
    );
  }
}
