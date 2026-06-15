import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/receipt_settings_dao.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/business/data/datasources/business_remote_ds.dart';
import 'package:pos/features/settings/data/datasources/receipt_settings_remote_ds.dart';
import 'package:pos/features/settings/domain/receipt_settings.dart';

class ReceiptSettingsRepository {
  final ReceiptSettingsDao _dao;
  final ReceiptSettingsRemoteDs _remote;
  final ConnectivityService _connectivity;
  final BusinessRemoteDs _businessRemote;

  ReceiptSettingsRepository({
    required ReceiptSettingsDao dao,
    required ReceiptSettingsRemoteDs remote,
    required ConnectivityService connectivity,
    required BusinessRemoteDs businessRemote,
  }) : _dao = dao,
       _remote = remote,
       _connectivity = connectivity,
       _businessRemote = businessRemote;

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

  /// Save a freshly-picked logo. Offline-first: on native the image is written
  /// to a local file and shown immediately; the Supabase Storage upload is
  /// queued (empty logoUrl = "needs upload") and drained by [syncPending] when
  /// connectivity returns. The public URL is mirrored to businesses.logo_url so
  /// the app shell and other devices stay in sync.
  ///
  /// Web has no local-file display, so it keeps the original online-only path.
  Future<void> saveLogo({
    required String businessId,
    required Uint8List bytes,
    required String ext,
    required String mimeType,
  }) async {
    final safeExt = ext.isNotEmpty ? ext.toLowerCase() : '.jpg';

    if (kIsWeb) {
      final online = await _connectivity.isConnected;
      if (!online) {
        throw Exception(
          'Uploading a logo needs an internet connection on the web app.',
        );
      }
      final url = await _remote.uploadLogo(
        businessId: businessId,
        fileName: 'logo$safeExt',
        bytes: bytes,
        mimeType: mimeType,
      );
      await _persistLogo(businessId: businessId, localPath: '', url: url);
      await _mirrorLogoUrl(businessId, url);
      unawaited(_safePush(businessId));
      return;
    }

    // Native: local file first so the logo is visible instantly, even offline.
    final localPath = await _writeLogoFile(businessId, bytes, safeExt);
    await _persistLogo(businessId: businessId, localPath: localPath, url: '');

    final online = await _connectivity.isConnected;
    if (online) unawaited(_safePush(businessId));
  }

  /// Reads the queued local logo file and uploads it to Storage when it hasn't
  /// been uploaded yet (logoUrl still empty). Idempotent — safe to call on every
  /// sync. Sets logoUrl locally and mirrors it to businesses.logo_url.
  Future<void> _ensureLogoUploaded(String businessId) async {
    if (kIsWeb) return;
    final row = await _dao.getByBusinessId(businessId);
    if (row == null) return;
    if (row.logoUrl.isNotEmpty) return; // already uploaded
    if (row.logoLocalPath.isEmpty) return; // nothing queued

    final file = File(row.logoLocalPath);
    if (!await file.exists()) {
      debugPrint('[Logo] Queued file missing, skipping: ${row.logoLocalPath}');
      return;
    }

    final bytes = await file.readAsBytes();
    final ext = p.extension(row.logoLocalPath).toLowerCase();
    final url = await _remote.uploadLogo(
      businessId: businessId,
      fileName: 'logo${ext.isNotEmpty ? ext : '.jpg'}',
      bytes: bytes,
      mimeType: _mimeForExt(ext),
    );

    // Keep the local path for offline display; just stamp the public URL.
    final now = DateTime.now();
    await _dao.upsert(
      row.toCompanion(true).copyWith(
        logoUrl: Value(url),
        updatedAt: Value(now),
        localUpdatedAt: Value(now),
      ),
    );
    await _mirrorLogoUrl(businessId, url);
  }

  /// Push a single business's row, marking it failed (for retry) on error.
  Future<void> _safePush(String businessId) async {
    try {
      await _pushToRemote(businessId);
    } catch (e, st) {
      debugPrint('[Logo] Push failed for $businessId: $e\n$st');
      await _dao.updateSyncStatus(
        id: businessId,
        status: SyncStatus.failed,
        error: e.toString(),
      );
    }
  }

  /// Mirror the public URL onto businesses.logo_url + refresh the shell's cache.
  /// Best-effort — the receipt logo is already saved, so a mirror failure only
  /// delays the shell/profile picking up the new URL until the next sync.
  Future<void> _mirrorLogoUrl(String businessId, String url) async {
    try {
      await _businessRemote.updateLogoUrl(businessId: businessId, url: url);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'biz_logo_$businessId',
        '$url?t=${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e, st) {
      debugPrint('[Logo] Mirror to businesses.logo_url failed: $e\n$st');
    }
  }

  Future<String> _writeLogoFile(
    String businessId,
    Uint8List bytes,
    String safeExt,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final logoDir = Directory(p.join(dir.path, 'business_logos'));
    if (!await logoDir.exists()) await logoDir.create(recursive: true);
    final file = File(p.join(logoDir.path, '$businessId$safeExt'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Upsert just the logo columns + mark pending. Creates the row (id =
  /// businessId, matching the rest of this feature) if none exists yet.
  Future<void> _persistLogo({
    required String businessId,
    required String localPath,
    required String url,
  }) async {
    final now = DateTime.now();
    final existing = await _dao.getByBusinessId(businessId);
    if (existing != null) {
      await _dao.upsert(
        existing.toCompanion(true).copyWith(
          logoLocalPath: Value(localPath),
          logoUrl: Value(url),
          syncStatus: Value(SyncStatus.pendingUpdate.toInt()),
          updatedAt: Value(now),
          localUpdatedAt: Value(now),
        ),
      );
    } else {
      await _dao.upsert(
        ReceiptSettingsTableCompanion.insert(
          id: businessId,
          businessId: businessId,
          logoLocalPath: Value(localPath),
          logoUrl: Value(url),
          syncStatus: Value(SyncStatus.pendingUpload.toInt()),
          updatedAt: Value(now),
          localUpdatedAt: Value(now),
        ),
      );
    }
  }

  String _mimeForExt(String ext) {
    final e = ext.toLowerCase();
    if (e == '.png') return 'image/png';
    if (e == '.webp') return 'image/webp';
    return 'image/jpeg';
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
      // The DAO's upsertFromServer guards against clobbering unsynced local
      // edits (e.g. a logo picked offline), so no extra guard is needed here.
      if (data != null) await _dao.upsertFromServer(data);
    } catch (e) {
      debugPrint('[ReceiptSettings] Pull failed: $e');
    }
  }

  Stream<int> watchPendingSyncCount() => _dao.watchPendingSyncCount();

  Future<void> clearAll() => _dao.clearAll();

  // ── Private ──────────────────────────────────────────────────────────────

  Future<void> _pushToRemote(String id) async {
    // Upload any queued logo file first so the row we push carries its URL.
    await _ensureLogoUploaded(id);
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
      'updated_at': row.updatedAt.toUtc().toIso8601String(),
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
      updatedAt: Value(now),
      syncStatus: Value(status.toInt()),
      localUpdatedAt: Value(now),
    );
  }
}
