import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/products_dao.dart';
import 'package:pos/core/database/daos/product_variants_dao.dart';
import 'package:pos/core/permissions/data/permission_remote_ds.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/features/procurement/domain/entities/procurement_settings.dart';
import 'package:pos/features/procurement/domain/entities/purchase_order.dart';
import 'package:pos/features/procurement/domain/entities/supplier.dart';
import 'package:pos/features/procurement/domain/repositories/i_procurement_repository.dart';
import 'package:pos/features/procurement/presentation/cubit/po_cubit.dart';
import 'package:pos/features/procurement/presentation/pages/po_form_page.dart';

/// Reproduction harness for the "blank Create-PO form" report. Renders the real
/// PoFormPage headless (no web engine) at a phone viewport and asserts the three
/// section cards paint. If this passes, the blank screen is web-engine-specific,
/// not a layout/widget bug in the page.
class _FakeProcurementRepo implements IProcurementRepository {
  @override
  Future<List<Supplier>> getSuppliers(String businessId) async => const [];

  @override
  Stream<List<PurchaseOrder>> watchPurchaseOrders(String businessId) =>
      Stream.value(const []);

  @override
  Future<ProcurementSettings> getSettings(String businessId) async =>
      ProcurementSettings(businessId: businessId);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

void main() {
  late AppDatabase db;
  late PoCubit cubit;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final permissions = PermissionService(
      authContextDao: db.authContextDao,
      activeBusinessContext: ActiveBusinessContext(),
      auditLogService: AuditLogService(
        dao: db.auditLogsDao,
        authContextDao: db.authContextDao,
        activeBusinessContext: ActiveBusinessContext(),
      ),
      permissionsDao: db.employeePermissionsDao,
      permissionRemoteDs: PermissionRemoteDs(
        SupabaseClient('http://localhost', 'test-anon-key'),
      ),
      businessModulesDao: db.businessModulesDao,
    );
    permissions.setRole('owner');

    final repo = _FakeProcurementRepo();

    if (sl.isRegistered<IProcurementRepository>()) {
      sl.unregister<IProcurementRepository>();
    }
    if (sl.isRegistered<ProductsDao>()) sl.unregister<ProductsDao>();
    if (sl.isRegistered<ProductVariantsDao>()) {
      sl.unregister<ProductVariantsDao>();
    }
    if (sl.isRegistered<PermissionService>()) {
      sl.unregister<PermissionService>();
    }
    sl.registerSingleton<IProcurementRepository>(repo);
    sl.registerSingleton<ProductsDao>(ProductsDao(db));
    sl.registerSingleton<ProductVariantsDao>(ProductVariantsDao(db));
    sl.registerSingleton<PermissionService>(permissions);

    cubit = PoCubit(
      repository: repo,
      permissions: permissions,
      businessId: 'biz-1',
      userId: 'user-1',
      userName: 'Tester',
    )..watch();
  });

  tearDown(() async {
    await cubit.close();
    await sl.reset();
    await db.close();
  });

  testWidgets('PoFormPage renders its section cards at a phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<PoCubit>.value(
          value: cubit,
          child: const PoFormPage(businessId: 'biz-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Regression guard for the blank-form bug: AppStickyActionBar used to expand
    // to full height and squeeze the body ListView to zero, so these cards never
    // rendered even though the page received a full-height viewport.
    expect(find.text('Supplier'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('No items yet'), findsOneWidget);
  });
}
