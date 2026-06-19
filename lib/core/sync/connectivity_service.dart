import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';
import 'package:pos/core/env/app_env.dart';

/// Service to track network connectivity status.
///
/// connectivity_plus only reports the link TYPE (wifi/mobile/ethernet), not
/// whether the network actually reaches anything — a captive portal or a
/// dead uplink still reports "connected". [isConnected] backs the link-type
/// check with a real reachability probe against the Supabase host so the
/// app doesn't treat a dead connection as online and burn through failed
/// sync attempts.
class ConnectivityService {
  final Connectivity _connectivity;
  final http.Client _httpClient;

  ConnectivityService([Connectivity? connectivity, http.Client? httpClient])
    : _connectivity = connectivity ?? Connectivity(),
      _httpClient = httpClient ?? http.Client();

  /// Stream of connectivity changes, debounced so a burst of flapping
  /// link-type events (and the reachability probe per event) collapses into
  /// one update instead of triggering a sync attempt per flap.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged
        .debounceTime(const Duration(milliseconds: 800))
        .asyncMap((results) => _isReachable(results));
  }

  /// Check current connectivity status, including reachability.
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return _isReachable(result);
  }

  Future<bool> _isReachable(List<ConnectivityResult> results) async {
    if (!_hasLinkType(results)) return false;
    if (AppEnv.supabaseUrl.isEmpty) {
      // No backend configured to probe (e.g. a test run) — fall back to the
      // link-type signal alone.
      return true;
    }
    try {
      final response = await _httpClient
          .head(Uri.parse('${AppEnv.supabaseUrl}/auth/v1/health'))
          .timeout(const Duration(seconds: 3));
      // Any response — even 401/404 — proves the network path actually
      // reaches the host, which is all this check needs to confirm.
      return response.statusCode > 0;
    } catch (_) {
      return false;
    }
  }

  bool _hasLinkType(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet,
    );
  }
}
