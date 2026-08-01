import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos/core/device/device_identity_service.dart';
import 'package:pos/core/device/device_info_service.dart';
import 'package:pos/core/device/device_registration_remote_ds.dart';
import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/session/active_business_context.dart';
import 'package:pos/core/sync/connectivity_service.dart';

enum DeviceRegistrationStatus { unknown, registered, capReached, notCloudTier }

/// Registers this install against the tenant's device cap when it's on a cloud
/// tier (M7.1 §4/§6.3). Registration is online-only (an RPC) — that's what
/// bounds a paid account to its device count. SyncService arms only when the
/// device is registered, so a revoked or over-cap device can't sync.
///
/// The last successful registration is cached per-business in SharedPreferences
/// so a device that registered while online stays "registered" across restarts
/// (sync needs the network anyway; the cache just avoids a redundant RPC and
/// lets the gate answer instantly at cold start).
class DeviceRegistrationService {
  final DeviceRegistrationRemoteDs _remoteDs;
  final DeviceIdentityService _identity;
  final DeviceInfoService _info;
  final ActiveBusinessContext _activeBusinessContext;
  final EntitlementService _entitlement;
  final ConnectivityService _connectivity;
  final SharedPreferences _prefs;

  static const _prefix = 'device_registered';

  DeviceRegistrationStatus _status = DeviceRegistrationStatus.unknown;
  final ValueNotifier<int> _registrationRevision = ValueNotifier<int>(0);

  DeviceRegistrationService({
    required DeviceRegistrationRemoteDs remoteDs,
    required DeviceIdentityService identityService,
    required DeviceInfoService infoService,
    required ActiveBusinessContext activeBusinessContext,
    required EntitlementService entitlementService,
    required ConnectivityService connectivityService,
    required SharedPreferences prefs,
  })  : _remoteDs = remoteDs,
        _identity = identityService,
        _info = infoService,
        _activeBusinessContext = activeBusinessContext,
        _entitlement = entitlementService,
        _connectivity = connectivityService,
        _prefs = prefs;

  DeviceRegistrationStatus get status => _status;

  /// This device is over the plan's device cap: it works normally, but nothing
  /// on it reaches the cloud until a slot is freed or the plan grows.
  bool get isCapReached => _status == DeviceRegistrationStatus.capReached;

  /// The cap that turned us away, for the banner's "3 of 3 in use" line.
  int? get deviceCap => _entitlement.effectiveMax(EntitlementResource.devices);

  /// A one-device plan hitting the cap *is* the "second device" moment (§4.3) —
  /// the merchant just tried to use their phone as well as their tablet. Any
  /// higher cap is a device-management problem, not an upsell.
  ///
  /// A Free tenant who is offline on both devices is undetectable by
  /// construction: nothing registers and nothing syncs, so there is no shared
  /// fact to compare against. This catches every case we can actually see.
  bool get isSecondDeviceMoment => isCapReached && deviceCap == 1;

  /// Bumps when registration status changes — SyncService listens so a
  /// successful registration (or a revoke) re-arms/pauses sync.
  ValueListenable<int> get registrationRevision => _registrationRevision;

  /// True when sync is allowed to touch the cloud on the device axis. Free/
  /// local tiers return true (device cap is meaningless without the cloud —
  /// the entitlement gate already blocks sync there). On a cloud tier it
  /// reflects the cached/last registration result.
  bool get isRegistered {
    if (!_entitlement.cloudEnabled) return true;
    final biz = _activeBusinessContext.businessId;
    if (biz == null || biz.isEmpty) return false;
    if (_status == DeviceRegistrationStatus.registered) return true;
    if (_status == DeviceRegistrationStatus.capReached) return false;
    // Cold start: trust the cached flag until the next ensureRegistered().
    return _prefs.getBool('$_prefix:$biz') ?? false;
  }

  /// Attempt registration if on a cloud tier and online. Safe to call often
  /// (bootstrap, entitlement-gained, app resume) — it no-ops when not needed.
  Future<DeviceRegistrationStatus> ensureRegistered() async {
    final biz = _activeBusinessContext.businessId;
    if (biz == null || biz.isEmpty) return DeviceRegistrationStatus.unknown;

    if (!_entitlement.cloudEnabled) {
      _set(DeviceRegistrationStatus.notCloudTier, biz);
      return _status;
    }
    if (!await _connectivity.isConnected) {
      // Offline: keep whatever the cached flag says; don't downgrade.
      return _status;
    }

    try {
      final uid = await _identity.getDeviceUid();
      final label = await _info.getDeviceLabel();
      final result = await _remoteDs.register(
        deviceUid: uid,
        label: label,
        platform: _info.platform,
      );
      final status = result == 'registered'
          ? DeviceRegistrationStatus.registered
          : DeviceRegistrationStatus.capReached;
      _set(status, biz);
      return status;
    } catch (e, st) {
      debugPrint('[DeviceRegistration] Error in ensureRegistered: $e\n$st');
      // Network/transient failure: leave the cached flag untouched.
      return _status;
    }
  }

  /// Bump this device's `last_seen_at`. Best-effort and silent — a failed
  /// heartbeat must never disturb sync or registration state.
  Future<void> touch() async {
    if (!isRegistered || !_entitlement.cloudEnabled) return;
    try {
      await _remoteDs.touch(await _identity.getDeviceUid());
    } catch (e, st) {
      debugPrint('[DeviceRegistration] Error in touch: $e\n$st');
    }
  }

  Future<void> revoke(String deviceUid) async {
    await _remoteDs.revoke(deviceUid);
    // If we revoked ourselves, drop our own registration flag.
    final uid = await _identity.getDeviceUid();
    if (uid == deviceUid) {
      final biz = _activeBusinessContext.businessId;
      if (biz != null && biz.isNotEmpty) {
        _set(DeviceRegistrationStatus.capReached, biz);
      }
    }
  }

  void _set(DeviceRegistrationStatus status, String businessId) {
    final registered = status == DeviceRegistrationStatus.registered;
    _prefs.setBool('$_prefix:$businessId', registered);
    if (_status != status) {
      _status = status;
      _registrationRevision.value++;
    }
  }
}
