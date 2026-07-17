import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/audit/audit_log_service.dart';
import 'package:pos/core/database/app_database.dart';
import 'package:pos/core/database/daos/fraud_flags_dao.dart';
import 'package:pos/core/permissions/permission_keys.dart';
import 'package:pos/core/permissions/permission_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/sync/sync_status.dart';
import 'package:pos/features/alert/data/alert_model.dart';
import 'package:pos/features/alert/presentation/cubit/fraud_cubit.dart';
import 'package:pos/features/audit_logs/domain/audit_log_action_type.dart';

class MockPermissionService extends Mock implements PermissionService {}

class MockAuditLogService extends Mock implements AuditLogService {}

class MockFraudFlagsDao extends Mock implements FraudFlagsDao {}

void main() {
  late AppDatabase db;
  late FraudFlagsDao flagsDao;
  late MockPermissionService permissions;
  late MockAuditLogService auditLog;
  late ActiveBusinessContext context;

  setUpAll(() {
    registerFallbackValue(AuditLogActionType.fraudFlagResolved);
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    flagsDao = FraudFlagsDao(db);
    permissions = MockPermissionService();
    when(() => permissions.can(any())).thenReturn(true);
    auditLog = MockAuditLogService();
    when(
      () => auditLog.log(
        actionType: any(named: 'actionType'),
        entityType: any(named: 'entityType'),
        entityId: any(named: 'entityId'),
        entityName: any(named: 'entityName'),
        userName: any(named: 'userName'),
        description: any(named: 'description'),
        metadata: any(named: 'metadata'),
        businessId: any(named: 'businessId'),
        branchId: any(named: 'branchId'),
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async {});
    context = ActiveBusinessContext()
      ..set(
        userId: 'me1',
        businessId: 'biz1',
        branchId: 'br1',
        fullName: 'Me',
      );
  });

  tearDown(() async {
    await db.close();
  });

  FraudCubit buildCubit() {
    return FraudCubit(
      flagsDao: flagsDao,
      db: db,
      permissionService: permissions,
      activeBusinessContext: context,
      auditLogService: auditLog,
    );
  }

  Future<void> seedBusiness({String ownerId = 'owner1'}) {
    return db.customStatement(
      'INSERT INTO businesses (id, name, owner_id, template_id, created_at) '
      "VALUES ('biz1', 'Test', ?, 'tpl', 1700000000)",
      [ownerId],
    );
  }

  Future<void> seedFlag(String id, {String? branchId = 'br1'}) {
    return db.into(db.fraudFlagsTable).insert(
          FraudFlagsTableCompanion.insert(
            id: id,
            businessId: 'biz1',
            branchId: Value(branchId),
            ruleCode: 'HIGH_DISCOUNT',
            severity: 'high',
            title: 't',
            description: 'd',
            detectedAt: DateTime(2026, 7, 1),
            dedupeKey: 'HIGH_DISCOUNT|$id',
            syncStatus: Value(SyncStatus.synced.toInt()),
          ),
        );
  }

  FraudAlert alertOf({
    String id = 'f1',
    String? subjectUserId,
    String? branchId = 'br1',
  }) {
    return FraudAlert(
      id: id,
      ruleCode: 'HIGH_DISCOUNT',
      title: 'High discount',
      description: 'd',
      severity: AlertSeverity.high,
      status: AlertStatus.newAlert,
      author: '—',
      subjectUserId: subjectUserId,
      branchId: branchId,
      store: 'Branch',
      date: DateTime(2026, 7, 1),
      evidence: const {},
      relatedRecords: const [],
    );
  }

  Future<FraudFlagRow> flag(String id) =>
      (db.select(db.fraudFlagsTable)..where((t) => t.id.equals(id)))
          .getSingle();

  group('triage denial mirror', () {
    test('denies without fraud.resolve', () async {
      when(() => permissions.can(PermissionKeys.fraudResolve))
          .thenReturn(false);
      final cubit = buildCubit();

      expect(cubit.canResolveAlert(alertOf()), isFalse);
      expect(
        await cubit.setStatus(alertOf(), AlertStatus.resolved, null),
        isNotNull,
      );
      await cubit.close();
    });

    test('denies triaging an alert that implicates the caller', () async {
      await seedBusiness(); // owner is owner1, caller is me1
      await seedFlag('f1');
      final cubit = buildCubit();
      await cubit.load();

      final result = await cubit.setStatus(
        alertOf(subjectUserId: 'me1'),
        AlertStatus.dismissed,
        null,
      );

      expect(result, isNotNull);
      expect((await flag('f1')).status, 'new');
      await cubit.close();
    });

    test('the owner may triage an alert implicating themselves', () async {
      context.set(
        userId: 'owner1',
        businessId: 'biz1',
        branchId: 'br1',
        fullName: 'Owner',
      );
      await seedBusiness(ownerId: 'owner1');
      await seedFlag('f1');
      final cubit = buildCubit();
      await cubit.load();

      final result = await cubit.setStatus(
        alertOf(subjectUserId: 'owner1'),
        AlertStatus.resolved,
        'self-check',
      );

      expect(result, isNull);
      expect((await flag('f1')).status, 'resolved');
      await cubit.close();
    });

    test('denies business-wide alerts without cross-branch access', () async {
      when(() => permissions.can(PermissionKeys.dataCrossBranchAccess))
          .thenReturn(false);
      final cubit = buildCubit();

      final result = await cubit.setStatus(
        alertOf(branchId: null),
        AlertStatus.resolved,
        null,
      );

      expect(result, isNotNull);
      await cubit.close();
    });

    test("denies another branch's alert without cross-branch access",
        () async {
      when(() => permissions.can(PermissionKeys.dataCrossBranchAccess))
          .thenReturn(false);
      final cubit = buildCubit();

      final result = await cubit.setStatus(
        alertOf(branchId: 'br2'),
        AlertStatus.resolved,
        null,
      );

      expect(result, isNotNull);
      await cubit.close();
    });

    test('allows own-branch alerts without cross-branch access', () async {
      when(() => permissions.can(PermissionKeys.dataCrossBranchAccess))
          .thenReturn(false);
      await seedFlag('f1');
      final cubit = buildCubit();

      final result = await cubit.setStatus(
        alertOf(branchId: 'br1'),
        AlertStatus.investigating,
        null,
      );

      expect(result, isNull);
      expect((await flag('f1')).status, 'investigating');
      await cubit.close();
    });
  });

  group('setStatus', () {
    test('writes triage fields and logs the chained audit entry', () async {
      await seedFlag('f1');
      final cubit = buildCubit();

      final result = await cubit.setStatus(
        alertOf(subjectUserId: 'someone-else'),
        AlertStatus.resolved,
        'verified with cashier',
      );

      expect(result, isNull);
      final row = await flag('f1');
      expect(row.status, 'resolved');
      expect(row.resolvedBy, 'me1');
      expect(row.resolutionNote, 'verified with cashier');
      verify(
        () => auditLog.log(
          actionType: AuditLogActionType.fraudFlagResolved,
          entityType: 'fraud_flag',
          entityId: 'f1',
          entityName: any(named: 'entityName'),
          userName: any(named: 'userName'),
          description: any(named: 'description'),
          metadata: any(named: 'metadata'),
          businessId: any(named: 'businessId'),
          branchId: any(named: 'branchId'),
          userId: any(named: 'userId'),
        ),
      ).called(1);
      await cubit.close();
    });

    test('returns a user-facing message when the write fails', () async {
      // A throwing DAO must surface as a message — never a silent failure.
      final failingDao = MockFraudFlagsDao();
      when(
        () => failingDao.resolve(
          id: any(named: 'id'),
          status: any(named: 'status'),
          resolvedBy: any(named: 'resolvedBy'),
          resolutionNote: any(named: 'resolutionNote'),
        ),
      ).thenThrow(Exception('write failed'));
      final cubit = FraudCubit(
        flagsDao: failingDao,
        db: db,
        permissionService: permissions,
        activeBusinessContext: context,
        auditLogService: auditLog,
      );

      final result = await cubit.setStatus(
        alertOf(),
        AlertStatus.resolved,
        null,
      );

      expect(result, isNotNull);
      await cubit.close();
    });
  });
}
