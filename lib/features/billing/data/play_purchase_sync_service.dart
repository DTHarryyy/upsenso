import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/features/billing/data/billing_remote_ds.dart';
import 'package:pos/features/billing/data/iap_service.dart';

/// Where a purchase currently stands, for UI feedback only — entitlement itself
/// always comes from EntitlementService.
///
/// [superseded] is deliberately silent: it means Play handed back the old
/// subscription of a completed plan change, which is bookkeeping, not a failure.
enum PlayPurchasePhase { pending, granted, failed, canceled, stuck, superseded }

class PlayPurchaseEvent {
  final PlayPurchasePhase phase;

  /// User-facing text for [PlayPurchasePhase.failed] / [PlayPurchasePhase.stuck];
  /// null otherwise.
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

  /// Verifications running right now, keyed by token. Play can re-emit the same
  /// purchase (a restore during an in-flight verify) and one round trip is
  /// enough — callers share the running future so they all see the real answer.
  final Map<String, Future<bool>> _inFlight = <String, Future<bool>>{};

  /// Tokens the server permanently refused. Re-verifying them on every restore
  /// would just burn round trips for the same 4xx.
  final Set<String> _rejected = <String>{};

  /// Tokens already granted. Without this memo every `granted` triggers a page
  /// reload, which triggers a restore, which re-emits the same purchase — an
  /// endless verify loop that only ever stopped when a verify FAILED.
  final Set<String> _granted = <String>{};

  /// Purchases that failed transiently (offline / 5xx) and deserve another go
  /// when the network returns.
  final Set<String> _retryable = <String>{};

  /// Attempts already spent per token, so backoff can grow and eventually stop
  /// instead of retrying a doomed call forever.
  final Map<String, int> _attempts = <String, int>{};

  /// One timer per token. A single shared timer meant a second retryable
  /// purchase cancelled the first one's retry, so only the last token scheduled
  /// ever came back.
  final Map<String, Timer> _backoffTimers = <String, Timer>{};

  /// Beyond this the user is told plainly rather than left watching a spinner.
  /// Roughly covers 5s → 80s of backoff.
  static const int _maxAttempts = 5;

  /// Play's own view of what this account currently owns. A plan change needs
  /// it as `oldPurchaseDetails`, or Play stacks a second subscription instead
  /// of replacing the first.
  ///
  /// Must be cleared whenever Play stops vouching for it: a token from a
  /// canceled, expired or foreign-account purchase handed back as
  /// `oldPurchaseDetails` is rejected, which Play reports as the unhelpful
  /// "unable to change your subscription plan".
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

  /// Drop everything tied to the signed-out tenant. Without this the next user
  /// on this device inherits the previous one's owned purchase and hands it to
  /// Play as the "old purchase" of their own plan change.
  void reset() {
    _cancelAllRetries();
    _activePurchase = null;
    _inFlight.clear();
    _rejected.clear();
    _granted.clear();
    _retryable.clear();
    _attempts.clear();
  }

  void _cancelAllRetries() {
    for (final t in _backoffTimers.values) {
      t.cancel();
    }
    _backoffTimers.clear();
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
        // The user backed out of a CHANGE — whatever they owned before is still
        // what they own, so the cached purchase stands. Only drop it if this
        // cancel was for the very purchase we were holding.
        _forgetIfSame(p);
        await _iap.completePurchase(p);
        _emit(const PlayPurchaseEvent(PlayPurchasePhase.canceled));
        break;
      case PurchaseStatus.error:
        debugPrint('[PlayPurchaseSync] purchase error: '
            '${p.error?.code} ${p.error?.message} ${p.error?.details}');
        _forgetIfSame(p);
        // No money changed hands — completing here just clears the queue.
        await _iap.completePurchase(p);
        _emit(PlayPurchaseEvent(
          PlayPurchasePhase.failed,
          message: _messageForIapError(p.error),
        ));
        break;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // Cache regardless of the verify outcome below: this is Play's own view
        // of what's owned, which is exactly what a plan change needs.
        //
        // A `restored` must not overwrite a purchase we already granted. After a
        // plan change Play keeps handing back the superseded subscription for a
        // while, and letting it win here is what fed the OLD token to the next
        // plan change as `oldPurchaseDetails`.
        if (p.status == PurchaseStatus.purchased || !_holdsGrantedPurchase) {
          _activePurchase = p;
        }
        await _verify(p);
        break;
    }
  }

  bool get _holdsGrantedPurchase {
    final held = _activePurchase;
    return held != null &&
        _granted.contains(held.verificationData.serverVerificationData);
  }

  void _forgetIfSame(PurchaseDetails p) {
    if (_activePurchase?.purchaseID == p.purchaseID &&
        _activePurchase?.productID == p.productID) {
      _activePurchase = null;
    }
  }

  /// Play's own error codes, translated into something a shop owner can act on.
  /// Previously every one of these collapsed into a single generic sentence, so
  /// the user could not tell "already own it" from "Play is down".
  ///
  /// Matches on code AND message: on Android the plugin always sets
  /// `code: 'purchase_error'` and puts the real answer in `message` as the Dart
  /// enum name (`BillingResponse.itemAlreadyOwned`). Keying off `code` alone —
  /// as this did — made every branch below unreachable, so users saw the raw
  /// enum name instead. Normalising to bare uppercase letters matches both.
  static String _messageForIapError(IAPError? e) {
    final code = _normaliseErrorKey('${e?.code ?? ''} ${e?.message ?? ''}');
    if (code.contains('ITEMALREADYOWNED')) {
      return 'You already own this plan on Google Play. Tap "Restore purchases" '
          'to sync it to this device.';
    }
    if (code.contains('USERCANCELED') || code.contains('USERCANCELLED')) {
      return 'Purchase canceled.';
    }
    if (code.contains('ITEMUNAVAILABLE') || code.contains('ITEMNOTOWNED')) {
      return 'That plan isn\'t available on your Google account right now.';
    }
    if (code.contains('SERVICEUNAVAILABLE') ||
        code.contains('SERVICEDISCONNECTED') ||
        code.contains('SERVICETIMEOUT') ||
        code.contains('NETWORKERROR')) {
      return 'Google Play is unreachable right now. Check your connection and '
          'try again.';
    }
    if (code.contains('BILLINGUNAVAILABLE')) {
      return 'Google Play billing isn\'t available on this account. Make sure '
          'you\'re signed in to the Play Store with a supported payment method.';
    }
    if (code.contains('FEATURENOTSUPPORTED')) {
      return 'This device\'s Play Store version doesn\'t support subscription '
          'changes. Update Google Play and try again.';
    }
    if (code.contains('DEVELOPERERROR')) {
      return 'We couldn\'t start that plan change. Please contact support.';
    }
    // Nothing recognised — never show the raw enum name or SDK string.
    return 'The purchase couldn\'t be completed. Please try again, or contact '
        'support if it keeps happening.';
  }

  /// Bare uppercase letters, so `ITEM_ALREADY_OWNED`,
  /// `BillingResponse.itemAlreadyOwned` and `itemAlreadyOwned` all collapse to
  /// the same key.
  static String _normaliseErrorKey(String raw) =>
      raw.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');

  /// Re-run verification for whatever Play says is currently owned. Used when a
  /// user taps a plan they already own — the purchase exists, only the grant is
  /// missing. Returns true when entitlement was granted.
  Future<bool> reverifyActive() async {
    final p = _activePurchase;
    if (p == null) return false;
    final token = p.verificationData.serverVerificationData;
    // A previous permanent refusal must not block a deliberate user retry.
    _rejected.remove(token);
    _attempts.remove(token);
    return _verify(p);
  }

  Future<bool> _verify(PurchaseDetails p) {
    final token = p.verificationData.serverVerificationData;
    // Play re-emits every owned purchase on each restore. Without this memo a
    // grant triggered a reload, which triggered a restore, which re-verified the
    // same token — an unbounded loop that only ended when a verify failed.
    if (_granted.contains(token)) return Future.value(true);
    if (_rejected.contains(token)) return Future.value(false);
    // A concurrent verify must hand back the SAME answer rather than a bare
    // false: reporting "not granted" while the grant was mid-flight is what let
    // buyPlan paint an error over a purchase that in fact succeeded.
    final existing = _inFlight[token];
    if (existing != null) return existing;
    final run = _runVerify(p, token);
    _inFlight[token] = run;
    return run;
  }

  Future<bool> _runVerify(PurchaseDetails p, String token) async {
    try {
      await _remoteDs.verifyPlayPurchase(
        productId: p.productID,
        purchaseToken: token,
      );
      // Granted — acknowledge so Google doesn't auto-refund, then refresh the
      // entitlement so every listener (banner, router, Billing page) repaints.
      await _iap.completePurchase(p);
      _granted.add(token);
      _retryable.remove(token);
      _attempts.remove(token);
      _backoffTimers.remove(token)?.cancel();
      final refreshed = await _entitlement.syncEntitlement();
      _emit(PlayPurchaseEvent(
        PlayPurchasePhase.granted,
        // The grant is banked either way; only the local repaint is missing, so
        // say so instead of reporting a success the screen doesn't show yet.
        message: refreshed
            ? null
            : 'Your plan is active. Refreshing this device — pull down if it '
                'doesn\'t update.',
      ));
      return true;
    } on PlayVerifyException catch (e, st) {
      debugPrint('[PlayPurchaseSync] Error in _verify: $e\n$st');
      if (e.isSuperseded) {
        // The old subscription of a completed plan change. Play keeps handing it
        // back for a while; it is not a failure and must stay silent.
        _rejected.add(token);
        _retryable.remove(token);
        _forgetIfSame(p);
        _emit(const PlayPurchaseEvent(PlayPurchasePhase.superseded));
      } else if (e.isPermanent) {
        // Left UNACKNOWLEDGED on purpose — Google refunds the user in 3 days,
        // which is the right outcome when we can never grant what they bought.
        _rejected.add(token);
        _retryable.remove(token);
        // Play must never be offered a token the server refused as the "old
        // purchase" of a change — it rejects the whole flow with the unhelpful
        // "unable to change your subscription plan".
        _forgetIfSame(p);
        _emit(PlayPurchaseEvent(
          PlayPurchasePhase.stuck,
          message: 'We couldn\'t confirm your purchase (${e.message}). '
              'You won\'t be charged — contact support if this persists.',
        ));
      } else if (e.isConfigFault) {
        // Our own misconfiguration: retrying cannot help, so don't promise it.
        _rejected.add(token);
        _retryable.remove(token);
        _emit(const PlayPurchaseEvent(
          PlayPurchasePhase.stuck,
          message: 'Your payment went through, but we couldn\'t activate the '
              'plan because of a problem on our side. Google will refund you '
              'automatically if we can\'t fix it — please contact support.',
        ));
      } else {
        _scheduleRetry(token);
      }
      return false;
    } catch (e, st) {
      debugPrint('[PlayPurchaseSync] Error in _verify: $e\n$st');
      _scheduleRetry(token);
      return false;
    } finally {
      _inFlight.remove(token);
    }
  }

  /// Exponential backoff, capped. The old code only ever retried on an
  /// offline→online flip, so a device that never lost connectivity was told
  /// "it will retry automatically" and then never did.
  void _scheduleRetry(String token) {
    _retryable.add(token);
    final attempt = (_attempts[token] ?? 0) + 1;
    _attempts[token] = attempt;

    if (attempt >= _maxAttempts) {
      _emit(const PlayPurchaseEvent(
        PlayPurchasePhase.stuck,
        message: 'Your payment went through, but we still can\'t confirm it '
            'with our server. Your plan will activate as soon as we reach it — '
            'reopen this page to try again, or contact support.',
      ));
      return;
    }

    _emit(const PlayPurchaseEvent(
      PlayPurchasePhase.failed,
      message: 'We couldn\'t reach the server to confirm your purchase. '
          'Retrying…',
    ));

    final delay = Duration(seconds: 5 * (1 << (attempt - 1)));
    _backoffTimers.remove(token)?.cancel();
    _backoffTimers[token] = Timer(delay, () {
      _backoffTimers.remove(token);
      if (_retryable.contains(token)) restore();
    });
  }

  void _emit(PlayPurchaseEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  Future<void> dispose() async {
    _cancelAllRetries();
    await _purchaseSub?.cancel();
    await _connectivitySub?.cancel();
    _purchaseSub = null;
    _connectivitySub = null;
    await _events.close();
  }
}
