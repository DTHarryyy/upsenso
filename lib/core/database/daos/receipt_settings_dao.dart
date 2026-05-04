import 'package:drift/drift.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/tables/receipt_settings_table.dart';
import 'package:pos/core/sync/sync_status.dart';

part 'receipt_settings_dao.g.dart';

@DriftAccessor(tables: [ReceiptSettingsTable])
class ReceiptSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$ReceiptSettingsDaoMixin {
  ReceiptSettingsDao(super.db);

  /// Watch a single row for a business — emits on every local change.
  Stream<ReceiptSettingsRow?> watchByBusinessId(String businessId) {
    return (select(receiptSettingsTable)
          ..where((t) => t.businessId.equals(businessId)))
        .watchSingleOrNull();
  }

  Future<ReceiptSettingsRow?> getByBusinessId(String businessId) {
    return (select(receiptSettingsTable)
          ..where((t) => t.businessId.equals(businessId)))
        .getSingleOrNull();
  }

  /// Upsert local settings and mark as pending sync.
  Future<void> upsert(ReceiptSettingsTableCompanion companion) {
    return into(receiptSettingsTable).insertOnConflictUpdate(companion);
  }

  Future<void> updateSyncStatus({
    required String id,
    required SyncStatus status,
    String? error,
  }) {
    return (update(receiptSettingsTable)..where((t) => t.id.equals(id))).write(
      ReceiptSettingsTableCompanion(
        syncStatus: Value(status.toInt()),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: Value(error),
      ),
    );
  }

  Future<List<ReceiptSettingsRow>> getPendingSync() {
    return (select(receiptSettingsTable)
          ..where(
            (t) => t.syncStatus.isIn([
              SyncStatus.pendingUpload.toInt(),
              SyncStatus.pendingUpdate.toInt(),
              SyncStatus.failed.toInt(),
            ]),
          ))
        .get();
  }

  Stream<int> watchPendingSyncCount() {
    final countExp = receiptSettingsTable.id.count();
    final query = selectOnly(receiptSettingsTable)
      ..addColumns([countExp])
      ..where(receiptSettingsTable.syncStatus.isIn([
        SyncStatus.pendingUpload.toInt(),
        SyncStatus.pendingUpdate.toInt(),
        SyncStatus.failed.toInt(),
      ]));
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<void> upsertFromServer(Map<String, dynamic> row) {
    return into(receiptSettingsTable).insertOnConflictUpdate(
      ReceiptSettingsTableCompanion.insert(
        id: row['id'] as String,
        businessId: row['business_id'] as String,
        businessName: Value(row['business_name'] as String? ?? ''),
        storeName: Value(row['store_name'] as String? ?? ''),
        ownerName: Value(row['owner_name'] as String? ?? ''),
        address: Value(row['address'] as String? ?? ''),
        contactNumber: Value(row['contact_number'] as String? ?? ''),
        email: Value(row['email'] as String? ?? ''),
        website: Value(row['website'] as String? ?? ''),
        tinNumber: Value(row['tin_number'] as String? ?? ''),
        permitNumber: Value(row['permit_number'] as String? ?? ''),
        headerText: Value(row['header_text'] as String? ?? ''),
        footerText: Value(
            row['footer_text'] as String? ?? 'Thank you for your purchase!'),
        returnPolicy: Value(row['return_policy'] as String? ?? ''),
        customNotes: Value(row['custom_notes'] as String? ?? ''),
        showLogo: Value(row['show_logo'] as bool? ?? true),
        logoLocalPath: const Value(''),
        logoUrl: Value(row['logo_url'] as String? ?? ''),
        showQrCode: Value(row['show_qr_code'] as bool? ?? false),
        showTaxBreakdown: Value(row['show_tax_breakdown'] as bool? ?? true),
        showCashierName: Value(row['show_cashier_name'] as bool? ?? true),
        showCustomerName: Value(row['show_customer_name'] as bool? ?? false),
        showDateTime: Value(row['show_date_time'] as bool? ?? true),
        showOrderId: Value(row['show_order_id'] as bool? ?? true),
        paperSize: Value(row['paper_size'] as String? ?? '80mm'),
        fontSize: Value(row['font_size'] as String? ?? 'medium'),
        textAlignment: Value(row['text_alignment'] as String? ?? 'center'),
        autoPrintAfterCheckout:
            Value(row['auto_print_after_checkout'] as bool? ?? false),
        printDuplicateCopy:
            Value(row['print_duplicate_copy'] as bool? ?? false),
        thermalPrinterEnabled:
            Value(row['thermal_printer_enabled'] as bool? ?? false),
        currencySymbol: Value(row['currency_symbol'] as String? ?? '₱'),
        taxPercentage:
            Value((row['tax_percentage'] as num?)?.toDouble() ?? 0.0),
        serviceChargePercentage: Value(
            (row['service_charge_percentage'] as num?)?.toDouble() ?? 0.0),
        vatInclusive: Value(row['vat_inclusive'] as bool? ?? true),
        updatedAt: Value(DateTime.tryParse(
                row['updated_at'] as String? ?? '') ??
            DateTime.now()),
        syncStatus: Value(SyncStatus.synced.toInt()),
      ),
    );
  }

  Future<void> clearAll() => delete(receiptSettingsTable).go();
}
