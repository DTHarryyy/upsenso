import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/audit_logs_dao.dart';
import 'package:pos/core/database/daos/auth_context_dao.dart';
import 'package:pos/core/database/daos/business_modules_dao.dart';
import 'package:pos/core/database/daos/employee_permissions_dao.dart';
import 'package:pos/core/permissions/data/permission_remote_ds.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/features/procurement/domain/entities/po_input.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order_line.dart';
import 'package:pos/features/procurement/domain/entities/supplier.dart';
import 'package:pos/features/procurement/domain/repositories/i_procurement_repository.dart';
import 'package:pos/features/procurement/presentation/cubit/po_cubit.dart';
import 'package:pos/features/procurement/presentation/cubit/po_state.dart';
import 'package:pos/features/procurement/presentation/cubit/supplier_cubit.dart';
import 'package:pos/features/procurement/presentation/cubit/supplier_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Regression: procurement mutations must be blocked at the cubit (business)
/// layer — not just by hidden UI — so a role lacking the permission cannot
/// create / approve / receive / cancel POs or manage suppliers even if it
/// reaches the cubit directly. Mirrors the server-side separation of duties.
void main() {
  late AppDatabase db;
  late PermissionService service;
  late _RecordingRepo repo;

  PermissionService buildService() => PermissionService(
    authContextDao: AuthContextDao(db),
    auditLogService: AuditLogService(
      dao: AuditLogsDao(db),
      authContextDao: AuthContextDao(db),
    ),
    permissionsDao: EmployeePermissionsDao(db),
    permissionRemoteDs: PermissionRemoteDs(
      SupabaseClient('https://example.supabase.co', 'test-anon-key'),
    ),
    businessModulesDao: BusinessModulesDao(db),
  );

  PoCubit poCubit() => PoCubit(
    repository: repo,
    permissions: service,
    businessId: 'b1',
    userId: 'u1',
    userName: 'Tester',
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = buildService();
    repo = _RecordingRepo();
  });

  tearDown(() async => db.close());

  group('PoCubit guards', () {
    test('inventory staff cannot create or approve POs', () async {
      service.setRole('inventory_staff');
      final cubit = poCubit();
      final emitted = <PoState>[];
      final sub = cubit.stream.listen(emitted.add);

      final id = await cubit.createPurchaseOrder(lines: const []);
      expect(id, isNull);
      expect(repo.createCalled, isFalse);
      // Let the broadcast stream deliver the queued emissions, then assert the
      // denial was surfaced (transiently) so the UI can show a message.
      await Future<void>.delayed(Duration.zero);
      expect(emitted.whereType<PoError>(), isNotEmpty);

      await cubit.approvePurchaseOrder('po1');
      expect(repo.approveCalled, isFalse);

      await sub.cancel();
      await cubit.close();
    });

    test('inventory staff cannot cancel a PO', () async {
      service.setRole('inventory_staff');
      final cubit = poCubit();

      await cubit.cancelPurchaseOrder('po1');
      expect(repo.cancelCalled, isFalse);

      await cubit.close();
    });

    test('inventory staff CAN receive goods (role default allows receive)',
        () async {
      service.setRole('inventory_staff');
      final cubit = poCubit();

      await cubit.receiveGoods(poId: 'po1', branchId: 'br1', lines: const []);
      expect(repo.receiveCalled, isTrue);

      await cubit.close();
    });

    test('branch manager can create and approve POs', () async {
      service.setRole('branch_manager');
      final cubit = poCubit();

      await cubit.createPurchaseOrder(lines: const []);
      expect(repo.createCalled, isTrue);

      await cubit.approvePurchaseOrder('po1');
      expect(repo.approveCalled, isTrue);

      await cubit.close();
    });
  });

  group('SupplierCubit guards', () {
    Future<SupplierCubit> loadedSupplierCubit() async {
      final cubit = SupplierCubit(
        repository: repo,
        permissions: service,
        businessId: 'b1',
      )..watch();
      // Let the (empty) supplier/order streams emit so state reaches Loaded.
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state, isA<SupplierLoaded>());
      return cubit;
    }

    test('cashier cannot create a supplier', () async {
      service.setRole('cashier');
      final cubit = await loadedSupplierCubit();
      final emitted = <SupplierState>[];
      final sub = cubit.stream.listen(emitted.add);

      await cubit.createSupplier(name: 'Acme');
      expect(repo.createSupplierCalled, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.whereType<SupplierError>(), isNotEmpty);

      await sub.cancel();
      await cubit.close();
    });

    // Inventory staff maintain the supplier directory via suppliers.manage
    // without full procurement rights — the Phase 6a key-mismatch fix.
    test('inventory staff can create a supplier', () async {
      service.setRole('inventory_staff');
      final cubit = await loadedSupplierCubit();

      final ok = await cubit.createSupplier(name: 'Acme');
      expect(ok, isTrue);
      expect(repo.createSupplierCalled, isTrue);

      await cubit.close();
    });

    test('duplicate supplier name is rejected (case-insensitive)', () async {
      service.setRole('branch_manager');
      repo.suppliers = [
        Supplier(
          id: 's1',
          businessId: 'b1',
          name: 'Acme Supplies',
          isActive: true,
          createdAt: DateTime(2026, 1, 1),
        ),
      ];
      final cubit = await loadedSupplierCubit();
      final emitted = <SupplierState>[];
      final sub = cubit.stream.listen(emitted.add);

      final ok = await cubit.createSupplier(name: '  acme supplies ');
      expect(ok, isFalse);
      expect(repo.createSupplierCalled, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.whereType<SupplierError>(), isNotEmpty);

      await sub.cancel();
      await cubit.close();
    });
  });
}

/// Minimal IProcurementRepository that records whether each mutation ran.
/// Read/stream methods return empty so cubits can reach their loaded state.
class _RecordingRepo implements IProcurementRepository {
  bool createCalled = false;
  bool approveCalled = false;
  bool receiveCalled = false;
  bool cancelCalled = false;
  bool createSupplierCalled = false;

  /// Seed the directory so the cubit's duplicate-name guard has something to
  /// clash against. Emitted by [watchSuppliers].
  List<Supplier> suppliers = const [];

  @override
  Stream<List<Supplier>> watchSuppliers(String businessId) =>
      Stream.value(suppliers);

  @override
  Future<List<Supplier>> getSuppliers(String businessId) async => suppliers;

  @override
  Future<Supplier?> getSupplierById(String id) async => null;

  @override
  Future<void> createSupplier({
    required String businessId,
    required String name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
    String? taxId,
    String? notes,
  }) async {
    createSupplierCalled = true;
  }

  @override
  Future<void> updateSupplier({
    required String id,
    required String name,
    String? contactName,
    String? phone,
    String? email,
    String? address,
    String? taxId,
    String? notes,
    bool? isActive,
  }) async {}

  @override
  Future<void> deleteSupplier(String id) async {}

  @override
  Stream<List<PurchaseOrder>> watchPurchaseOrders(String businessId) =>
      Stream.value(const []);

  @override
  Future<List<PurchaseOrder>> getPurchaseOrders(String businessId) async =>
      const [];

  @override
  Future<PurchaseOrder?> getPurchaseOrderById(String id) async => null;

  @override
  Stream<List<PurchaseOrderLine>> watchPurchaseOrderLines(String poId) =>
      Stream.value(const []);

  @override
  Future<List<PurchaseOrderLine>> getPurchaseOrderLines(String poId) async =>
      const [];

  @override
  Future<String> createPurchaseOrder({
    required String businessId,
    String? branchId,
    String? supplierId,
    String? supplierName,
    String? notes,
    DateTime? expectedDelivery,
    required String createdById,
    required String createdByName,
    required List<PoLineInput> lines,
  }) async {
    createCalled = true;
    return 'po-new';
  }

  @override
  Future<void> updatePurchaseOrder({
    required String id,
    String? notes,
    DateTime? expectedDelivery,
    String? supplierId,
    String? supplierName,
    List<PoLineInput>? lines,
  }) async {}

  @override
  Future<void> submitPurchaseOrder(String id) async {}

  @override
  Future<void> approvePurchaseOrder({
    required String id,
    required String approvedById,
    required String approvedByName,
  }) async {
    approveCalled = true;
  }

  @override
  Future<void> receiveGoods({
    required String poId,
    required String branchId,
    required List<ReceiveLineInput> lines,
  }) async {
    receiveCalled = true;
  }

  @override
  Future<void> cancelPurchaseOrder(String id) async {
    cancelCalled = true;
  }
}
