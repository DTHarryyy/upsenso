import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/errors/audit_chain_conflict_exception.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/database/daos/branches_dao.dart';
import 'package:pos/core/database/daos/businesses_dao.dart';
import 'package:pos/core/database/daos/categories_dao.dart';
import 'package:pos/core/database/daos/expenses_dao.dart';
import 'package:pos/core/database/daos/inventory_levels_dao.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/database/daos/product_barcodes_dao.dart';
import 'package:pos/core/database/daos/stock_ledger_dao.dart';
import 'package:pos/core/database/daos/transactions_dao.dart';
import 'package:pos/core/database/daos/draft_sales_dao.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/database/daos/employees_dao.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/core/sync/audit_log_retention.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/business/data/datasources/business_remote_ds.dart';
import 'package:pos/features/business/data/models/business_model.dart';
import 'package:pos/features/business/domain/entities/branch.dart';
import 'package:pos/features/expenses/data/datasources/expenses_remote_ds.dart';
import 'package:pos/features/products/data/datasources/products_remote_ds.dart';
import 'package:pos/features/pos/data/datasources/transactions_remote_ds.dart';
import 'package:pos/features/settings/data/receipt_settings_repository.dart';
import 'package:pos/features/audit_logs/data/datasources/audit_log_remote_ds.dart';
import 'package:pos/features/audit_logs/data/audit_log_sync_mapper.dart';
import 'package:pos/features/employees/data/datasources/employees_remote_ds.dart';
import 'package:pos/core/database/daos/purchase_order_lines_dao.dart';
import 'package:pos/core/database/daos/goods_receipts_dao.dart';
import 'package:pos/core/database/daos/goods_receipt_items_dao.dart';
import 'package:pos/core/database/daos/purchase_orders_dao.dart';
import 'package:pos/core/database/daos/recipe_lines_dao.dart';
import 'package:pos/core/database/daos/sync_state_dao.dart';
import 'package:pos/core/database/daos/suppliers_dao.dart';
import 'package:pos/core/database/daos/customers_dao.dart';
import 'package:pos/features/crm/data/datasources/customer_remote_ds.dart';
import 'package:pos/core/services/image_service.dart';
import 'package:pos/core/services/invoice_number_service.dart';
import 'package:pos/core/database/daos/invoice_sequences_dao.dart';
import 'package:pos/features/procurement/data/datasources/procurement_remote_ds.dart';
import 'package:pos/core/database/daos/refunds_dao.dart';
import 'package:pos/features/pos/data/datasources/refunds_remote_ds.dart';
import 'package:pos/features/settings/data/refund_settings_repository.dart';
import 'package:pos/core/database/daos/fraud_flags_dao.dart';
import 'package:pos/features/alert/data/datasources/fraud_flags_remote_ds.dart';
import 'package:pos/core/database/daos/devices_dao.dart';
import 'package:pos/core/device/devices_remote_ds.dart';
import 'package:pos/core/device/device_registration_service.dart';
import 'package:pos/core/permissions/entitlement_service.dart';

/// Service to handle synchronization between local Drift DB and Supabase
class SyncService {
  final AuthContextDao _authContextDao;
  final ActiveBusinessContext _activeBusinessContext;
  final BranchesDao _branchesDao;
  final BusinessesDao _businessesDao;
  final CategoriesDao _categoriesDao;
  final ExpensesDao _expensesDao;
  final InventoryLevelsDao _inventoryLevelsDao;
  final ProductsDao _productsDao;
  final ProductVariantsDao _productVariantsDao;
  final ProductBarcodesDao _productBarcodesDao;
  final StockLedgerDao _stockLedgerDao;
  final TransactionsDao _transactionsDao;
  final DraftSalesDao _draftSalesDao;
  final BusinessRemoteDs _businessRemoteDs;
  final ExpensesRemoteDs _expensesRemoteDs;
  final ProductsRemoteDs _productsRemoteDs;
  final TransactionsRemoteDs _transactionsRemoteDs;
  final ConnectivityService _connectivityService;
  final ReceiptSettingsRepository _receiptSettingsRepo;
  final AuditLogsDao _auditLogsDao;
  final AuditLogRemoteDs _auditLogRemoteDs;
  final EmployeesDao _employeesDao;
  final EmployeesRemoteDs _employeesRemoteDs;
  final SuppliersDao _suppliersDao;
  final PurchaseOrdersDao _purchaseOrdersDao;
  final PurchaseOrderLinesDao _purchaseOrderLinesDao;
  final GoodsReceiptsDao _goodsReceiptsDao;
  final GoodsReceiptItemsDao _goodsReceiptItemsDao;
  final ProcurementRemoteDs _procurementRemoteDs;
  final CustomersDao _customersDao;
  final CustomerRemoteDs _customerRemoteDs;
  final RecipeLinesDao _recipeLinesDao;
  final SyncStateDao _syncStateDao;
  final ImageService _imageService;
  final RefundsDao _refundsDao;
  final RefundsRemoteDs _refundsRemoteDs;
  final RefundSettingsRepository _refundSettingsRepo;
  final FraudFlagsDao _fraudFlagsDao;
  final FraudFlagsRemoteDs _fraudFlagsRemoteDs;
  final DevicesDao _devicesDao;
  final DevicesRemoteDs _devicesRemoteDs;
  final EntitlementService _entitlementService;
  final DeviceRegistrationService _deviceRegistrationService;

  // Built lazily from existing deps (no DI change) so duplicate-invoice
  // recovery can re-claim a fresh server number on a 23505 conflict.
  InvoiceNumberService? _invoiceNumberService;
  InvoiceNumberService get _invoiceService =>
      _invoiceNumberService ??= InvoiceNumberService(
        _transactionsRemoteDs.client,
        InvoiceSequencesDao(_transactionsDao.attachedDatabase),
        _connectivityService,
      );

  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _retryTimer;

  /// Re-reads the entitlement on a slow cadence. Without it the plan was only
  /// fetched at startup, on auth change, and when the Billing page opened — so a
  /// subscription revoked server-side (refund, chargeback, RTDN expiry) kept its
  /// access for as long as the app stayed open.
  Timer? _entitlementTimer;

  /// Long on purpose: entitlement changes are rare and the RPC is not free. The
  /// server is the enforcement point regardless — this only keeps the local
  /// mirror from going stale for days.
  static const _entitlementRefreshInterval = Duration(hours: 6);
  bool _isSyncing = false;
  bool _initCalled = false;
  // Holds the most recent businessId provided to syncAll() while a sync was
  // already running. After the current sync finishes we re-run pullFromServer
  // with this id so no data is missed.
  String? _pendingBusinessId;

  /// Set by AuthBloc (the sole owner of tenant identity — see
  /// ActiveBusinessContext). Invoked when a push is rejected by RLS (42501)
  /// in a way that points at a stale active business_id — e.g. the cached
  /// tenant was deleted/recreated server-side while this device was offline.
  /// AuthBloc re-resolves identity against the server and, if confirmed,
  /// wipes the orphaned local data and resyncs. This is the mechanism that
  /// actually guarantees convergence: proactive revalidation on app
  /// resume/login can still lose the race against this service's own
  /// immediate/connectivity-triggered syncAll() in [init], but reacting to
  /// the real failure can't lose that race — it only fires after it happens.
  void Function(String staleBusinessId)? onTenantRejected;

  /// Invoked (fire-and-forget) after each completed sync cycle — the fraud
  /// engine hooks its periodic full sweep here: data is freshest right after
  /// a pull, and the cadence already covers app-resume + connectivity.
  void Function()? onSyncCompleted;

  /// Invoked when an audit push hits the server's chain index — a benign
  /// same-device restart (wiped local DB + surviving uid). Wired in DI to
  /// AuditLogService.reconcileConflictedTail, which re-chains the unsynced
  /// tail past the server head so it pushes cleanly next cycle.
  Future<void> Function(String businessId)? onChainConflict;

  /// Materializes staged audit entries into chained rows before they push.
  /// Wired in DI to AuditLogService.drainOutbox (kept as a callback so
  /// core/sync doesn't take a hard dependency on the audit service).
  Future<void> Function()? drainAuditOutbox;

  /// Refetches audit rows the created_at-keyset pull structurally misses
  /// (late-pushed rows land behind the watermark). Wired in DI to
  /// AuditMirrorRepair.repair; runs after each audit pull so seq gaps and
  /// stale tails never survive long enough to read as tampering.
  Future<int> Function(String businessId)? repairAuditMirror;

  /// Invoked once when cloud access is first gained (Free→paid upgrade),
  /// before the first syncAll. Wired in DI to BackfillService.markAllForUpload
  /// so a re-upgrade re-queues previously-synced rows (design §7.2). Callback,
  /// so core/sync doesn't depend on the backfill service.
  Future<void> Function()? onCloudGained;

  SyncService({
    required AuthContextDao authContextDao,
    required ActiveBusinessContext activeBusinessContext,
    required BranchesDao branchesDao,
    required BusinessesDao businessesDao,
    required CategoriesDao categoriesDao,
    required ExpensesDao expensesDao,
    required InventoryLevelsDao inventoryLevelsDao,
    required ProductsDao productsDao,
    required ProductVariantsDao productVariantsDao,
    required ProductBarcodesDao productBarcodesDao,
    required StockLedgerDao stockLedgerDao,
    required TransactionsDao transactionsDao,
    required DraftSalesDao draftSalesDao,
    required BusinessRemoteDs businessRemoteDs,
    required ExpensesRemoteDs expensesRemoteDs,
    required ProductsRemoteDs productsRemoteDs,
    required TransactionsRemoteDs transactionsRemoteDs,
    required ConnectivityService connectivityService,
    required ReceiptSettingsRepository receiptSettingsRepository,
    required AuditLogsDao auditLogsDao,
    required AuditLogRemoteDs auditLogRemoteDs,
    required EmployeesDao employeesDao,
    required EmployeesRemoteDs employeesRemoteDs,
    required SuppliersDao suppliersDao,
    required PurchaseOrdersDao purchaseOrdersDao,
    required PurchaseOrderLinesDao purchaseOrderLinesDao,
    required GoodsReceiptsDao goodsReceiptsDao,
    required GoodsReceiptItemsDao goodsReceiptItemsDao,
    required ProcurementRemoteDs procurementRemoteDs,
    required CustomersDao customersDao,
    required CustomerRemoteDs customerRemoteDs,
    required RecipeLinesDao recipeLinesDao,
    required SyncStateDao syncStateDao,
    required ImageService imageService,
    required RefundsDao refundsDao,
    required RefundsRemoteDs refundsRemoteDs,
    required RefundSettingsRepository refundSettingsRepository,
    required FraudFlagsDao fraudFlagsDao,
    required FraudFlagsRemoteDs fraudFlagsRemoteDs,
    required DevicesDao devicesDao,
    required DevicesRemoteDs devicesRemoteDs,
    required EntitlementService entitlementService,
    required DeviceRegistrationService deviceRegistrationService,
  }) : _authContextDao = authContextDao,
       _activeBusinessContext = activeBusinessContext,
       _branchesDao = branchesDao,
       _businessesDao = businessesDao,
       _categoriesDao = categoriesDao,
       _expensesDao = expensesDao,
       _inventoryLevelsDao = inventoryLevelsDao,
       _productsDao = productsDao,
       _productVariantsDao = productVariantsDao,
       _productBarcodesDao = productBarcodesDao,
       _stockLedgerDao = stockLedgerDao,
       _transactionsDao = transactionsDao,
       _draftSalesDao = draftSalesDao,
       _businessRemoteDs = businessRemoteDs,
       _expensesRemoteDs = expensesRemoteDs,
       _productsRemoteDs = productsRemoteDs,
       _transactionsRemoteDs = transactionsRemoteDs,
       _connectivityService = connectivityService,
       _receiptSettingsRepo = receiptSettingsRepository,
       _auditLogsDao = auditLogsDao,
       _auditLogRemoteDs = auditLogRemoteDs,
       _employeesDao = employeesDao,
       _employeesRemoteDs = employeesRemoteDs,
       _suppliersDao = suppliersDao,
       _purchaseOrdersDao = purchaseOrdersDao,
       _purchaseOrderLinesDao = purchaseOrderLinesDao,
       _goodsReceiptsDao = goodsReceiptsDao,
       _goodsReceiptItemsDao = goodsReceiptItemsDao,
       _procurementRemoteDs = procurementRemoteDs,
       _customersDao = customersDao,
       _customerRemoteDs = customerRemoteDs,
       _recipeLinesDao = recipeLinesDao,
       _syncStateDao = syncStateDao,
       _imageService = imageService,
       _refundsDao = refundsDao,
       _refundsRemoteDs = refundsRemoteDs,
       _refundSettingsRepo = refundSettingsRepository,
       _fraudFlagsDao = fraudFlagsDao,
       _fraudFlagsRemoteDs = fraudFlagsRemoteDs,
       _devicesDao = devicesDao,
       _devicesRemoteDs = devicesRemoteDs,
       _entitlementService = entitlementService,
       _deviceRegistrationService = deviceRegistrationService;

  /// Resolves the businessId a sync should operate on.
  ///
  /// Connectivity-/timer-triggered syncs arrive with no businessId; they must
  /// resolve it from the AUTHORITATIVE active session — never from a
  /// tenant-agnostic "first cached row" lookup, which is how a background pull
  /// could load a previous account's data on a shared device. When no business
  /// is active (logged out, or mid-onboarding before a business exists) the pull
  /// is skipped entirely.
  String? _resolveBusinessId(String? provided) {
    final active = _activeBusinessContext.businessId;
    final resolved = resolveSyncBusinessId(provided: provided, active: active);
    if (resolved == null && provided != null && provided.trim().isNotEmpty) {
      debugPrint(
        '[SYNC] Refusing pull for $provided — active business is $active',
      );
    }
    return resolved;
  }

  /// ── LOCAL-ONLY TEST KILL SWITCH ──────────────────────────────────────────
  /// When `false`, ALL Supabase sync is disabled — no push, no pull, and no
  /// background timers/connectivity listeners. The app runs purely against the
  /// local Drift database, so the offline data layer can be verified in
  /// isolation. Flip back to `true` to restore normal sync.
  /// (Added 2026-07-04 for local-DB testing.)
  static const bool syncEnabled = true;

  /// M7.1 §7.1: cloud sync is a paid entitlement. Free = local-only — Drift
  /// is the sole store and no business data ever leaves the device. This is
  /// the UX gate; the server enforces the same rule with has_cloud_access()
  /// RESTRICTIVE RLS, so a tampered client gains nothing.
  /// Cloud sync requires BOTH a cloud entitlement AND this device being
  /// registered under the plan's device cap (M7.1 §6.3). A registered device
  /// that gets revoked, or a device over the cap, stops syncing — the server
  /// enforces the same via register_device / has_cloud_access.
  bool get _cloudAllowed =>
      _entitlementService.cloudEnabled &&
      _deviceRegistrationService.isRegistered;

  /// Re-arm/pause when the plan changes (upgrade lands, trial expires, lapse
  /// confirmed) or device registration status changes. Hooked once; survives
  /// pause() so a later upgrade/registration can re-arm.
  bool _entitlementHooked = false;

  void _onEntitlementChanged() {
    if (_cloudAllowed && !_initCalled) {
      debugPrint('[SYNC] Cloud entitlement gained — backfill + arm sync.');
      // Re-queue previously-synced rows first (§7.2), then arm; the first
      // syncAll then pushes a complete snapshot. Fire-and-forget: the mark is
      // idempotent and init() will also retry via the periodic timer.
      final backfill = onCloudGained;
      if (backfill != null) {
        backfill().whenComplete(init);
      } else {
        init();
      }
    } else if (!_cloudAllowed && _initCalled) {
      debugPrint('[SYNC] Cloud entitlement lost — pausing sync.');
      pause();
    }
  }

  /// Initialize sync service and listen for connectivity changes.
  /// Guards against being called multiple times (e.g. if MainNavigationPage
  /// is rebuilt) so we never accumulate duplicate listeners.
  void init() {
    if (!syncEnabled) {
      debugPrint('[SYNC] Disabled (syncEnabled=false) — local-only test mode.');
      return;
    }
    if (!_entitlementHooked) {
      _entitlementHooked = true;
      _entitlementService.entitlementRevision.addListener(
        _onEntitlementChanged,
      );
      _deviceRegistrationService.registrationRevision.addListener(
        _onEntitlementChanged,
      );
    }
    // Armed regardless of the cloud gate, and before the early return below:
    // it has to catch entitlement moving in BOTH directions — a plan bought on
    // another device, and one revoked out from under a running session.
    _entitlementTimer ??= Timer.periodic(
      _entitlementRefreshInterval,
      (_) => _refreshEntitlement(),
    );

    if (!_cloudAllowed) {
      debugPrint('[SYNC] Cloud sync off — local plan (M7.1 §7.1).');
      return;
    }
    if (_initCalled) return;
    _initCalled = true;

    // Sync immediately if already online at startup.
    _connectivityService.isConnected.then((online) {
      if (online) syncAll();
    });

    // Sync whenever connectivity is restored.
    _connectivitySubscription = _connectivityService.onConnectivityChanged
        .listen((isConnected) {
          if (isConnected) syncAll();
        });

    // Periodic retry every 60 s so that a failed initial sync doesn't leave
    // data pending forever (which would otherwise require a connectivity change
    // or app restart to trigger another attempt).
    _retryTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      syncAll().ignore();
    });
  }

  /// Pull the current plan from the server. Offline is not a failure — the
  /// cached snapshot stays authoritative and its own expiry math still applies.
  Future<void> _refreshEntitlement() async {
    if (!await _connectivityService.isConnected) return;
    final ok = await _entitlementService.syncEntitlement();
    if (!ok) debugPrint('[SYNC] Periodic entitlement refresh did not land.');
    // Re-check registration on the same tick. Without this, a device revoked
    // from another device kept syncing until the app was restarted, and a
    // device that hit the cap never noticed a slot being freed for it.
    await _deviceRegistrationService.ensureRegistered();
    // Heartbeat so `registered_devices.last_seen_at` is real — it's what the
    // owner sorts by when deciding which stale device to revoke.
    await _deviceRegistrationService.touch();
  }

  void dispose() {
    _retryTimer?.cancel();
    _entitlementTimer?.cancel();
    _entitlementTimer = null;
    _connectivitySubscription?.cancel();
  }

  /// Stop all background sync triggers on logout so no timer- or
  /// connectivity-driven pull can run while no account is active (which is when
  /// a stale tenant could otherwise be resolved). [init] re-arms on next login.
  void pause() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _pendingBusinessId = null;
    _initCalled = false;
    // _entitlementTimer deliberately survives. pause() also runs when cloud
    // access is LOST, and stopping the refresh there would leave a lapsed
    // account with no way back — nothing else re-arms it until a restart.
    // It is safe across a logout too: syncEntitlement() resolves the active
    // business at call time and no-ops when there isn't one.
  }

  /// Wipe all business-specific local data on logout so the next account
  /// starts with a clean slate. Called before emitting AuthUnauthenticated.
  ///
  /// Refuses to run while unsynced changes still exist locally — wiping them
  /// would silently discard sales/inventory that never reached the server —
  /// unless [force] is set. [force] exists for the one case where "unsynced"
  /// rows can never become synced: AuthBloc has confirmed via the server that
  /// this device's cached business_id no longer resolves for the signed-in
  /// user (business deleted/recreated, e.g. a test-data purge), so every
  /// locally-pending row for it is permanently orphaned, not just delayed.
  /// Callers passing force: true must log why first — this never discards
  /// silently. The wipe runs inside one DB transaction so a crash can't leave
  /// a half-cleared (partially-orphaned) local database.
  Future<void> clearLocalData({bool force = false}) async {
    final pending = await pendingSyncCount();
    if (pending > 0 && !force) {
      debugPrint(
        '[SYNC] clearLocalData aborted: $pending unsynced record(s) remain',
      );
      throw StateError(
        'Refusing to clear local data: $pending unsynced record(s) pending',
      );
    }
    await _transactionsDao.attachedDatabase.transaction(() async {
      await _inventoryLevelsDao.clearAll();
      await _stockLedgerDao.clearAll();
      await _expensesDao.clearAll();
      await _refundsDao.clearAll();
      await _transactionsDao.clearAll();
      await _draftSalesDao.clearAll();
      await _productBarcodesDao.clearAll();
      await _productVariantsDao.clearAll();
      await _productsDao.clearAll();
      await _categoriesDao.clearAll();
      await _branchesDao.clearAll();
      await _businessesDao.clearAll();
      await _receiptSettingsRepo.clearAll();
      await _auditLogsDao.clearAll();
      await _fraudFlagsDao.clearAll();
      await _devicesDao.clearAll();
      await _employeesDao.clearAll();
      await _suppliersDao.clearAll();
      await _customersDao.clearAll();
      await _goodsReceiptItemsDao.clearAll();
      await _goodsReceiptsDao.clearAll();
      await _purchaseOrderLinesDao.clearAll();
      await _purchaseOrdersDao.clearAll();
      await _recipeLinesDao.clearAll();
      // Reset delta-sync watermarks so the next sync does a fresh full pull —
      // otherwise a stale watermark would skip rows that the wipe just removed.
      await _syncStateDao.clearAll();
      await _authContextDao.clearAll();
    });
  }

  /// One-shot total of records still waiting to reach the server across every
  /// table. Used by logout to refuse a destructive local wipe while unsynced
  /// sales/inventory still exist locally.
  Future<int> pendingSyncCount() async {
    final counts = await Future.wait<int>([
      _branchesDao.getPendingSync().then<int>((r) => r.length),
      _businessesDao.getPendingSync().then<int>((r) => r.length),
      _categoriesDao.getPendingSync().then<int>((r) => r.length),
      _productsDao.getPendingSync().then<int>((r) => r.length),
      _productVariantsDao.getPendingSync().then<int>((r) => r.length),
      _productBarcodesDao.getPendingSync().then<int>((r) => r.length),
      _transactionsDao.getPendingSync().then<int>((r) => r.length),
      _refundsDao.getPendingSync().then<int>((r) => r.length),
      _expensesDao.getPendingSync().then<int>((r) => r.length),
      _inventoryLevelsDao.getPendingSync().then<int>((r) => r.length),
      _stockLedgerDao.getPendingSync().then<int>((r) => r.length),
      _employeesDao.getPendingSync().then<int>((r) => r.length),
      _suppliersDao.getPendingSync().then<int>((r) => r.length),
      _customersDao.getPendingSync().then<int>((r) => r.length),
      _purchaseOrdersDao.getPendingSync().then<int>((r) => r.length),
      _purchaseOrderLinesDao.getPendingSync().then<int>((r) => r.length),
      _recipeLinesDao.getPendingSync().then<int>((r) => r.length),
    ]);
    return counts.fold<int>(0, (sum, n) => sum + n);
  }

  /// check kapag may internet connection
  Future<bool> get isOnline => _connectivityService.isConnected;

  /// Reactive total count of pending sync records across ALL tables.
  Stream<int> watchTotalPendingSyncCount() {
    int cat = 0,
        prod = 0,
        vars = 0,
        pbc = 0,
        orders = 0,
        exp = 0,
        inv = 0,
        led = 0,
        rcpt = 0,
        audit = 0,
        emp = 0,
        sup = 0,
        po = 0,
        pol = 0,
        gr = 0,
        gri = 0,
        rcp = 0,
        rfnd = 0,
        cust = 0;
    final controller = StreamController<int>.broadcast();

    void emit() {
      if (!controller.isClosed) {
        controller.add(
          cat +
              prod +
              vars +
              pbc +
              orders +
              exp +
              inv +
              led +
              rcpt +
              audit +
              emp +
              sup +
              po +
              pol +
              gr +
              gri +
              rcp +
              rfnd +
              cust,
        );
      }
    }

    final s1 = _categoriesDao.watchPendingSyncCount().listen((n) {
      cat = n;
      emit();
    });
    final s2 = _productsDao.watchPendingSyncCount().listen((n) {
      prod = n;
      emit();
    });
    final s3 = _productVariantsDao.watchPendingSyncCount().listen((n) {
      vars = n;
      emit();
    });
    final s19 = _productBarcodesDao.watchPendingSyncCount().listen((n) {
      pbc = n;
      emit();
    });
    final s4 = _transactionsDao.watchPendingSyncCount().listen((n) {
      orders = n;
      emit();
    });
    final s5 = _expensesDao.watchPendingSyncCount().listen((n) {
      exp = n;
      emit();
    });
    final s6 = _inventoryLevelsDao.watchPendingSyncCount().listen((n) {
      inv = n;
      emit();
    });
    final s7 = _stockLedgerDao.watchPendingSyncCount().listen((n) {
      led = n;
      emit();
    });
    // ignore: avoid_function_literals_in_foreach_calls — DAO doesn't expose stream directly
    final s8 = _receiptSettingsRepo.watchPendingSyncCount().listen((n) {
      rcpt = n;
      emit();
    });
    final s9 = _auditLogsDao.watchPendingSyncCount().listen((n) {
      audit = n;
      emit();
    });
    final s10 = _employeesDao.watchPendingSyncCount().listen((n) {
      emp = n;
      emit();
    });
    final s11 = _suppliersDao.watchPendingSyncCount().listen((n) {
      sup = n;
      emit();
    });
    final s12 = _purchaseOrdersDao.watchPendingSyncCount().listen((n) {
      po = n;
      emit();
    });
    final s13 = _purchaseOrderLinesDao.watchPendingSyncCount().listen((n) {
      pol = n;
      emit();
    });
    final s14 = _recipeLinesDao.watchPendingSyncCount().listen((n) {
      rcp = n;
      emit();
    });
    final s15 = _refundsDao.watchPendingSyncCount().listen((n) {
      rfnd = n;
      emit();
    });
    final s16 = _goodsReceiptsDao.watchPendingSyncCount().listen((n) {
      gr = n;
      emit();
    });
    final s17 = _goodsReceiptItemsDao.watchPendingSyncCount().listen((n) {
      gri = n;
      emit();
    });
    final s18 = _customersDao.watchPendingSyncCount().listen((n) {
      cust = n;
      emit();
    });

    controller.onCancel = () {
      s1.cancel();
      s2.cancel();
      s3.cancel();
      s4.cancel();
      s5.cancel();
      s6.cancel();
      s7.cancel();
      s8.cancel();
      s9.cancel();
      s10.cancel();
      s11.cancel();
      s12.cancel();
      s13.cancel();
      s14.cancel();
      s15.cancel();
      s16.cancel();
      s17.cancel();
      s18.cancel();
      s19.cancel();
      controller.close();
    };

    return controller.stream;
  }

  /// Push all pending local changes to Supabase, then pull from server.
  Future<SyncResult> syncAll({String? businessId}) async {
    if (!syncEnabled) {
      return SyncResult(
        success: true,
        message: 'Sync disabled — local-only test mode',
      );
    }
    if (!_cloudAllowed) {
      // Not an error: on a local plan, pending rows simply stay local. They
      // are pushed by the first-sync backfill when the tenant upgrades.
      return SyncResult(success: true, message: 'Cloud sync off — local plan');
    }
    if (_isSyncing) {
      // If the caller provided a businessId, keep it so the running sync (or
      // the follow-up pull after it) can use it.  This prevents the common
      // startup race where AuthBloc calls syncAll(businessId: id) while
      // SyncService.init() already kicked off a no-businessId syncAll().
      if (businessId != null) _pendingBusinessId = businessId;
      return SyncResult(success: false, message: 'Sync already in progress');
    }
    // Set the flag immediately — before any await — so concurrent calls that
    // arrive during the isOnline check are correctly blocked.
    _isSyncing = true;
    // Capture and clear any pending businessId queued during a prior sync.
    final queued = _pendingBusinessId;
    _pendingBusinessId = null;
    // Prefer the explicitly-provided businessId; fall back to the queued one.
    businessId ??= queued;

    final online = await isOnline;
    if (!online) {
      _isSyncing = false;
      return SyncResult(success: false, message: 'No internet connection');
    }

    try {
      // upload na here  bag o i pull
      final branchResult = await _syncBranches();
      final businessResult = await _syncBusinesses();
      final categoryResult = await _syncCategories();
      final productResult = await _syncProducts();
      final variantResult = await _syncProductVariants();
      final barcodeResult = await _syncProductBarcodes();
      final orderResult = await _syncTransactions();
      // Refunds push after transactions so the FK parent already exists
      // on the server when the refund row is inserted.
      // Materialize any staged audit entries, then push audit logs BEFORE the
      // records they explain (refunds/ledger). Otherwise a refund can reach
      // the server in a cycle that's interrupted before its audit row does,
      // leaving a transient "refund with no audit trail" a server-side check
      // would false-positive on.
      if (drainAuditOutbox != null) await drainAuditOutbox!();
      final auditResult = await _syncAuditLogs();
      final refundResult = await _syncRefunds();
      final expenseResult = await _syncExpenses();
      final inventoryResult = await _syncInventoryLevels();
      // Purchase orders push before the stock ledger so a same-session
      // create-PO-then-receive flow already has its parent PO on the server
      // when the ledger's purchase_order source-document check runs.
      final poResult = await _syncPurchaseOrders();
      final ledgerResult = await _syncStockLedger();
      await _syncReceiptSettings(); // fire-and-forget style; errors logged internally
      await _syncDevices(); // fire-and-forget style; errors logged internally
      final fraudResult = await _syncFraudFlags();
      final employeeResult = await _syncEmployees();
      final supplierResult = await _syncSuppliers();
      final customerResult = await _syncCustomers();
      final polResult = await _syncPurchaseOrderLines();
      final grResult = await _syncGoodsReceipts();
      final griResult = await _syncGoodsReceiptItems();
      final recipeResult = await _syncRecipeLines();

      final int totalSynced =
          branchResult.syncedCount +
          businessResult.syncedCount +
          categoryResult.syncedCount +
          productResult.syncedCount +
          variantResult.syncedCount +
          barcodeResult.syncedCount +
          orderResult.syncedCount +
          refundResult.syncedCount +
          expenseResult.syncedCount +
          inventoryResult.syncedCount +
          ledgerResult.syncedCount +
          employeeResult.syncedCount +
          supplierResult.syncedCount +
          customerResult.syncedCount +
          poResult.syncedCount +
          polResult.syncedCount +
          grResult.syncedCount +
          griResult.syncedCount +
          recipeResult.syncedCount +
          auditResult.syncedCount +
          fraudResult.syncedCount;
      final int totalFailed =
          branchResult.failedCount +
          businessResult.failedCount +
          categoryResult.failedCount +
          productResult.failedCount +
          variantResult.failedCount +
          barcodeResult.failedCount +
          orderResult.failedCount +
          refundResult.failedCount +
          expenseResult.failedCount +
          inventoryResult.failedCount +
          ledgerResult.failedCount +
          employeeResult.failedCount +
          supplierResult.failedCount +
          customerResult.failedCount +
          poResult.failedCount +
          polResult.failedCount +
          grResult.failedCount +
          griResult.failedCount +
          recipeResult.failedCount +
          auditResult.failedCount +
          fraudResult.failedCount;

      // pull kapag may businessId (either provided or from auth context)
      final effectiveBusinessId = _resolveBusinessId(businessId);

      // A 42501 among this pass's push errors means the active business_id
      // was rejected by RLS for the signed-in user — the cached tenant no
      // longer resolves server-side. Self-healing that is AuthBloc's job (it
      // owns ActiveBusinessContext); just hand off which businessId was
      // rejected.
      if (effectiveBusinessId != null) {
        final pushErrors = [
          ...branchResult.errors,
          ...businessResult.errors,
          ...categoryResult.errors,
          ...productResult.errors,
          ...variantResult.errors,
          ...barcodeResult.errors,
          ...orderResult.errors,
          ...refundResult.errors,
          ...expenseResult.errors,
          ...inventoryResult.errors,
          ...ledgerResult.errors,
          ...employeeResult.errors,
          ...supplierResult.errors,
          ...customerResult.errors,
          ...poResult.errors,
          ...polResult.errors,
          ...grResult.errors,
          ...griResult.errors,
          ...recipeResult.errors,
        ];
        if (containsTenantRejection(pushErrors)) {
          onTenantRejected?.call(effectiveBusinessId);
        }
      }

      SyncResult pullResult = SyncResult(
        success: true,
        message: 'Pull skipped (no businessId)',
      );
      if (effectiveBusinessId != null) {
        pullResult = await pullFromServer(effectiveBusinessId);
      }

      // Post-cycle hook (fraud sweep): after the pull, so rules see the
      // freshest mirror. Never allowed to affect the sync result.
      try {
        onSyncCompleted?.call();
      } catch (e, st) {
        debugPrint('[SYNC] onSyncCompleted hook failed: $e\n$st');
      }

      return SyncResult(
        success:
            branchResult.success &&
            businessResult.success &&
            categoryResult.success &&
            productResult.success &&
            variantResult.success &&
            barcodeResult.success &&
            orderResult.success &&
            refundResult.success &&
            expenseResult.success &&
            inventoryResult.success &&
            ledgerResult.success &&
            employeeResult.success &&
            supplierResult.success &&
            customerResult.success &&
            poResult.success &&
            polResult.success &&
            grResult.success &&
            griResult.success &&
            recipeResult.success &&
            pullResult.success,
        message:
            '${branchResult.message}; ${businessResult.message}; ${categoryResult.message}; ${productResult.message}; ${variantResult.message}; ${barcodeResult.message}; ${orderResult.message}; ${refundResult.message}; ${expenseResult.message}; ${inventoryResult.message}; ${ledgerResult.message}; ${employeeResult.message}; ${supplierResult.message}; ${customerResult.message}; ${poResult.message}; ${polResult.message}; ${grResult.message}; ${griResult.message}; ${recipeResult.message}; ${pullResult.message}',
        syncedCount: totalSynced + pullResult.syncedCount,
        failedCount: totalFailed + pullResult.failedCount,
        errors: [
          ...branchResult.errors,
          ...businessResult.errors,
          ...categoryResult.errors,
          ...productResult.errors,
          ...variantResult.errors,
          ...barcodeResult.errors,
          ...orderResult.errors,
          ...refundResult.errors,
          ...expenseResult.errors,
          ...inventoryResult.errors,
          ...ledgerResult.errors,
          ...employeeResult.errors,
          ...supplierResult.errors,
          ...customerResult.errors,
          ...poResult.errors,
          ...polResult.errors,
          ...grResult.errors,
          ...griResult.errors,
          ...recipeResult.errors,
          ...pullResult.errors,
        ],
      );
    } finally {
      _isSyncing = false;
      // If a sync call with a businessId arrived while we were running (e.g.
      // AuthBloc._backgroundSync during the startup init sync), schedule a
      // quick pull-only pass so that server data is never missed.
      final followUp = _resolveBusinessId(_pendingBusinessId);
      _pendingBusinessId = null;
      if (followUp != null) {
        _connectivityService.isConnected.then((online) {
          if (online) pullFromServer(followUp).ignore();
        });
      }
    }
  }

  Future<SyncResult> _syncBranches() async {
    final pending = await _branchesDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.failed:
            await _businessRemoteDs.createBranch(
              id: record.id,
              businessId: record.businessId,
              name: record.name,
              location: record.location,
            );
            await _branchesDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingUpdate:
            await _businessRemoteDs.updateBranch(
              id: record.id,
              name: record.name,
              location: record.location,
            );
            await _branchesDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            await _businessRemoteDs.deleteBranch(record.id);
            await _branchesDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e, st) {
        failed++;
        debugPrint('[SYNC] Branch ${record.name} FAILED: $e\n$st');
        errors.add('Branch ${record.name}: ${e.toString()}');
        await _branchesDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Branches: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  // i sync na yung categories

  Future<SyncResult> _syncCategories() async {
    final pending = await _categoriesDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.failed:
            await _businessRemoteDs.createCategory(
              id: record.id,
              businessId: record.businessId,
              name: record.name,
            );
            await _categoriesDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingUpdate:
            await _businessRemoteDs.updateCategory(
              id: record.id,
              name: record.name,
            );
            await _categoriesDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            await _businessRemoteDs.deleteCategory(record.id);
            await _categoriesDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e, st) {
        failed++;
        debugPrint('[SYNC] Category ${record.name} FAILED: $e\n$st');
        errors.add('Category ${record.name}: ${e.toString()}');
        await _categoriesDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Categories: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  // Best-effort: persist a discarded local change after an LWW supersede. Must
  // never throw into the sync loop — conflict logging can't be allowed to fail
  // a sync. CLAUDE.md: never silently discard.
  Future<void> _logSupersededConflict(
    String table,
    String recordId,
    String businessId,
    Map<String, dynamic> localData,
  ) async {
    try {
      await _productsRemoteDs.logSyncConflict(
        businessId: businessId,
        tableName: table,
        recordId: recordId,
        localData: localData,
      );
    } catch (e, st) {
      debugPrint('[SYNC] conflict log failed for $table $recordId: $e\n$st');
    }
  }

  // i sync namn yung mga products

  Future<SyncResult> _syncProducts() async {
    final pending = await _productsDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        // Upload any locally-stored image before syncing to Supabase.
        // Local paths don't start with https:// — they're absolute device paths.
        String? resolvedImagePath = record.imagePath;
        if (resolvedImagePath != null &&
            !resolvedImagePath.startsWith('https://') &&
            File(resolvedImagePath).existsSync()) {
          resolvedImagePath = await _imageService.uploadLocalImageToStorage(
            localPath: resolvedImagePath,
            businessId: record.businessId,
          );
          await _productsDao.updateProduct(
            record.id,
            ProductsTableCompanion(imagePath: Value(resolvedImagePath)),
          );
        }

        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.failed:
            await _productsRemoteDs.createProduct(
              id: record.id,
              businessId: record.businessId,
              categoryId: record.categoryId,
              name: record.name,
              sku: record.sku,
              barcode: record.barcode,
              tax: record.tax,
              sellBy: record.sellBy,
              hasVariants: record.hasVariants,
              isActive: record.isActive,
              imagePath: resolvedImagePath,
              type: record.type,
              trackingMethod: record.trackingMethod,
              clientUpdatedAt: record.localUpdatedAt,
            );
            await _productsDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingUpdate:
            final updatedRows = await _productsRemoteDs.updateProduct(
              id: record.id,
              categoryId: record.categoryId,
              name: record.name,
              sku: record.sku,
              barcode: record.barcode,
              tax: record.tax,
              sellBy: record.sellBy,
              hasVariants: record.hasVariants,
              isActive: record.isActive,
              imagePath: resolvedImagePath,
              type: record.type,
              trackingMethod: record.trackingMethod,
              clientUpdatedAt: record.localUpdatedAt,
            );
            if (updatedRows.isEmpty) {
              // Rejected as stale — a newer edit from another device already
              // landed. Don't retry; the next pull fetches the winning row.
              debugPrint(
                '[SYNC] Product ${record.id} push superseded by a newer '
                'edit elsewhere — discarding local change',
              );
              await _logSupersededConflict(
                'products',
                record.id,
                record.businessId,
                record.toJson(),
              );
            }
            await _productsDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            // Soft-delete (stamp deleted_at) instead of hard delete so the
            // removal propagates to other devices via the delta-pull.
            await _productsRemoteDs.softDeleteProduct(record.id);
            await _productsDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e, st) {
        failed++;
        debugPrint('[SYNC] Product ${record.name} FAILED: $e\n$st');
        errors.add('Product ${record.name}: ${e.toString()}');
        await _productsDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Products: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  // sycn naman mga products variants

  Future<SyncResult> _syncProductVariants() async {
    final pending = await _productVariantsDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.failed:
            await _productsRemoteDs.createProductVariant(
              id: record.id,
              productId: record.productId,
              businessId: record.businessId,
              name: record.name,
              price: record.price,
              costPrice: record.costPrice,
              retailPrice: record.retailPrice,
              stock: record.stock,
              sku: record.sku,
              barcode: record.barcode,
              unit: record.unit,
              trackExpiry: record.trackExpiry,
              expiryDate: record.expiryDate?.millisecondsSinceEpoch,
              isActive: record.isActive,
              clientUpdatedAt: record.localUpdatedAt,
            );
            await _productVariantsDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingUpdate:
            final updatedRows = await _productsRemoteDs.updateProductVariant(
              id: record.id,
              name: record.name,
              price: record.price,
              costPrice: record.costPrice,
              retailPrice: record.retailPrice,
              stock: record.stock,
              sku: record.sku,
              barcode: record.barcode,
              unit: record.unit,
              trackExpiry: record.trackExpiry,
              expiryDate: record.expiryDate?.millisecondsSinceEpoch,
              isActive: record.isActive,
              clientUpdatedAt: record.localUpdatedAt,
            );
            if (updatedRows.isEmpty) {
              debugPrint(
                '[SYNC] Variant ${record.id} push superseded by a newer '
                'edit elsewhere — discarding local change',
              );
              await _logSupersededConflict(
                'product_variants',
                record.id,
                record.businessId,
                record.toJson(),
              );
            }
            await _productVariantsDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            // Soft-delete (stamp deleted_at) so the removal propagates to other
            // devices via the delta-pull; FK constraints from history stay
            // satisfied because the row is never hard-deleted on the server.
            await _productsRemoteDs.softDeleteProductVariant(record.id);
            await _productVariantsDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e, st) {
        // FK violation: parent product is locally synced but missing from
        // Supabase (e.g. remote DB was reset). Re-queue it so the next cycle
        // uploads it before retrying this variant.
        // Re-queue the parent product ONLY if it still exists locally; if it's
        // gone too, re-queuing a non-existent parent would loop forever, so let
        // the variant fail and be surfaced instead.
        if (e is PostgrestException &&
            e.code == '23503' &&
            (status == SyncStatus.pendingUpload ||
                status == SyncStatus.failed) &&
            await _productsDao.getById(record.productId) != null) {
          await _productsDao.updateSyncStatus(
            id: record.productId,
            status: SyncStatus.pendingUpload,
          );
          debugPrint(
            '[SYNC] Variant ${record.id}: product missing on server, re-queuing product for upload',
          );
          continue;
        }
        failed++;
        debugPrint('[SYNC] Variant ${record.name} FAILED: $e\n$st');
        errors.add('Variant ${record.name}: ${e.toString()}');
        await _productVariantsDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Variants: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  // sync product barcodes — normalized 1-to-many, pushed AFTER variants (FK).

  Future<SyncResult> _syncProductBarcodes() async {
    final pending = await _productBarcodesDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.pendingUpdate:
          case SyncStatus.failed:
            await _productsRemoteDs.upsertProductBarcode(
              id: record.id,
              businessId: record.businessId,
              variantId: record.variantId,
              code: record.code,
              isPrimary: record.isPrimary,
            );
            await _productBarcodesDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            await _productsRemoteDs.softDeleteProductBarcode(record.id);
            await _productBarcodesDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e, st) {
        // FK violation: parent variant is locally synced but missing from
        // Supabase (e.g. remote reset). Re-queue the variant so the next cycle
        // uploads it before retrying this barcode — mirrors _syncProductVariants.
        if (e is PostgrestException &&
            e.code == '23503' &&
            (status == SyncStatus.pendingUpload ||
                status == SyncStatus.pendingUpdate ||
                status == SyncStatus.failed) &&
            await _productVariantsDao.getById(record.variantId) != null) {
          await _productVariantsDao.updateSyncStatus(
            id: record.variantId,
            status: SyncStatus.pendingUpload,
          );
          debugPrint(
            '[SYNC] Barcode ${record.code}: variant missing on server, '
            're-queuing variant for upload',
          );
          continue;
        }
        // 23505: an offline-created code collided with the (business_id, code)
        // unique index. Surface just this barcode as failed — never block the
        // rest of the product's sync.
        failed++;
        debugPrint('[SYNC] Barcode ${record.code} FAILED: $e\n$st');
        errors.add('Barcode ${record.code}: ${e.toString()}');
        await _productBarcodesDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Barcodes: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  // sync completed POS transactions — upload only (transactions are immutable)

  Future<SyncResult> _syncTransactions() async {
    final pending = await _transactionsDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final tx in pending) {
      // Backoff: skip failed rows whose retry window hasn't elapsed yet so a
      // permanently-failing sale doesn't hammer the server every 60s.
      if (_shouldSkipForBackoff(tx.syncStatus, tx.lastSyncAttempt)) {
        continue;
      }

      // Status-only push: a refund flips this flag without touching the rest
      // of the (otherwise immutable) sale, so it skips the full create+items
      // upload below entirely.
      if (tx.syncStatus == SyncStatus.pendingUpdate.toInt()) {
        try {
          await _transactionsRemoteDs.updateTransactionStatus(tx.id, tx.status);
          await _transactionsDao.updateSyncStatus(
            id: tx.id,
            status: SyncStatus.synced,
          );
          synced++;
        } catch (e, st) {
          failed++;
          debugPrint(
            '[SYNC] Transaction ${tx.id} status update FAILED: $e\n$st',
          );
          errors.add('Transaction ${tx.id} status: ${e.toString()}');
          await _transactionsDao.updateSyncStatus(
            id: tx.id,
            status: SyncStatus.failed,
            error: e.toString(),
          );
        }
        continue;
      }

      var invoiceNumber = tx.invoiceNumber;
      try {
        await _transactionsRemoteDs.createTransaction(
          id: tx.id,
          cashierId: tx.cashierId,
          businessId: tx.businessId,
          branchId: tx.branchId,
          totalAmount: tx.totalAmount,
          discountAmount: tx.discountAmount,
          taxAmount: tx.taxAmount,
          createdAt: tx.createdAt,
          paymentMethod: tx.paymentMethod,
          invoiceNumber: invoiceNumber,
        );
        final items = await _transactionsDao.getItemsByTransactionId(tx.id);
        if (items.isNotEmpty) {
          await _transactionsRemoteDs.upsertTransactionItems(
            items
                .map(
                  (i) => {
                    'id': i.id,
                    'transaction_id': i.transactionId,
                    // Tenant scope + sale time mirrored from the parent so the
                    // server columns are populated without a join.
                    'business_id': tx.businessId,
                    'created_at': tx.createdAt.toUtc().toIso8601String(),
                    'variant_id': i.variantId,
                    'product_name': i.productName,
                    'variant_name': i.variantName,
                    'unit_price': i.unitPrice,
                    'tax_rate': i.taxRate,
                    'qty': i.qty,
                    'line_total': i.lineTotal,
                    'line_tax': i.lineTax,
                  },
                )
                .toList(),
          );
        }
        await _transactionsDao.updateSyncStatus(
          id: tx.id,
          status: SyncStatus.synced,
        );
        synced++;
      } catch (e, st) {
        // Duplicate invoice number: an offline-claimed number collided with the
        // per-business (business_id, invoice_number) unique index. Re-claim a
        // fresh server number, persist it, and retry the upload this same cycle.
        if (e is PostgrestException &&
            e.code == '23505' &&
            tx.businessId != null) {
          try {
            invoiceNumber = await _invoiceService.reclaim(tx.businessId!);
            await _transactionsDao.updateInvoiceNumber(tx.id, invoiceNumber);
            await _transactionsRemoteDs.createTransaction(
              id: tx.id,
              cashierId: tx.cashierId,
              businessId: tx.businessId,
              branchId: tx.branchId,
              totalAmount: tx.totalAmount,
              discountAmount: tx.discountAmount,
              taxAmount: tx.taxAmount,
              createdAt: tx.createdAt,
              paymentMethod: tx.paymentMethod,
              invoiceNumber: invoiceNumber,
            );
            final items = await _transactionsDao.getItemsByTransactionId(tx.id);
            if (items.isNotEmpty) {
              await _transactionsRemoteDs.upsertTransactionItems(
                items
                    .map(
                      (i) => {
                        'id': i.id,
                        'transaction_id': i.transactionId,
                        'variant_id': i.variantId,
                        'product_name': i.productName,
                        'variant_name': i.variantName,
                        'unit_price': i.unitPrice,
                        'tax_rate': i.taxRate,
                        'qty': i.qty,
                        'line_total': i.lineTotal,
                        'line_tax': i.lineTax,
                      },
                    )
                    .toList(),
              );
            }
            await _transactionsDao.updateSyncStatus(
              id: tx.id,
              status: SyncStatus.synced,
            );
            synced++;
            debugPrint(
              '[SYNC] Transaction ${tx.id}: duplicate invoice re-claimed as '
              '$invoiceNumber and re-uploaded',
            );
            continue;
          } catch (e2, st2) {
            // Re-claim/retry failed (e.g. went offline mid-recovery) — fall
            // through to mark failed so the next cycle tries again.
            debugPrint(
              '[SYNC] Transaction ${tx.id} duplicate-invoice recovery failed: '
              '$e2\n$st2',
            );
          }
        }
        // FK violation: a referenced variant is missing from Supabase.
        // Reset all variants in this transaction's items to pendingUpload
        // so the next cycle re-uploads them before retrying the transaction.
        if (e is PostgrestException && e.code == '23503') {
          final items = await _transactionsDao.getItemsByTransactionId(tx.id);
          var requeued = 0;
          for (final item in items) {
            // Only re-queue variants that still exist locally; re-queuing one
            // that's gone too would loop forever.
            if (await _productVariantsDao.getById(item.variantId) != null) {
              await _productVariantsDao.updateSyncStatus(
                id: item.variantId,
                status: SyncStatus.pendingUpload,
              );
              requeued++;
            }
          }
          if (requeued > 0) {
            debugPrint(
              '[SYNC] Transaction ${tx.id}: $requeued variant(s) missing on '
              'server, re-queuing for upload',
            );
            continue;
          }
          // Nothing re-queueable — fall through and surface the failure rather
          // than retrying a transaction whose variants are gone.
        }
        failed++;
        debugPrint('[SYNC] Transaction ${tx.id} FAILED: $e\n$st');
        errors.add('Transaction ${tx.id}: ${e.toString()}');
        await _transactionsDao.updateSyncStatus(
          id: tx.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Transactions: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  // Refunds are append-only (header + lines) — same upload-only shape as
  // transactions, pushed after them so the FK parent already exists.
  Future<SyncResult> _syncRefunds() async {
    final pending = await _refundsDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final refund in pending) {
      if (_shouldSkipForBackoff(refund.syncStatus, refund.lastSyncAttempt)) {
        continue;
      }
      try {
        await _refundsRemoteDs.upsertRefund({
          'id': refund.id,
          'transaction_id': refund.transactionId,
          'business_id': refund.businessId,
          'branch_id': refund.branchId,
          'refunded_by': refund.refundedBy,
          'total_amount': refund.totalAmount,
          'tax_amount': refund.taxAmount,
          'reason': refund.reason,
          'created_at': refund.createdAt.toUtc().toIso8601String(),
          'updated_at': refund.updatedAt.toUtc().toIso8601String(),
          'client_updated_at': refund.clientUpdatedAt.toUtc().toIso8601String(),
          'deleted_at': refund.deletedAt?.toUtc().toIso8601String(),
        });
        final items = await _refundsDao.getItemsByRefundId(refund.id);
        if (items.isNotEmpty) {
          await _refundsRemoteDs.upsertRefundItems(
            items
                .map(
                  (i) => {
                    'id': i.id,
                    'refund_id': i.refundId,
                    'business_id': refund.businessId,
                    'created_at': refund.createdAt.toUtc().toIso8601String(),
                    'transaction_item_id': i.transactionItemId,
                    'variant_id': i.variantId,
                    'qty': i.qty,
                    'amount': i.amount,
                    'restocked': i.restocked,
                  },
                )
                .toList(),
          );
        }
        await _refundsDao.updateSyncStatus(
          id: refund.id,
          status: SyncStatus.synced,
        );
        synced++;
      } catch (e, st) {
        failed++;
        debugPrint('[SYNC] Refund ${refund.id} FAILED: $e\n$st');
        errors.add('Refund ${refund.id}: ${e.toString()}');
        await _refundsDao.updateSyncStatus(
          id: refund.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Refunds: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  /// Recomputes a transaction's derived `status` from ALL refund rows now
  /// present locally (after a pull). Self-heals the status even if the
  /// status-only push above was lost, duplicated, or raced by another
  /// device — refund qty sums are the source of truth, status is derived.
  Future<void> _recomputeTransactionStatusFromRefunds(
    String transactionId,
  ) async {
    final items = await _transactionsDao.getItemsByTransactionId(transactionId);
    if (items.isEmpty) return;
    final refundedQty = await _refundsDao.getRefundedQtyByTransactionId(
      transactionId,
    );
    final allFullyRefunded = items.every(
      (i) => (refundedQty[i.id] ?? 0.0) >= i.qty - 1e-6,
    );
    final anyRefunded = refundedQty.values.any((q) => q > 0);
    final status = allFullyRefunded
        ? 'refunded'
        : (anyRefunded ? 'partially_refunded' : 'completed');
    await _transactionsDao.updateStatusFromServer(transactionId, status);
  }

  Future<SyncResult> _syncExpenses() async {
    final pending = await _expensesDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.failed:
            await _expensesRemoteDs.upsertExpense(
              id: record.id,
              businessId: record.businessId,
              branchId: record.branchId,
              branchName: record.branchName,
              category: record.category,
              vendor: record.vendor,
              amount: record.amount,
              status: record.status,
              submittedById: record.submittedById,
              submittedByName: record.submittedByName,
              approvedById: record.approvedById,
              approvedByName: record.approvedByName,
              note: record.note,
              expenseDate: record.expenseDate,
              createdAt: record.createdAt,
              updatedAt: record.updatedAt,
            );
            await _expensesDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingUpdate:
            await _expensesRemoteDs.updateExpenseStatus(
              id: record.id,
              status: record.status,
              approvedById: record.approvedById,
              approvedByName: record.approvedByName,
              updatedAt: record.updatedAt,
            );
            await _expensesDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            await _expensesRemoteDs.deleteExpense(record.id);
            await _expensesDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e, st) {
        failed++;
        debugPrint('[SYNC] Expense ${record.id} FAILED: $e\n$st');
        errors.add('Expense ${record.id}: ${e.toString()}');
        await _expensesDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Expenses: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  Future<SyncResult> _syncInventoryLevels() async {
    final pending = await _inventoryLevelsDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      try {
        await _productsRemoteDs.upsertInventoryLevel(
          id: record.id,
          variantId: record.variantId,
          branchId: record.branchId,
          businessId: record.businessId,
          quantity: record.quantity,
          lowStockAlertOverride: record.lowStockAlertOverride,
        );
        await _inventoryLevelsDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.synced,
        );
        synced++;
      } catch (e, st) {
        // FK violation: a parent row is locally synced but missing from Supabase
        // (e.g. remote DB was reset). Identify which FK failed via the error
        // details and re-queue only the missing parent so the next cycle
        // re-uploads it before retrying this inventory level.
        if (e is PostgrestException && e.code == '23503') {
          final info = '${e.details} ${e.message}'.toLowerCase();
          // Self-heal ONLY when the missing parent still exists locally — then
          // re-queuing it makes the next cycle upload it first. If the parent
          // is gone locally too the row is orphaned; re-queuing a non-existent
          // parent loops forever, so fail it loudly instead of pretending.
          if (info.contains('product_variant') &&
              await _productVariantsDao.getById(record.variantId) != null) {
            await _productVariantsDao.updateSyncStatus(
              id: record.variantId,
              status: SyncStatus.pendingUpload,
            );
            debugPrint(
              '[SYNC] InventoryLevel ${record.id}: variant missing on server, re-queuing variant for upload',
            );
            continue;
          } else if (info.contains('branch') &&
              await _branchesDao.getById(record.branchId) != null) {
            await _branchesDao.updateSyncStatus(
              id: record.branchId,
              status: SyncStatus.pendingUpload,
            );
            debugPrint(
              '[SYNC] InventoryLevel ${record.id}: branch missing on server, re-queuing branch for upload',
            );
            continue;
          } else if (info.contains('business') &&
              await _businessesDao.getById(record.businessId) != null) {
            await _businessesDao.updateSyncStatus(
              id: record.businessId,
              status: SyncStatus.pendingUpload,
            );
            debugPrint(
              '[SYNC] InventoryLevel ${record.id}: business missing on server, re-queuing business for upload',
            );
            continue;
          }
          // Orphaned (parent absent locally) or an unrecognised FK — surface it
          // as a real failure rather than re-queuing a parent that will never
          // upload.
          failed++;
          debugPrint(
            '[SYNC] InventoryLevel ${record.id}: unresolved FK violation, '
            'likely orphaned parent — details: ${e.details}\n$st',
          );
          errors.add('InventoryLevel ${record.id}: unresolved FK (${e.code})');
          await _inventoryLevelsDao.updateSyncStatus(
            id: record.id,
            status: SyncStatus.failed,
          );
          continue;
        }
        failed++;
        debugPrint('[SYNC] InventoryLevel ${record.id} FAILED: $e\n$st');
        errors.add('InventoryLevel ${record.id}: ${e.toString()}');
        await _inventoryLevelsDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'InventoryLevels: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  Future<SyncResult> _syncStockLedger() async {
    final pending = await _stockLedgerDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      try {
        await _productsRemoteDs.insertStockLedgerEntry(
          id: record.id,
          variantId: record.variantId,
          productId: record.productId,
          branchId: record.branchId,
          businessId: record.businessId,
          changeType: record.changeType,
          quantity: record.quantity,
          quantityBefore: record.quantityBefore,
          quantityAfter: record.quantityAfter,
          reason: record.reason,
          note: record.note,
          createdAt: record.createdAt,
          sourceType: record.sourceType,
          sourceId: record.sourceId,
        );
        await _stockLedgerDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.synced,
        );
        synced++;
      } catch (e, st) {
        // Duplicate id: this exact row already reached the server (most
        // likely a crash-window retry — see stock_ledger_no_update RLS in
        // 20260627000015). Ledger ids are client-generated UUIDs, so a
        // collision can only mean self-conflict, never a different row —
        // safe to self-heal as synced instead of retrying forever into the
        // immutable-ledger UPDATE block (42501).
        if (e is PostgrestException && e.code == '23505') {
          debugPrint(
            '[SYNC] StockLedger ${record.id}: already exists on server '
            '(duplicate id) — marking synced',
          );
          await _stockLedgerDao.updateSyncStatus(
            id: record.id,
            status: SyncStatus.synced,
          );
          synced++;
          continue;
        }
        // FK violation: variant or product is locally synced but missing from
        // Supabase. Reset the parent(s) to pendingUpload for self-healing.
        if (e is PostgrestException && e.code == '23503') {
          await _productVariantsDao.updateSyncStatus(
            id: record.variantId,
            status: SyncStatus.pendingUpload,
          );
          await _productsDao.updateSyncStatus(
            id: record.productId,
            status: SyncStatus.pendingUpload,
          );
          debugPrint(
            '[SYNC] StockLedger ${record.id}: parent missing on server, re-queuing variant/product for upload',
          );
          continue;
        }
        failed++;
        debugPrint('[SYNC] StockLedger ${record.id} FAILED: $e\n$st');
        errors.add('StockLedger ${record.id}: ${e.toString()}');
        await _stockLedgerDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'StockLedger: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  // i sync na yung businesses, kahit isa lang dapat yun pero for consistency with other tables we still loop through pending records list

  Future<SyncResult> _syncBusinesses() async {
    final pendingRecords = await _businessesDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pendingRecords) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);

      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.failed:
            await _handlePendingUpload(record);
            synced++;

          case SyncStatus.pendingUpdate:
            await _handlePendingUpdate(record);
            synced++;

          case SyncStatus.pendingDelete:
            await _handlePendingDelete(record);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e, st) {
        failed++;
        debugPrint('[SYNC] Business ${record.name} FAILED: $e\n$st');
        errors.add('${record.name}: ${e.toString()}');
        await _businessesDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Businesses: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  /// A business created OFFLINE lands here on first sync. It must go through the
  /// same atomic onboarding RPC as an online signup — pushing the bare business
  /// row (what this used to do) produced a half-built tenant on the server: no
  /// roles, no receipt_settings, no owner user row, which is the exact shape of
  /// the orphans the 2026-07-26 duplicate-signup bug left behind.
  ///
  /// The RPC is idempotent per owner, so re-running this is safe.
  Future<void> _handlePendingUpload(BusinessesTableData record) async {
    final localBranches = await _branchesDao.getByBusinessId(record.id);
    final branch = localBranches.isNotEmpty ? localBranches.first : null;

    await _businessRemoteDs.createBusinessOnboarding(
      businessId: record.id,
      name: record.name,
      templateId: record.templateId,
      branchId: branch?.id ?? const Uuid().v4(),
      branchName: branch?.name ?? 'Main Branch',
    );

    await _businessesDao.updateSyncStatus(
      id: record.id,
      status: SyncStatus.synced,
    );
    if (branch != null) {
      await _branchesDao.updateSyncStatus(
        id: branch.id,
        status: SyncStatus.synced,
      );
    }
  }

  Future<void> _handlePendingUpdate(BusinessesTableData record) async {
    await _businessesDao.updateSyncStatus(
      id: record.id,
      status: SyncStatus.synced,
    );
  }

  Future<void> _handlePendingDelete(BusinessesTableData record) async {
    await _businessesDao.hardDelete(record.id);
  }

  // pull the data from sever kapag  bago ang device or may changes sa server that are not yet in local db, then update local db with server data. This ensures na kahit connectivity-triggered syncs on a new device still pull server data.
  Future<SyncResult> pullFromServer(String businessId) async {
    // Defensive tenant guard: never pull a business other than the active one.
    final active = _activeBusinessContext.businessId;
    if (active != null && active.trim().isNotEmpty && businessId != active) {
      debugPrint(
        '[SYNC] pullFromServer blocked: $businessId != active $active',
      );
      return SyncResult(
        success: false,
        message: 'Pull blocked: tenant mismatch',
      );
    }

    final online = await isOnline;
    if (!online) {
      return SyncResult(success: false, message: 'Pull skipped: offline');
    }

    int pulled = 0;
    int failed = 0;
    final errors = <String>[];

    try {
      final categories = await _businessRemoteDs.getCategoriesByBusiness(
        businessId,
      );
      for (final row in categories) {
        await _categoriesDao.upsertFromServer(row);
        pulled++;
      }
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull categories failed: $e\n$st');
      errors.add('Pull categories: ${e.toString()}');
    }

    try {
      pulled += await _pullIncremental(
        entity: 'products',
        businessId: businessId,
        timestampField: 'updated_at',
        fetchPage: (after, id, lim) => _productsRemoteDs.getProductsByBusiness(
          businessId,
          afterTs: after,
          afterId: id,
          limit: lim,
        ),
        applyRow: (row) => _productsDao.upsertFromServer(row),
      );
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull products failed: $e\n$st');
      errors.add('Pull products: ${e.toString()}');
    }

    try {
      pulled += await _pullIncremental(
        entity: 'product_variants',
        businessId: businessId,
        timestampField: 'updated_at',
        fetchPage: (after, id, lim) => _productsRemoteDs.getVariantsByBusiness(
          businessId,
          afterTs: after,
          afterId: id,
          limit: lim,
        ),
        applyRow: (row) => _productVariantsDao.upsertFromServer(row),
      );
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull variants failed: $e\n$st');
      errors.add('Pull variants: ${e.toString()}');
    }

    try {
      pulled += await _pullIncremental(
        entity: 'product_barcodes',
        businessId: businessId,
        timestampField: 'updated_at',
        fetchPage: (after, id, lim) => _productsRemoteDs.getBarcodesByBusiness(
          businessId,
          afterTs: after,
          afterId: id,
          limit: lim,
        ),
        applyRow: (row) => _productBarcodesDao.upsertFromServer(row),
      );
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull product barcodes failed: $e\n$st');
      errors.add('Pull product barcodes: ${e.toString()}');
    }

    try {
      pulled += await _pullIncremental(
        entity: 'inventory_levels',
        businessId: businessId,
        timestampField: 'updated_at',
        fetchPage: (after, id, lim) =>
            _productsRemoteDs.getInventoryLevelsByBusiness(
              businessId,
              afterTs: after,
              afterId: id,
              limit: lim,
            ),
        applyRow: (row) => _inventoryLevelsDao.upsertFromServer(row),
      );
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull inventory levels failed: $e\n$st');
      errors.add('Pull inventory levels: ${e.toString()}');
    }

    try {
      pulled += await _pullIncremental(
        entity: 'stock_ledger',
        businessId: businessId,
        timestampField: 'created_at',
        fetchPage: (after, id, lim) =>
            _productsRemoteDs.getStockLedgerByBusiness(
              businessId,
              afterTs: after,
              afterId: id,
              limit: lim,
            ),
        applyRow: (row) => _stockLedgerDao.upsertFromServer(row),
      );
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull stock ledger failed: $e\n$st');
      errors.add('Pull stock ledger: ${e.toString()}');
    }

    try {
      // Incremental by transactions.updated_at; each page's line items are
      // fetched by transaction_id (items are append-only, written with their
      // transaction) so no transaction_items schema change is needed.
      pulled += await _pullIncremental(
        entity: 'transactions',
        businessId: businessId,
        timestampField: 'updated_at',
        fetchPage: (after, id, lim) =>
            _transactionsRemoteDs.getTransactionsByBusiness(
              businessId,
              afterTs: after,
              afterId: id,
              limit: lim,
            ),
        applyRow: (row) => _transactionsDao.upsertFromServer(row),
        afterPage: (page) async {
          final ids = page.map((r) => r['id'] as String).toList();
          if (ids.isEmpty) return;
          final items = await _transactionsRemoteDs.getItemsByTransactionIds(
            ids,
          );
          for (final item in items) {
            await _transactionsDao.upsertItemFromServer(item);
          }
        },
      );
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull transactions failed: $e\n$st');
      errors.add('Pull transactions: ${e.toString()}');
    }

    try {
      // Incremental by refunds.created_at (append-only, like stock_ledger).
      // Each page's lines are fetched by refund_id and applied, then every
      // affected transaction's derived `status` is recomputed locally — a
      // self-heal so a lost/duplicated status push from another device
      // still converges on this one.
      pulled += await _pullIncremental(
        entity: 'refunds',
        businessId: businessId,
        timestampField: 'created_at',
        fetchPage: (after, id, lim) => _refundsRemoteDs.getRefundsByBusiness(
          businessId,
          afterTs: after,
          afterId: id,
          limit: lim,
        ),
        applyRow: (row) => _refundsDao.upsertFromServer(row),
        afterPage: (page) async {
          if (page.isEmpty) return;
          final refundIds = page.map((r) => r['id'] as String).toList();
          final items = await _refundsRemoteDs.getItemsByRefundIds(refundIds);
          for (final item in items) {
            await _refundsDao.upsertItemFromServer(item);
          }
          final transactionIds = page
              .map((r) => r['transaction_id'] as String)
              .toSet();
          for (final txId in transactionIds) {
            await _recomputeTransactionStatusFromRefunds(txId);
          }
        },
      );
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull refunds failed: $e\n$st');
      errors.add('Pull refunds: ${e.toString()}');
    }

    try {
      // Incremental by created_at (append-only, like stock_ledger/refunds).
      // RLS (audit_admin_only) restricts SELECT to owners/admins — a
      // cashier or branch manager pulling here just gets an empty page every
      // time, which is correct; no client-side permission gate needed.
      //
      // initialCursorTs caps a brand-new device's first pull to the local
      // retention window instead of full history — older entries stay
      // server-only and are fetched on demand (AuditLogRepository).
      final auditWindowStart = DateTime.now().subtract(
        const Duration(days: auditLogLocalWindowDays),
      );
      pulled += await _pullIncremental(
        entity: 'audit_logs',
        businessId: businessId,
        timestampField: 'created_at',
        fetchPage: (after, id, lim) => _auditLogRemoteDs.getAuditLogsByBusiness(
          businessId,
          afterTs: after,
          afterId: id,
          limit: lim,
        ),
        applyRow: (row) => _auditLogsDao.upsertFromServer(row),
        initialCursorTs: auditWindowStart,
      );
      // Keep the local mirror bounded to the same rolling window — safe,
      // since anything pruned is, by definition, already on the server.
      final prunedCount = await _auditLogsDao.pruneOlderThan(auditWindowStart);
      if (prunedCount > 0) {
        debugPrint(
          '[SYNC] Pruned $prunedCount audit log row(s) past the local window',
        );
      }
      // Seq-driven repair AFTER the keyset pull: rows another device pushed
      // late sit behind this device's watermark and would otherwise never
      // arrive — the mirror holes they leave are what the fraud rules were
      // false-positiving on (seqGap tamper flags, "refund with no audit
      // trail"). Runs after the prune so refilled rows aren't re-deleted.
      if (repairAuditMirror != null) {
        pulled += await repairAuditMirror!(businessId);
      }
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull audit logs failed: $e\n$st');
      errors.add('Pull audit logs: ${e.toString()}');
    }

    try {
      // Device directory (normalized labels) — small, so a full tenant pull
      // keeps the owner's verify UI able to name every device, not just the
      // ones whose audit rows it pulled. RLS keeps it owner/verify-gated.
      final devices = await _devicesRemoteDs.getByBusiness(businessId);
      for (final row in devices) {
        await _devicesDao.upsertFromServer(row);
        pulled++;
      }
    } catch (e, st) {
      debugPrint('[SYNC] Pull devices failed: $e\n$st');
    }

    try {
      // Repair rows pulled before the upsert fix that landed with a null
      // business_id (and were therefore missing from reports). No-op once clean.
      final repaired = await _transactionsDao.backfillNullBusinessId(
        businessId,
      );
      if (repaired > 0) {
        debugPrint('[SYNC] Backfilled business_id on $repaired transaction(s)');
      }
    } catch (e, st) {
      debugPrint('[SYNC] Backfill transaction business_id failed: $e\n$st');
    }

    try {
      // Delta + paged pull (was a full re-download every cycle).
      pulled += await _pullIncremental(
        entity: 'expenses',
        businessId: businessId,
        timestampField: 'updated_at',
        fetchPage: (after, id, lim) => _expensesRemoteDs.getExpensesByBusiness(
          businessId,
          afterTs: after,
          afterId: id,
          limit: lim,
        ),
        applyRow: (row) => _expensesDao.upsertFromServer(row),
      );
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull expenses failed: $e\n$st');
      errors.add('Pull expenses: ${e.toString()}');
    }

    try {
      final branches = await _businessRemoteDs.getActiveBranchesByBusiness(
        businessId,
      );
      for (final row in branches) {
        await _branchesDao.upsertFromServer(
          Branch(
            id: row['id'] as String,
            businessId: row['business_id'] as String,
            name: row['name'] as String,
            location: row['location'] as String?,
          ),
        );
        pulled++;
      }
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull branches failed: $e\n$st');
      errors.add('Pull branches: ${e.toString()}');
    }

    try {
      final businessData = await _businessRemoteDs.getBusinessById(businessId);
      if (businessData != null) {
        await _businessesDao.upsertFromServer(
          BusinessModel.fromJson(businessData),
        );
        pulled++;
      }
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull business failed: $e\n$st');
      errors.add('Pull business: ${e.toString()}');
    }

    try {
      await _receiptSettingsRepo.pullFromServer(businessId);
      pulled++;
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull receipt settings failed: $e\n$st');
      errors.add('Pull receipt settings: ${e.toString()}');
    }

    try {
      await _refundSettingsRepo.pullFromServer(businessId);
      pulled++;
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull refund settings failed: $e\n$st');
      errors.add('Pull refund settings: ${e.toString()}');
    }

    try {
      final employees = await _employeesRemoteDs.getEmployeesByBusiness(
        businessId,
      );
      for (final row in employees) {
        final rowId = row['id'] as String;
        // Do not overwrite records that have pending local changes.
        // They will be pushed by _syncEmployees() on the next sync cycle,
        // so the server will receive the correct data. Overwriting here would
        // silently discard offline edits made on this device.
        final existing = await _employeesDao.getById(rowId);
        if (existing != null &&
            _hasPendingEmployeeChanges(existing.syncStatus)) {
          continue;
        }
        // Extract denormalized branch from employee_branches join
        final branches = row['employee_branches'] as List?;
        final branchId = branches != null && branches.isNotEmpty
            ? branches.first['branch_id'] as String?
            : null;
        // Prefer the direct role_name column (set at creation time), then the
        // roles join (if a role_id UUID is assigned), then fall back to
        // whatever is already stored locally so offline-only labels survive sync.
        final directRoleName = row['role_name'] as String?;
        final joinedRoleName = row['roles'] != null
            ? (row['roles'] as Map<String, dynamic>)['name'] as String?
            : null;
        final roleName = directRoleName ?? joinedRoleName ?? existing?.roleName;

        await _employeesDao.upsertFromServer(
          EmployeesTableCompanion.insert(
            id: row['id'] as String,
            businessId: row['business_id'] as String,
            userId: Value(row['user_id'] as String?),
            authUserId: Value(row['auth_user_id'] as String?),
            fullName: Value(row['full_name'] as String?),
            email: Value(row['email'] as String?),
            roleId: Value(row['role_id'] as String?),
            roleName: Value(roleName),
            branchId: Value(branchId),
            isActive: Value((row['is_active'] as bool?) ?? true),
            createdAt: Value(
              row['created_at'] != null
                  ? DateTime.parse(row['created_at'] as String)
                  : null,
            ),
            syncStatus: const Value(3), // synced
          ),
        );
        pulled++;
      }
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull employees failed: $e\n$st');
      errors.add('Pull employees: ${e.toString()}');
    }

    try {
      // Delta + paged pull (was a full re-download every cycle). The fetch now
      // includes soft-deleted rows so tombstones propagate to this device.
      pulled += await _pullIncremental(
        entity: 'suppliers',
        businessId: businessId,
        timestampField: 'updated_at',
        fetchPage: (after, id, lim) =>
            _procurementRemoteDs.getSuppliersByBusiness(
              businessId,
              afterTs: after,
              afterId: id,
              limit: lim,
            ),
        applyRow: (row) => _suppliersDao.upsertFromServer(row),
      );
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull suppliers failed: $e\n$st');
      errors.add('Pull suppliers: ${e.toString()}');
    }

    try {
      // Delta + paged pull; fetch includes soft-deleted rows so tombstones
      // propagate to this device.
      pulled += await _pullIncremental(
        entity: 'customers',
        businessId: businessId,
        timestampField: 'updated_at',
        fetchPage: (after, id, lim) => _customerRemoteDs.getCustomersByBusiness(
          businessId,
          afterTs: after,
          afterId: id,
          limit: lim,
        ),
        applyRow: (row) => _customersDao.upsertFromServer(row),
      );
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull customers failed: $e\n$st');
      errors.add('Pull customers: ${e.toString()}');
    }

    try {
      // RLS returns rows only for fraud.view holders (branch-scoped);
      // everyone else just gets an empty page — not an error.
      final flags = await _fraudFlagsRemoteDs.getFlagsByBusiness(businessId);
      for (final row in flags) {
        if (await _fraudFlagsDao.upsertFromServer(row)) {
          pulled++;
        } else {
          // Local triage hasn't pushed yet — kept local instead of letting
          // the pull silently revert it. Converges on the next push.
          debugPrint(
            '[SYNC] Fraud flag ${row['id']} pull skipped: '
            'local triage still pending push',
          );
        }
      }
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull fraud flags failed: $e\n$st');
      errors.add('Pull fraud flags: ${e.toString()}');
    }

    try {
      pulled += await _pullIncremental(
        entity: 'purchase_orders',
        businessId: businessId,
        timestampField: 'updated_at',
        fetchPage: (after, id, lim) =>
            _procurementRemoteDs.getPurchaseOrdersByBusiness(
              businessId,
              afterTs: after,
              afterId: id,
              limit: lim,
            ),
        applyRow: (row) => _purchaseOrdersDao.upsertFromServer(row),
      );
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull purchase orders failed: $e\n$st');
      errors.add('Pull purchase orders: ${e.toString()}');
    }

    try {
      pulled += await _pullIncremental(
        entity: 'purchase_order_lines',
        businessId: businessId,
        timestampField: 'updated_at',
        fetchPage: (after, id, lim) =>
            _procurementRemoteDs.getPurchaseOrderLinesByBusiness(
              businessId,
              afterTs: after,
              afterId: id,
              limit: lim,
            ),
        applyRow: (row) => _purchaseOrderLinesDao.upsertFromServer(row),
      );
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull PO lines failed: $e\n$st');
      errors.add('Pull PO lines: ${e.toString()}');
    }

    try {
      pulled += await _pullIncremental(
        entity: 'goods_receipts',
        businessId: businessId,
        timestampField: 'updated_at',
        fetchPage: (after, id, lim) =>
            _procurementRemoteDs.getGoodsReceiptsByBusiness(
              businessId,
              afterTs: after,
              afterId: id,
              limit: lim,
            ),
        applyRow: (row) => _goodsReceiptsDao.upsertFromServer(row),
      );
      pulled += await _pullIncremental(
        entity: 'goods_receipt_items',
        businessId: businessId,
        timestampField: 'updated_at',
        fetchPage: (after, id, lim) =>
            _procurementRemoteDs.getGoodsReceiptItemsByBusiness(
              businessId,
              afterTs: after,
              afterId: id,
              limit: lim,
            ),
        applyRow: (row) => _goodsReceiptItemsDao.upsertFromServer(row),
      );
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull goods receipts failed: $e\n$st');
      errors.add('Pull goods receipts: ${e.toString()}');
    }

    try {
      pulled += await _pullIncremental(
        entity: 'recipe_lines',
        businessId: businessId,
        timestampField: 'updated_at',
        fetchPage: (after, id, lim) =>
            _productsRemoteDs.getRecipeLinesByBusiness(
              businessId,
              afterTs: after,
              afterId: id,
              limit: lim,
            ),
        applyRow: (row) => _recipeLinesDao.upsertFromServer(row),
      );
    } catch (e, st) {
      failed++;
      debugPrint('[SYNC] Pull recipe lines failed: $e\n$st');
      errors.add('Pull recipe lines: ${e.toString()}');
    }

    return SyncResult(
      success: failed == 0,
      message: 'Pull: $pulled records, $failed errors',
      syncedCount: pulled,
      failedCount: failed,
      errors: errors,
    );
  }

  static const _pullPageSize = 500;

  /// Generic incremental, paged pull driven by a (timestamp, id) keyset cursor
  /// stored per entity in [SyncStateDao].
  ///
  /// - [timestampField] is the server column to page by ('updated_at' for
  ///   mutable tables, 'created_at' for the append-only ledger).
  /// - [fetchPage] requests rows strictly after (afterTs, afterId), ordered by
  ///   (timestampField, id) ascending, limited to a page.
  /// - [applyRow] upserts one row locally (existing pending-change guards apply).
  ///
  /// The cursor is the (timestamp, id) of the LAST row in each page, so rows
  /// sharing a timestamp are never skipped at a boundary. The watermark advances
  /// only after a page is fully applied, so a crash resumes from the last good
  /// cursor (upserts are idempotent). First run (null cursor) pages the full
  /// set, unless [initialCursorTs] is given — then the first run starts from
  /// there instead, e.g. so a brand-new device's first audit_logs pull only
  /// brings down the local retention window instead of full history.
  Future<int> _pullIncremental({
    required String entity,
    required String businessId,
    required String timestampField,
    required Future<List<Map<String, dynamic>>> Function(
      DateTime? afterTs,
      String? afterId,
      int limit,
    )
    fetchPage,
    required Future<void> Function(Map<String, dynamic> row) applyRow,
    Future<void> Function(List<Map<String, dynamic>> page)? afterPage,
    DateTime? initialCursorTs,
  }) async {
    var cursor = await _syncStateDao.getWatermark(entity, businessId);
    if (cursor.ts == null && initialCursorTs != null) {
      cursor = (ts: initialCursorTs, id: null);
    }
    int pulled = 0;

    while (true) {
      final page = await fetchPage(cursor.ts, cursor.id, _pullPageSize);
      if (page.isEmpty) break;

      DateTime? lastTs;
      String? lastId;
      for (final row in page) {
        await applyRow(row);
        pulled++;
        final ts = DateTime.tryParse(row[timestampField] as String? ?? '');
        final id = row['id'] as String?;
        if (ts != null && id != null) {
          lastTs = ts;
          lastId = id;
        }
      }

      // Apply any dependent child rows for this page (e.g. transaction items)
      // BEFORE advancing the cursor, so a failure here is retried next sync.
      if (afterPage != null) await afterPage(page);

      // No parseable cursor in the page — stop rather than risk a loop.
      if (lastTs == null || lastId == null) break;
      cursor = (ts: lastTs, id: lastId);
      await _syncStateDao.setWatermark(entity, businessId, lastTs, lastId);

      if (page.length < _pullPageSize) break;
    }

    return pulled;
  }

  Future<void> _syncReceiptSettings() async {
    try {
      await _receiptSettingsRepo.syncPending();
    } catch (e, st) {
      debugPrint('[SYNC] Receipt settings push failed: $e\n$st');
    }
  }

  Future<({int syncedCount, int failedCount})> _syncAuditLogs() async {
    const pageSize = 500;
    int synced = 0;
    int failed = 0;
    // Once a row of a device chain fails to push, every higher-seq row of the
    // SAME chain is held back this cycle — pushing seq N+1 while N is missing
    // would open a server-side gap that other devices' verifiers read as a
    // seqGap. getPendingSync() is ordered (device_uid, seq) so this is a
    // simple contiguous skip. Persisted across pages within this cycle.
    final blockedDevices = <String>{};

    // Page until a long offline backlog drains: synced rows leave the pending
    // set, so each page returns the next batch. Stop when a page makes no
    // progress (only blocked/failed rows remain) to avoid re-fetching them.
    while (true) {
      final pending = await _auditLogsDao.getPendingSync(limit: pageSize);
      if (pending.isEmpty) break;

      var syncedThisPage = 0;
      var conflicted = false;
      for (final r in pending) {
        final deviceUid = r.deviceUid;
        if (deviceUid != null && blockedDevices.contains(deviceUid)) {
          continue;
        }
        final row = auditLogToRemoteRow(r);
        try {
          await _auditLogRemoteDs.upsertLogs([row]);
          await _auditLogsDao.updateSyncStatus(
            id: r.id,
            status: SyncStatus.synced,
          );
          synced++;
          syncedThisPage++;
        } on AuditChainConflictException catch (e, st) {
          // Same (business, device, seq) already on the server with different
          // content — the benign same-device restart (T13: wiped local DB +
          // surviving uid). NOT tampering: self-heal by re-chaining this
          // device's unsynced tail past the server head, then stop this cycle
          // (the re-chained rows push cleanly on the next one).
          debugPrint(
            '[SYNC] AuditLog ${r.id} chain conflict — reconciling device tail '
            '(business=${r.businessId} seq=${r.seq}): $e\n$st',
          );
          await _auditLogsDao.updateSyncStatus(
            id: r.id,
            status: SyncStatus.failed,
            error: e.toString(),
          );
          if (onChainConflict != null) {
            await onChainConflict!(r.businessId);
            conflicted = true;
            break;
          }
          failed++;
        } catch (e, st) {
          failed++;
          if (deviceUid != null) blockedDevices.add(deviceUid);
          debugPrint(
            '[SYNC] AuditLog ${r.id} FAILED '
            '(business=${r.businessId} action=${r.actionType}): $e\n$st',
          );
          await _auditLogsDao.updateSyncStatus(
            id: r.id,
            status: SyncStatus.failed,
            error: e.toString(),
          );
          // Not covered by syncAll()'s push-error scan (this method returns
          // void), so flag a stale tenant directly — same signal as every
          // other tenant-scoped table.
          if (e is PostgrestException && e.code == '42501') {
            onTenantRejected?.call(r.businessId);
          }
        }
      }

      // Reconcile handoff, no forward progress, or a partial final page: done.
      if (conflicted || syncedThisPage == 0 || pending.length < pageSize) {
        break;
      }
    }

    if (synced > 0 || failed > 0) {
      debugPrint('[SYNC] Audit logs: synced $synced, failed $failed');
    }
    return (syncedCount: synced, failedCount: failed);
  }

  Future<void> _syncDevices() async {
    final pending = await _devicesDao.getPendingSync();
    if (pending.isEmpty) return;
    for (final r in pending) {
      try {
        await _devicesRemoteDs.upsertDevice(r);
        await _devicesDao.updateSyncStatus(
          deviceUid: r.deviceUid,
          status: SyncStatus.synced,
        );
      } catch (e, st) {
        debugPrint('[SYNC] Device ${r.deviceUid} FAILED: $e\n$st');
        await _devicesDao.updateSyncStatus(
          deviceUid: r.deviceUid,
          status: SyncStatus.failed,
          error: e.toString(),
        );
        if (e is PostgrestException && e.code == '42501') {
          onTenantRejected?.call(r.businessId);
        }
      }
    }
  }

  Future<({int syncedCount, int failedCount})> _syncFraudFlags() async {
    final pending = await _fraudFlagsDao.getPendingSync();
    if (pending.isEmpty) return (syncedCount: 0, failedCount: 0);

    int synced = 0;
    int failed = 0;

    for (final r in pending) {
      try {
        if (r.syncStatus == SyncStatus.pendingUpdate.toInt()) {
          // Triage-only update — anything wider trips the server freeze
          // trigger by design.
          await _fraudFlagsRemoteDs.updateTriage(r);
        } else {
          try {
            await _fraudFlagsRemoteDs.insertFlag(fraudFlagToRemoteRow(r));
          } on FraudFlagIdExists {
            // This exact row already reached the server on an earlier
            // attempt. If the local copy carries triage the server doesn't
            // have, deliver it — swallowing here used to silently lose
            // resolutions applied before the first upload succeeded.
            if (r.status != 'new') {
              await _fraudFlagsRemoteDs.updateTriage(r);
            }
          }
        }
        await _fraudFlagsDao.updateSyncStatus(
          id: r.id,
          status: SyncStatus.synced,
        );
        synced++;
      } on FraudFlagDedupeConflict {
        // Another device already flagged this incident — benign race, not a
        // tamper signal. Supersede the local duplicate; the canonical row
        // lands on the next pull.
        await _fraudFlagsDao.markSuperseded(r.id);
      } catch (e, st) {
        failed++;
        debugPrint('[SYNC] FraudFlag ${r.id} FAILED (${r.ruleCode}): $e\n$st');
        await _fraudFlagsDao.updateSyncStatus(
          id: r.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
        if (e is PostgrestException && e.code == '42501') {
          onTenantRejected?.call(r.businessId);
        }
      }
    }

    if (synced > 0 || failed > 0) {
      debugPrint('[SYNC] Fraud flags: synced $synced, failed $failed');
    }
    return (syncedCount: synced, failedCount: failed);
  }

  Future<SyncResult> _syncEmployees() async {
    final pending = await _employeesDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.failed:
          case SyncStatus.pendingUpdate:
            await _employeesRemoteDs.upsertEmployee(
              id: record.id,
              businessId: record.businessId,
              userId: record.userId,
              authUserId: record.authUserId,
              fullName: record.fullName ?? '',
              email: record.email,
              roleId: record.roleId,
              roleName: record.roleName,
              isActive: record.isActive,
            );
            if (record.branchId != null) {
              await _employeesRemoteDs.assignBranch(
                employeeId: record.id,
                branchId: record.branchId!,
              );
            }
            await _employeesDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            await _employeesRemoteDs.deleteEmployee(record.id);
            await _employeesDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e, st) {
        failed++;
        debugPrint('[SYNC] Employee ${record.fullName} FAILED: $e\n$st');
        errors.add('Employee ${record.fullName}: ${e.toString()}');
        await _employeesDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Employees: synced $synced, failed $failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  /// Pull latest business data from server and update local DB.
  Future<void> pullBusinessFromServer(String ownerId) async {
    final online = await isOnline;
    if (!online) return;

    final serverData = await _businessRemoteDs.getBusinessByOwner(ownerId);
    if (serverData != null) {
      final business = BusinessModel.fromJson(serverData);
      await _businessesDao.upsertFromServer(business);
    }
  }

  Future<SyncResult> _syncSuppliers() async {
    final pending = await _suppliersDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.pendingUpdate:
          case SyncStatus.failed:
            await _procurementRemoteDs.upsertSupplier({
              'id': record.id,
              'business_id': record.businessId,
              'name': record.name,
              'contact_name': record.contactName,
              'phone': record.phone,
              'email': record.email,
              'address': record.address,
              'tax_id': record.taxId,
              'notes': record.notes,
              'is_active': record.isActive,
              'is_deleted': record.isDeleted,
              'deleted_at': record.deletedAt?.toUtc().toIso8601String(),
              'created_at': record.createdAt.toUtc().toIso8601String(),
              'updated_at': record.localUpdatedAt.toUtc().toIso8601String(),
            });
            await _suppliersDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            await _procurementRemoteDs.deleteSupplier(record.id);
            await _suppliersDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e, st) {
        failed++;
        debugPrint('[SYNC] Supplier ${record.name} FAILED: $e\n$st');
        errors.add('Supplier ${record.name}: ${e.toString()}');
        await _suppliersDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Suppliers: $synced synced, $failed failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  Future<SyncResult> _syncCustomers() async {
    final pending = await _customersDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.pendingUpdate:
          // A customer soft-delete rides an upsert (is_deleted flag) — there's
          // no server hard-delete for customers (no DELETE policy).
          case SyncStatus.pendingDelete:
          case SyncStatus.failed:
            await _customerRemoteDs.upsertCustomer({
              'id': record.id,
              'business_id': record.businessId,
              'name': record.name,
              'phone': record.phone,
              'email': record.email,
              'address': record.address,
              'notes': record.notes,
              'is_active': record.isActive,
              'is_deleted': record.isDeleted,
              'deleted_at': record.deletedAt?.toUtc().toIso8601String(),
              'created_at': record.createdAt.toUtc().toIso8601String(),
              'updated_at': record.localUpdatedAt.toUtc().toIso8601String(),
            });
            await _customersDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e, st) {
        failed++;
        debugPrint('[SYNC] Customer ${record.name} FAILED: $e\n$st');
        errors.add('Customer ${record.name}: ${e.toString()}');
        await _customersDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Customers: $synced synced, $failed failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  Future<SyncResult> _syncPurchaseOrders() async {
    final pending = await _purchaseOrdersDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.pendingUpdate:
          case SyncStatus.failed:
            await _procurementRemoteDs.upsertPurchaseOrder({
              'id': record.id,
              'business_id': record.businessId,
              'branch_id': record.branchId,
              'supplier_id': record.supplierId,
              'supplier_name': record.supplierName,
              'status': record.status,
              'po_number': record.poNumber,
              'notes': record.notes,
              'expected_delivery': record.expectedDelivery
                  ?.toUtc()
                  .toIso8601String(),
              'discount': record.discount,
              'shipping': record.shipping,
              'total_amount': record.totalAmount,
              'created_by_id': record.createdById,
              'created_by_name': record.createdByName,
              'submitted_at': record.submittedAt?.toUtc().toIso8601String(),
              'approved_at': record.approvedAt?.toUtc().toIso8601String(),
              'approved_by_id': record.approvedById,
              'approved_by_name': record.approvedByName,
              'is_deleted': record.isDeleted,
              'deleted_at': record.deletedAt?.toUtc().toIso8601String(),
              'created_at': record.createdAt.toUtc().toIso8601String(),
              'updated_at': record.localUpdatedAt.toUtc().toIso8601String(),
            });
            await _purchaseOrdersDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            await _procurementRemoteDs.deletePurchaseOrder(record.id);
            await _purchaseOrdersDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e, st) {
        failed++;
        debugPrint('[SYNC] PurchaseOrder ${record.poNumber} FAILED: $e\n$st');
        errors.add('PO ${record.poNumber}: ${e.toString()}');
        await _purchaseOrdersDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Purchase orders: $synced synced, $failed failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  Future<SyncResult> _syncPurchaseOrderLines() async {
    final pending = await _purchaseOrderLinesDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.pendingUpdate:
          case SyncStatus.failed:
            await _procurementRemoteDs.upsertPurchaseOrderLine({
              'id': record.id,
              'purchase_order_id': record.purchaseOrderId,
              'business_id': record.businessId,
              'product_id': record.productId,
              'variant_id': record.variantId,
              'product_name': record.productName,
              'variant_name': record.variantName,
              'sku': record.sku,
              'quantity_ordered': record.quantityOrdered,
              'quantity_received': record.quantityReceived,
              'unit_cost': record.unitCost,
              'is_deleted': record.isDeleted,
              'created_at': record.createdAt.toUtc().toIso8601String(),
              'updated_at': record.localUpdatedAt.toUtc().toIso8601String(),
            });
            await _purchaseOrderLinesDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            await _procurementRemoteDs.deletePurchaseOrderLine(record.id);
            await _purchaseOrderLinesDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e, st) {
        failed++;
        debugPrint('[SYNC] PurchaseOrderLine ${record.id} FAILED: $e\n$st');
        errors.add('PO line ${record.id}: ${e.toString()}');
        await _purchaseOrderLinesDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'PO lines: $synced synced, $failed failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  Future<SyncResult> _syncGoodsReceipts() async {
    final pending = await _goodsReceiptsDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.pendingUpdate:
          case SyncStatus.failed:
            await _procurementRemoteDs.upsertGoodsReceipt({
              'id': record.id,
              'business_id': record.businessId,
              'purchase_order_id': record.purchaseOrderId,
              'branch_id': record.branchId,
              'receipt_number': record.receiptNumber,
              'received_by_id': record.receivedById,
              'received_by_name': record.receivedByName,
              'notes': record.notes,
              'is_deleted': record.isDeleted,
              'received_at': record.receivedAt.toUtc().toIso8601String(),
              'created_at': record.createdAt.toUtc().toIso8601String(),
              'updated_at': record.localUpdatedAt.toUtc().toIso8601String(),
            });
            await _goodsReceiptsDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            await _goodsReceiptsDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e, st) {
        failed++;
        debugPrint('[SYNC] GoodsReceipt ${record.id} FAILED: $e\n$st');
        errors.add('Goods receipt ${record.id}: ${e.toString()}');
        await _goodsReceiptsDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Goods receipts: $synced synced, $failed failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  Future<SyncResult> _syncGoodsReceiptItems() async {
    final pending = await _goodsReceiptItemsDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.pendingUpdate:
          case SyncStatus.failed:
            await _procurementRemoteDs.upsertGoodsReceiptItem({
              'id': record.id,
              'business_id': record.businessId,
              'goods_receipt_id': record.goodsReceiptId,
              'purchase_order_line_id': record.purchaseOrderLineId,
              'variant_id': record.variantId,
              'product_id': record.productId,
              'product_name': record.productName,
              'quantity_received': record.quantityReceived,
              'unit_cost': record.unitCost,
              'created_at': record.createdAt.toUtc().toIso8601String(),
              'updated_at': record.localUpdatedAt.toUtc().toIso8601String(),
            });
            await _goodsReceiptItemsDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            await _goodsReceiptItemsDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e, st) {
        failed++;
        debugPrint('[SYNC] GoodsReceiptItem ${record.id} FAILED: $e\n$st');
        errors.add('Goods receipt item ${record.id}: ${e.toString()}');
        await _goodsReceiptItemsDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Goods receipt items: $synced synced, $failed failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  Future<SyncResult> _syncRecipeLines() async {
    final pending = await _recipeLinesDao.getPendingSync();
    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pending) {
      final status = SyncStatusExtension.fromInt(record.syncStatus);
      try {
        switch (status) {
          case SyncStatus.pendingUpload:
          case SyncStatus.pendingUpdate:
          case SyncStatus.failed:
            await _productsRemoteDs.upsertRecipeLine({
              'id': record.id,
              'business_id': record.businessId,
              'product_variant_id': record.productVariantId,
              'ingredient_variant_id': record.ingredientVariantId,
              'ingredient_name': record.ingredientName,
              'quantity': record.quantity,
              'unit': record.unit,
              'is_deleted': record.isDeleted,
              'created_at': record.createdAt.toUtc().toIso8601String(),
              'updated_at': record.localUpdatedAt.toUtc().toIso8601String(),
            });
            await _recipeLinesDao.updateSyncStatus(
              id: record.id,
              status: SyncStatus.synced,
            );
            synced++;

          case SyncStatus.pendingDelete:
            await _productsRemoteDs.deleteRecipeLine(record.id);
            await _recipeLinesDao.hardDelete(record.id);
            synced++;

          case SyncStatus.synced:
            break;
        }
      } catch (e, st) {
        failed++;
        debugPrint('[SYNC] RecipeLine ${record.id} FAILED: $e\n$st');
        errors.add('Recipe line ${record.id}: ${e.toString()}');
        await _recipeLinesDao.updateSyncStatus(
          id: record.id,
          status: SyncStatus.failed,
          error: e.toString(),
        );
      }
    }

    return SyncResult(
      success: failed == 0,
      message: 'Recipe lines: $synced synced, $failed failed',
      syncedCount: synced,
      failedCount: failed,
      errors: errors,
    );
  }

  // Backoff for failed transaction uploads. Without it the 60s retry timer
  // re-hits the server for a permanently-failing row every single cycle. We
  // only have a single lastSyncAttempt timestamp (no failure-count column to
  // add), so we throttle with a fixed cool-off window instead of a true
  // exponential curve. Only `failed` rows are affected.
  static const _failedRetryCooldown = Duration(minutes: 5);

  bool _shouldSkipForBackoff(int syncStatus, DateTime? lastAttempt) {
    if (syncStatus != SyncStatus.failed.toInt()) return false;
    if (lastAttempt == null) return false;
    return DateTime.now().difference(lastAttempt) < _failedRetryCooldown;
  }

  /// Returns true when [syncStatus] represents a locally pending change that
  /// must be uploaded before server data may overwrite it.
  bool _hasPendingEmployeeChanges(int syncStatus) {
    return syncStatus == SyncStatus.pendingUpload.toInt() ||
        syncStatus == SyncStatus.pendingUpdate.toInt() ||
        syncStatus == SyncStatus.pendingDelete.toInt();
  }
}

/// Pure tenant-resolution rule for syncs (extracted so it can be unit-tested
/// in isolation — it is the security-critical guard against cross-tenant pulls).
///
/// - Prefer an explicitly [provided] businessId, else fall back to the [active]
///   session's business.
/// - Blank/whitespace ids are treated as absent.
/// - When a business is active, NEVER resolve to a different one (a stale id
///   queued before an account switch is rejected → returns null).
/// - With no business available at all, returns null so the pull is skipped.
String? resolveSyncBusinessId({String? provided, String? active}) {
  String? norm(String? s) => (s != null && s.trim().isNotEmpty) ? s : null;
  final p = norm(provided);
  final a = norm(active);
  final candidate = p ?? a;
  if (candidate == null) return null;
  if (a != null && candidate != a) return null;
  return candidate;
}

/// True when [errors] contains a Postgres 42501 (RLS) rejection — the
/// signature of a stale active business_id (deleted/recreated server-side
/// while the device was offline) rather than a transient network error.
/// Matches against PostgrestException's toString() shape (`code: 42501`)
/// since the per-table sync loops only keep the stringified error. Pulled
/// out as a pure function so the detection rule behind the tenant
/// self-heal is regression-tested without spinning up SyncService's full
/// dependency graph.
bool containsTenantRejection(List<String> errors) =>
    errors.any((e) => e.contains('code: 42501'));

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.errors = const [],
  });
}
