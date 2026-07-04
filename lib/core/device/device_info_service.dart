import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Resolves a short, human-readable label for the current device
/// (e.g. "Pixel 7 · Android 14"), used to tag audit log entries.
///
/// Resolved once and cached — device identity doesn't change mid-session.
class DeviceInfoService {
  final DeviceInfoPlugin _plugin;
  String? _cachedLabel;

  DeviceInfoService({DeviceInfoPlugin? plugin})
      : _plugin = plugin ?? DeviceInfoPlugin();

  Future<String> getDeviceLabel() async {
    if (_cachedLabel != null) return _cachedLabel!;
    try {
      _cachedLabel = await _resolveLabel();
    } catch (e, st) {
      debugPrint('[DeviceInfo] Error in getDeviceLabel: $e\n$st');
      _cachedLabel = 'Unknown device';
    }
    return _cachedLabel!;
  }

  /// Coarse platform bucket for the devices table — stable, no plugin call.
  String get platform {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  Future<String> _resolveLabel() async {
    if (kIsWeb) {
      final info = await _plugin.webBrowserInfo;
      return 'Web · ${info.browserName.name}';
    }
    if (Platform.isAndroid) {
      final info = await _plugin.androidInfo;
      return '${info.brand} ${info.model} · Android ${info.version.release}';
    }
    if (Platform.isIOS) {
      final info = await _plugin.iosInfo;
      return '${info.name} · iOS ${info.systemVersion}';
    }
    if (Platform.isWindows) {
      final info = await _plugin.windowsInfo;
      return '${info.computerName} · Windows';
    }
    if (Platform.isMacOS) {
      final info = await _plugin.macOsInfo;
      return '${info.model} · macOS ${info.osRelease}';
    }
    if (Platform.isLinux) {
      final info = await _plugin.linuxInfo;
      return '${info.prettyName} · Linux';
    }
    return 'Unknown device';
  }
}
