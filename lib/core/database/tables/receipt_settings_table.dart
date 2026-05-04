import 'package:drift/drift.dart';

/// Stores all receipt configuration for a business.
/// One row per businessId — upserted on every save.
/// Fully offline-first: changes write here first, sync queued via syncStatus.
@DataClassName('ReceiptSettingsRow')
class ReceiptSettingsTable extends Table {
  @override
  String get tableName => 'receipt_settings';

  // ── Identity ────────────────────────────────────────────────────────────
  TextColumn get id => text()(); // UUID = businessId (1:1)
  TextColumn get businessId => text()();

  // ── Business details ────────────────────────────────────────────────────
  TextColumn get businessName => text().withDefault(const Constant(''))();
  TextColumn get storeName => text().withDefault(const Constant(''))();
  TextColumn get ownerName => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get contactNumber => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get website => text().withDefault(const Constant(''))();
  TextColumn get tinNumber => text().withDefault(const Constant(''))();
  TextColumn get permitNumber => text().withDefault(const Constant(''))();

  // ── Receipt content ─────────────────────────────────────────────────────
  TextColumn get headerText => text().withDefault(const Constant(''))();
  TextColumn get footerText =>
      text().withDefault(const Constant('Thank you for your purchase!'))();
  TextColumn get returnPolicy => text().withDefault(const Constant(''))();
  TextColumn get customNotes => text().withDefault(const Constant(''))();

  // ── Logo ────────────────────────────────────────────────────────────────
  BoolColumn get showLogo =>
      boolean().withDefault(const Constant(true))();
  /// Local file path (may be empty). Supabase public URL stored in logoUrl.
  TextColumn get logoLocalPath => text().withDefault(const Constant(''))();
  TextColumn get logoUrl => text().withDefault(const Constant(''))();

  // ── Toggle switches ─────────────────────────────────────────────────────
  BoolColumn get showQrCode =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get showTaxBreakdown =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showCashierName =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showCustomerName =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get showDateTime =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showOrderId =>
      boolean().withDefault(const Constant(true))();

  // ── Printing preferences ────────────────────────────────────────────────
  /// '58mm' | '80mm'
  TextColumn get paperSize =>
      text().withDefault(const Constant('80mm'))();
  /// 'small' | 'medium' | 'large'
  TextColumn get fontSize =>
      text().withDefault(const Constant('medium'))();
  /// 'left' | 'center' | 'right'
  TextColumn get textAlignment =>
      text().withDefault(const Constant('center'))();
  BoolColumn get autoPrintAfterCheckout =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get printDuplicateCopy =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get thermalPrinterEnabled =>
      boolean().withDefault(const Constant(false))();

  // ── Currency & tax ──────────────────────────────────────────────────────
  TextColumn get currencySymbol =>
      text().withDefault(const Constant('₱'))();
  RealColumn get taxPercentage =>
      real().withDefault(const Constant(0.0))();
  RealColumn get serviceChargePercentage =>
      real().withDefault(const Constant(0.0))();
  BoolColumn get vatInclusive =>
      boolean().withDefault(const Constant(true))();

  // ── Timestamps & sync ───────────────────────────────────────────────────
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// 0=pendingUpload 1=pendingUpdate 2=pendingDelete 3=synced 4=failed
  IntColumn get syncStatus =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncAttempt => dateTime().nullable()();
  TextColumn get syncError => text().nullable()();
  DateTimeColumn get localUpdatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
