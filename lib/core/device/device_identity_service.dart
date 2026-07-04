import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Stable, persisted identity for this app installation — scopes the
/// per-(business, device) audit hash chain.
///
/// Deliberately separate from [SecureStorageService]: the chain identity must
/// survive logout/account-switch, so it owns its own storage key. On web the
/// uid lives in SharedPreferences (localStorage) — clearing site data starts a
/// new chain; the old chain persists server-side and goes visibly silent.
class DeviceIdentityService {
  static const _key = 'device_chain_uid';
  static const _labelKey = 'device_chain_label';
  static const _headSentinelPrefix = 'audit_chain_head';

  DeviceIdentityService({
    required SharedPreferences prefs,
    FlutterSecureStorage? secureStorage,
  })  : _prefs = prefs,
        _secure = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;
  String? _cached;
  bool _restoredFromStorage = false;

  /// True when the current uid was read back from persistent storage (a prior
  /// install), false when it was freshly minted this session. The audit chain
  /// uses this to decide collision risk: a restored uid may already own a
  /// server chain we can't confirm; a freshly-minted uuid never can.
  bool get wasRestoredFromStorage => _restoredFromStorage;

  /// The persisted device uid, minted on first use.
  Future<String> getDeviceUid() async {
    if (_cached != null) return _cached!;
    try {
      final existing =
          kIsWeb ? _prefs.getString(_key) : await _secure.read(key: _key);
      if (existing != null && existing.isNotEmpty) {
        _cached = existing;
        _restoredFromStorage = true;
        return existing;
      }
    } catch (e, st) {
      debugPrint('[DeviceIdentity] Error in getDeviceUid: $e\n$st');
    }
    return rotate();
  }

  /// Mints and persists a fresh uid — first launch, or when the audit chain's
  /// genesis-resume finds a stored uid whose old chain can't be continued.
  Future<String> rotate() async {
    final uid = const Uuid().v4();
    try {
      if (kIsWeb) {
        await _prefs.setString(_key, uid);
      } else {
        await _secure.write(key: _key, value: uid);
      }
      // A new chain identity gets a freshly resolved label too — the stored
      // one described the previous uid's chain.
      await _prefs.remove(_labelKey);
    } catch (e, st) {
      // Persistence failure degrades to a per-session uid; audit logging
      // must keep working regardless.
      debugPrint('[DeviceIdentity] Error in rotate: $e\n$st');
    }
    _cached = uid;
    _restoredFromStorage = false;
    return uid;
  }

  /// Stable human label for this chain identity, resolved once via [resolve]
  /// and persisted for the uid's lifetime. Browser-name detection flaps
  /// between sessions ("Web · chrome" / "Web · safari" on ONE device was
  /// observed in prod on 2026-07-03) — a per-write label would scatter one
  /// chain across apparent devices in the verify UI.
  Future<String> getChainLabel(Future<String> Function() resolve) async {
    try {
      final stored = _prefs.getString(_labelKey);
      if (stored != null && stored.isNotEmpty) return stored;
      final label = await resolve();
      await _prefs.setString(_labelKey, label);
      return label;
    } catch (e, st) {
      debugPrint('[DeviceIdentity] Error in getChainLabel: $e\n$st');
      return resolve();
    }
  }

  /// Storage-eviction sentinel: the highest chain seq this device has ever
  /// written for (business, uid), kept in prefs/localStorage — deliberately a
  /// DIFFERENT store than the Drift DB (IndexedDB on web). A local DB head
  /// below the sentinel means the browser evicted the database while
  /// localStorage survived: history is missing through storage loss, not
  /// tampering, and the verifier reports it as such.
  Future<void> setLastLocalHeadSeq(
    String businessId,
    String deviceUid,
    int seq,
  ) async {
    try {
      await _prefs.setInt('$_headSentinelPrefix:$businessId:$deviceUid', seq);
    } catch (e, st) {
      debugPrint('[DeviceIdentity] Error in setLastLocalHeadSeq: $e\n$st');
    }
  }

  Future<int?> getLastLocalHeadSeq(String businessId, String deviceUid) async {
    try {
      return _prefs.getInt('$_headSentinelPrefix:$businessId:$deviceUid');
    } catch (e, st) {
      debugPrint('[DeviceIdentity] Error in getLastLocalHeadSeq: $e\n$st');
      return null;
    }
  }
}
