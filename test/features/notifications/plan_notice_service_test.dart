import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos/core/device/device_registration_service.dart';
import 'package:pos/core/permissions/entitlement_enforcement_service.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/features/notifications/data/plan_notice_ack.dart';
import 'package:pos/features/notifications/domain/entities/plan_notice.dart';
import 'package:pos/features/notifications/domain/plan_notice_service.dart';

class _MockEntitlement extends Mock implements EntitlementService {}

class _MockEnforcement extends Mock implements EntitlementEnforcementService {}

class _MockDeviceRegistration extends Mock
    implements DeviceRegistrationService {}

const _biz = 'biz-1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockEntitlement entitlement;
  late _MockEnforcement enforcement;
  late _MockDeviceRegistration device;
  late ValueNotifier<int> entitlementRevision;
  late ValueNotifier<int> lockRevision;
  late ValueNotifier<int> deviceRevision;

  setUp(() {
    entitlement = _MockEntitlement();
    enforcement = _MockEnforcement();
    device = _MockDeviceRegistration();
    entitlementRevision = ValueNotifier<int>(0);
    lockRevision = ValueNotifier<int>(0);
    deviceRevision = ValueNotifier<int>(0);

    when(() => entitlement.entitlementRevision).thenReturn(entitlementRevision);
    when(() => entitlement.effectiveStatus).thenReturn('active');
    when(() => entitlement.daysRemaining).thenReturn(null);
    when(() => entitlement.planCode).thenReturn('starter');
    when(() => enforcement.lockRevision).thenReturn(lockRevision);
    when(() => enforcement.hasOverCapResources).thenReturn(false);
    when(() => enforcement.lockedBranchIds).thenReturn(const {});
    when(() => enforcement.suspendedEmployeeIds).thenReturn(const {});
    when(() => device.registrationRevision).thenReturn(deviceRevision);
    when(() => device.isCapReached).thenReturn(false);
    when(() => device.isSecondDeviceMoment).thenReturn(false);
    when(() => device.deviceCap).thenReturn(1);
  });

  tearDown(() {
    entitlementRevision.dispose();
    lockRevision.dispose();
    deviceRevision.dispose();
  });

  Future<PlanNoticeService> build({
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final store = await SharedPreferences.getInstance();
    return PlanNoticeService(
      entitlement: entitlement,
      enforcement: enforcement,
      deviceRegistration: device,
      acknowledgement: PlanNoticeAck(store),
    );
  }

  test('healthy account has no synthetic plan notices', () async {
    final service = await build();
    expect(service.buildAll(_biz), isEmpty);
    service.dispose();
  });

  test('trial appears only during its last seven days', () async {
    when(() => entitlement.effectiveStatus).thenReturn('trialing');
    when(() => entitlement.daysRemaining).thenReturn(8);
    final service = await build();
    expect(service.buildAll(_biz), isEmpty);

    when(() => entitlement.daysRemaining).thenReturn(7);
    expect(service.activeKinds(_biz), [PlanNoticeKind.trialing]);
    service.dispose();
  });

  test('subscription, over-cap, and device notices can coexist', () async {
    when(() => entitlement.effectiveStatus).thenReturn('lapsed');
    when(() => enforcement.hasOverCapResources).thenReturn(true);
    when(() => enforcement.lockedBranchIds).thenReturn({'branch-1'});
    when(
      () => enforcement.suspendedEmployeeIds,
    ).thenReturn({'employee-1', 'employee-2'});
    when(() => device.isCapReached).thenReturn(true);
    when(() => device.isSecondDeviceMoment).thenReturn(true);
    final service = await build();

    final items = service.buildAll(_biz);
    expect(items.map(planNoticeKindOf), [
      PlanNoticeKind.lapsed,
      PlanNoticeKind.resourceOverCap,
      PlanNoticeKind.deviceCap,
    ]);
    expect(items[1].body, contains('1 branch is read-only'));
    expect(items[1].body, contains('2 employees need a seat'));
    expect(items[2].body, contains('covers one device'));
    service.dispose();
  });

  test(
    'acknowledgement hides one notice until it resolves and recurs',
    () async {
      when(() => enforcement.hasOverCapResources).thenReturn(true);
      when(() => enforcement.lockedBranchIds).thenReturn({'branch-1'});
      final service = await build();

      await service.acknowledge(PlanNoticeKind.resourceOverCap, _biz);
      expect(service.activeKinds(_biz), isEmpty);

      when(() => enforcement.hasOverCapResources).thenReturn(false);
      when(() => enforcement.lockedBranchIds).thenReturn(const {});
      await service.reArm(_biz);
      when(() => enforcement.hasOverCapResources).thenReturn(true);
      when(() => enforcement.lockedBranchIds).thenReturn({'branch-1'});
      expect(service.activeKinds(_biz), [PlanNoticeKind.resourceOverCap]);
      service.dispose();
    },
  );

  test('legacy cloud-paused acknowledgement remains respected', () async {
    when(() => entitlement.effectiveStatus).thenReturn('lapsed');
    final service = await build(prefs: {'cloud_paused_ack:$_biz': true});
    expect(service.activeKinds(_biz), isEmpty);
    service.dispose();
  });

  test(
    'synthetic items are stable and distinguishable from real rows',
    () async {
      when(() => entitlement.effectiveStatus).thenReturn('past_due');
      when(() => entitlement.daysRemaining).thenReturn(1);
      final service = await build();

      expect(service.buildAll(_biz), equals(service.buildAll(_biz)));
      expect(
        PlanNoticeService.isSyntheticId(service.buildAll(_biz).single.id),
        isTrue,
      );
      expect(
        PlanNoticeService.isSyntheticId('3f2b1c9e-0000-4a11-9c3d-abcdef123456'),
        isFalse,
      );
      service.dispose();
    },
  );
}
