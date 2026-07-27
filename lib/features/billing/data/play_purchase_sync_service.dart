import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/features/billing/data/billing_remote_ds.dart';
import 'package:pos/features/billing/data/iap_service.dart';

/// Where a purchase currently stands, for UI feedback only — entitlement itself
/// always comes from EntitlementService.
enum PlayPurchasePhase { pending, granted, failed, canceled }

class PlayPurchaseEvent {
  final PlayPurchasePhase phase;

  /// User-facing text for [PlayPurchasePhase.failed]; null otherwise.
  final String? message;

  const PlayPurchaseEvent(this.phase, {this.message});
}

/// Owns the Play purchase stream for the whole app lifetime and is the ONLY
/// place a purchase is verified and completed.
///
/// It exists because the purchase stream is not tied to any screen: Play can
/// deliver a purchase while the user is anywhere in the app, a pending payment
/// can resolve hours later, and an interrupted delivery is re-emitted on the
/// next attach. When the only listener lived on the Billing page, every one of
/// those was dropped — and a dropped purchase is never acknowledged, which
/// Google auto-refunds after three days.
///
/// Deliberately does NOT complete a purchase the server refused to grant.
/// Leaving it unacknowledged is what makes Google refund the user; completing
/// it would strand them: charged, no entitlement, no refund.
class PlayPurchaseSyncService {
  final IapService _iap;
  final BillingRemoteDs _remoteDs;
  final EntitlementService _entitlement;
  final ConnectivityService _connectivity;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  StreamSubscription<bool>? _connectivitySub;
  final StreamController<PlayPurchaseEvent> _events =
      StreamController<PlayPurchaseEvent>.broadcast();

  /// Tokens being verified right now — Play can re-emit the same purchase (a
  /// restore during an in-flight verify), and one round trip is enough.
  final Set<String> _inFlight = <String>{};

  /// Tokens the server permanently refused. Re-verifying them on every restore
  /// would just burn round trips for the same 4xx.
  final Set<String> _rejected = <String>{};

  /// Purchases that failed transiently (offline / 5xx) and deserve another go
  /// when the network returns.
  final Set<String> _retryable = <String>{};

  /// Play's own view of what this account currently owns. A plan change needs
  /// it as `oldPurchaseDetails`, or Play stacks a second subscription instead
  /// of replacing the first.
  PurchaseDetails? _activePurchase;

  PlayPurchaseSyncService({
    required IapService iap,
    required BillingRemoteDs remoteDs,
    required EntitlementService entitlement,
    required ConnectivityService connectivity,
  })  : _iap = iap,
        _remoteDs = remoteDs,
        _entitlement = entitlement,
        _connectivity = connectivity;

  Stream<PlayPurchaseEvent> get events => _events.stream;

  PurchaseDetails? get activePurchase => _activePurchase;

  bool get isSupportedPlatform => _iap.isSupportedPlatform;

  /// Attach for the process lifetime. Safe to call more than once.
  void start() {
    if (!_iap.isSupportedPlatform || _purchaseSub != null) return;
    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e, StackTrace st) =>
          debugPrint('[PlayPurchaseSync] purchaseStream error: $e\n$st'),
    );
    // A purchase that failed to verify offline gets another chance the moment
    // the network is back, rather than waiting for the user to find Restore.
    _connectivitySub = _connectivity.onConnectivityChanged.listen((online) {
      if (online && _retryable.isNotEmpty) {
        debugPrint(
            '[PlayPurchaseSync] back online — retrying ${_retryable.length} purchase(s)');
        restore();
      }
    });
  }

  /// Re-emit owned purchases so a reinstall or a second device recovers its
  /// plan with no user action. Rethrows so a user-initiated Restore can report
  /// failure.
  Future<void> restore() async {
    if (!_iap.isSupportedPlatform) return;
    await _iap.restorePurchases();
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      await _handle(p);
    }
  }

  Future<void> _handle(PurchaseDetails p) async {
    switch (p.status) {
      case PurchaseStatus.pending:
        _emit(const PlayPurchaseEvent(PlayPurchasePhase.pending));
        break;
      case PurchaseStatus.canceled:
        await _iap.completePurchase(p);
        _emit(const PlayPurchaseEvent(PlayPurchasePhase.canceled));
        break;
      case PurchaseStatus.error:
        debugPrint('[PlayPurchaseSync] purchase error: ${p.error}');
        // No money changed hands — completing here just clears the queue.
        await _iap.completePurchase(p);
        _emit(const PlayPurchaseEvent(
          PlayPurchasePhase.failed,
          message: 'The purchase couldn\'t be completed. Please try again.',
        ));
        break;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // Cache regardless of the verify outcome below: this is Play's own view
        // of what's owned, which is exactly what a plan change needs.
        _activePurchase = p;
        await _verify(p);
        break;
    }
  }

  Future<void> _verify(PurchaseDetails p) async {
    final token = p.verificationData.serverVerificationData;
    if (_inFlight.contains(token) || _rejected.contains(token)) return;
    _inFlight.add(token);
    try {
      await _remoteDs.verifyPlayPurchase(
        productId: p.productID,
        purchaseToken: token,
      );
      // Granted — acknowledge so Google doesn't auto-refund, then refresh the
      // entitlement so every listener (banner, router, Billing page) repaints.
      await _iap.completePurchase(p);
      _retryable.remove(token);
      await _entitlement.syncEntitlement();
      _emit(const PlayPurchaseEvent(PlayPurchasePhase.granted));
    } on PlayVerifyException catch (e, st) {
      debugPrint('[PlayPurchaseSync] Error in _verify: $e\n$st');
      if (e.isPermanent) {
        // Left UNACKNOWLEDGED on purpose — Google refunds the user in 3 days,
        // which is the right outcome when we can never grant what they bought.
        _rejected.add(token);
        _retryable.remove(token);
        _emit(PlayPurchaseEvent(
          PlayPurchasePhase.failed,
          message: 'We couldn\'t confirm your purchase (${e.message}). '
              'You won\'t be charged — contact support if this persists.',
        ));
      } else {
        _retryable.add(token);
        _emit(const PlayPurchaseEvent(
          PlayPurchasePhase.failed,
          message: 'We couldn\'t reach the server to confirm your purchase. '
              'It will retry automatically.',
        ));
      }
    } catch (e, st) {
      debugPrint('[PlayPurchaseSync] Error in _verify: $e\n$st');
      _retryable.add(token);
      _emit(const PlayPurchaseEvent(
        PlayPurchasePhase.failed,
        message: 'We couldn\'t confirm your purchase yet. It will retry '
            'automatically.',
      ));
    } finally {
      _inFlight.remove(token);
    }
  }

  void _emit(PlayPurchaseEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    await _connectivitySub?.cancel();
    _purchaseSub = null;
    _connectivitySub = null;
    await _events.close();
  }
}
