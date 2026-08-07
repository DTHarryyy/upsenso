import 'package:flutter/foundation.dart';

import 'package:pos/core/device/device_registration_service.dart';
import 'package:pos/core/permissions/entitlement_enforcement_service.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/permissions/plan_display.dart';
import 'package:pos/features/notifications/data/plan_notice_ack.dart';
import 'package:pos/features/notifications/domain/entities/notification_item.dart';
import 'package:pos/features/notifications/domain/entities/plan_notice.dart';

/// Single source of truth for every locally-derived plan notification.
class PlanNoticeService {
  PlanNoticeService({
    required EntitlementService entitlement,
    required EntitlementEnforcementService enforcement,
    required DeviceRegistrationService deviceRegistration,
    required PlanNoticeAck acknowledgement,
  }) : _entitlement = entitlement,
       _enforcement = enforcement,
       _deviceRegistration = deviceRegistration,
       _ack = acknowledgement {
    _entitlement.entitlementRevision.addListener(_bump);
    _enforcement.lockRevision.addListener(_bump);
    _deviceRegistration.registrationRevision.addListener(_bump);
  }

  final EntitlementService _entitlement;
  final EntitlementEnforcementService _enforcement;
  final DeviceRegistrationService _deviceRegistration;
  final PlanNoticeAck _ack;
  final ValueNotifier<int> _revision = ValueNotifier<int>(0);
  final DateTime _createdAt = DateTime.now();

  ValueListenable<int> get revision => _revision;

  List<PlanNoticeKind> activeKinds(String businessId) {
    final kinds = <PlanNoticeKind>[
      ?subscriptionNoticeKindForStatus(
        _entitlement.effectiveStatus,
        _entitlement.daysRemaining,
      ),
      if (_enforcement.hasOverCapResources) PlanNoticeKind.resourceOverCap,
      if (_deviceRegistration.isCapReached) PlanNoticeKind.deviceCap,
    ];
    return kinds
        .where((kind) => !_ack.isAcknowledged(kind, businessId))
        .toList(growable: false);
  }

  List<NotificationItem> buildAll(String businessId) => activeKinds(
    businessId,
  ).map((kind) => _build(kind, businessId)).toList(growable: false);

  NotificationItem _build(PlanNoticeKind kind, String businessId) {
    return NotificationItem(
      id: kind.id,
      businessId: businessId,
      type: NotificationType.billing,
      severity: kind.severity,
      title: kind.title,
      body: _body(kind),
      isRead: false,
      referenceType: kPlanNoticeRefType,
      referenceId: kind.name,
      createdAt: _createdAt,
    );
  }

  String _body(PlanNoticeKind kind) {
    switch (kind) {
      case PlanNoticeKind.trialing ||
          PlanNoticeKind.pastDue ||
          PlanNoticeKind.unverified ||
          PlanNoticeKind.lapsed:
        return subscriptionNoticeBody(kind, _entitlement.daysRemaining);
      case PlanNoticeKind.resourceOverCap:
        final branches = _enforcement.lockedBranchIds.length;
        final seats = _enforcement.suspendedEmployeeIds.length;
        final parts = [
          if (branches > 0)
            '$branches ${branches == 1 ? 'branch is' : 'branches are'} read-only',
          if (seats > 0)
            '$seats ${seats == 1 ? 'employee needs' : 'employees need'} a seat',
        ];
        return '${parts.join(' and ')} on your '
            '${planLabelOf(_entitlement.planCode)} plan. Nothing was deleted.';
      case PlanNoticeKind.deviceCap:
        final cap = _deviceRegistration.deviceCap;
        final plan = planLabelOf(_entitlement.planCode);
        if (_deviceRegistration.isSecondDeviceMoment) {
          return 'Your $plan plan covers one device. Selling still works here, '
              'but this device cannot use cloud backup.';
        }
        if (cap == null) {
          return 'This device is not authorised for cloud backup on your '
              '$plan plan. Selling still works here.';
        }
        return 'All $cap ${cap == 1 ? 'device slot is' : 'device slots are'} '
            'in use on your $plan plan. Selling still works here.';
    }
  }

  Future<void> reArm(String businessId) async {
    final active = <PlanNoticeKind>{
      ?subscriptionNoticeKindForStatus(
        _entitlement.effectiveStatus,
        _entitlement.daysRemaining,
      ),
      if (_enforcement.hasOverCapResources) PlanNoticeKind.resourceOverCap,
      if (_deviceRegistration.isCapReached) PlanNoticeKind.deviceCap,
    };
    for (final kind in PlanNoticeKind.values) {
      if (active.contains(kind) || !_ack.isAcknowledged(kind, businessId)) {
        continue;
      }
      await _ack.reset(kind, businessId);
    }
  }

  Future<void> acknowledge(PlanNoticeKind kind, String businessId) async {
    await _ack.acknowledge(kind, businessId);
    _bump();
  }

  static bool isSyntheticId(String id) => id.startsWith(kPlanNoticeIdPrefix);

  void _bump() => _revision.value++;

  void dispose() {
    _entitlement.entitlementRevision.removeListener(_bump);
    _enforcement.lockRevision.removeListener(_bump);
    _deviceRegistration.registrationRevision.removeListener(_bump);
    _revision.dispose();
  }
}
