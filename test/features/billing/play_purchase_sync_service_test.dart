import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pos/core/permissions/entitlement_service.dart';
import 'package:pos/core/sync/connectivity_service.dart';
import 'package:pos/features/billing/data/billing_remote_ds.dart';
import 'package:pos/features/billing/data/iap_service.dart';
import 'package:pos/features/billing/data/play_purchase_sync_service.dart';

class _MockIap extends Mock implements IapService {}

class _MockRemoteDs extends Mock implements BillingRemoteDs {}

class _MockEntitlement extends Mock implements EntitlementService {}

class _MockConnectivity extends Mock implements ConnectivityService {}

PurchaseDetails _purchase(
  String productId, {
  PurchaseStatus status = PurchaseStatus.purchased,
  String? token,
}) =>
    PurchaseDetails(
      purchaseID: 'order-$productId',
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: '{}',
        serverVerificationData: token ?? 'token-$productId',
        source: 'google_play',
      ),
      transactionDate: '1700000000000',
      status: status,
    );

void main() {
  late _MockIap iap;
  late _MockRemoteDs remoteDs;
  late _MockEntitlement entitlement;
  late _MockConnectivity connectivity;
  late StreamController<List<PurchaseDetails>> purchases;
  late PlayPurchaseSyncService service;

  setUpAll(() => registerFallbackValue(_purchase('fallback')));

  setUp(() {
    iap = _MockIap();
    remoteDs = _MockRemoteDs();
    entitlement = _MockEntitlement();
    connectivity = _MockConnectivity();
    purchases = StreamController<List<PurchaseDetails>>.broadcast();

    when(() => iap.isSupportedPlatform).thenReturn(true);
    when(() => iap.purchaseStream).thenAnswer((_) => purchases.stream);
    when(() => iap.completePurchase(any())).thenAnswer((_) async {});
    when(() => iap.restorePurchases()).thenAnswer((_) async {});
    when(() => entitlement.syncEntitlement()).thenAnswer((_) async => true);
    when(() => connectivity.onConnectivityChanged)
        .thenAnswer((_) => const Stream<bool>.empty());

    service = PlayPurchaseSyncService(
      iap: iap,
      remoteDs: remoteDs,
      entitlement: entitlement,
      connectivity: connectivity,
    );
  });

  tearDown(() async {
    await service.dispose();
    await purchases.close();
  });

  Future<void> deliver(List<PurchaseDetails> items) async {
    purchases.add(items);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('a granted purchase is acknowledged and refreshes entitlement', () async {
    when(() => remoteDs.verifyPlayPurchase(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        )).thenAnswer((_) async {});
    service.start();

    await deliver([_purchase('upsenso_starter_monthly')]);

    verify(() => iap.completePurchase(any())).called(1);
    verify(() => entitlement.syncEntitlement()).called(1);
  });

  // The revenue-critical rule: an unacknowledged purchase is auto-refunded by
  // Google after 3 days. Acknowledging one we could not grant would leave the
  // user charged, un-entitled, and past the refund window.
  test('a permanently refused purchase is NOT acknowledged', () async {
    when(() => remoteDs.verifyPlayPurchase(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        )).thenThrow(const PlayVerifyException(400, 'Unknown product'));
    service.start();

    await deliver([_purchase('upsenso_starter_monthly')]);

    verifyNever(() => iap.completePurchase(any()));
    verifyNever(() => entitlement.syncEntitlement());
  });

  test('a transient failure is NOT acknowledged either', () async {
    when(() => remoteDs.verifyPlayPurchase(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        )).thenThrow(const PlayVerifyException(503, 'upstream down'));
    service.start();

    await deliver([_purchase('upsenso_starter_monthly')]);

    verifyNever(() => iap.completePurchase(any()));
  });

  test('a permanently refused token is not re-verified on restore', () async {
    when(() => remoteDs.verifyPlayPurchase(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        )).thenThrow(const PlayVerifyException(409, 'Subscription not active'));
    service.start();

    await deliver([_purchase('upsenso_starter_monthly')]);
    // Play re-emits owned purchases on every restore.
    await deliver([
      _purchase('upsenso_starter_monthly', status: PurchaseStatus.restored),
    ]);

    verify(() => remoteDs.verifyPlayPurchase(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        )).called(1);
  });

  test('a cancelled purchase is completed and never verified', () async {
    service.start();

    await deliver([
      _purchase('upsenso_starter_monthly', status: PurchaseStatus.canceled),
    ]);

    verify(() => iap.completePurchase(any())).called(1);
    verifyNever(() => remoteDs.verifyPlayPurchase(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        ));
  });

  test('activePurchase tracks what Play reports as owned', () async {
    when(() => remoteDs.verifyPlayPurchase(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        )).thenAnswer((_) async {});
    service.start();

    expect(service.activePurchase, isNull);
    await deliver([
      _purchase('upsenso_growth_monthly', status: PurchaseStatus.restored),
    ]);

    expect(service.activePurchase?.productID, 'upsenso_growth_monthly');
  });

  // A 4xx means the server will never grant this purchase, so the user is
  // charged with nothing to show for it — that gets `stuck` (a dialog they must
  // acknowledge), not `failed` (a snackbar they can scroll past).
  test('emits granted then stuck on the event stream', () async {
    when(() => remoteDs.verifyPlayPurchase(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        )).thenAnswer((_) async {});
    service.start();

    final seen = <PlayPurchasePhase>[];
    final sub = service.events.listen((e) => seen.add(e.phase));

    await deliver([_purchase('a')]);
    when(() => remoteDs.verifyPlayPurchase(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        )).thenThrow(const PlayVerifyException(400, 'nope'));
    await deliver([_purchase('b')]);

    await sub.cancel();
    expect(seen, [PlayPurchasePhase.granted, PlayPurchasePhase.stuck]);
  });

  // Our own misconfiguration surfaces as a 5xx, but no client retry can clear
  // it. Promising "retrying automatically" there leaves a charged user waiting
  // for something that will never happen.
  test('a server config fault is terminal, not retried', () async {
    when(() => remoteDs.verifyPlayPurchase(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        )).thenThrow(const PlayVerifyException(
      500,
      'Billing is temporarily misconfigured',
      code: 'play_config',
      stage: 'google_get_sub',
    ));
    service.start();

    final seen = <PlayPurchaseEvent>[];
    final sub = service.events.listen(seen.add);
    await deliver([_purchase('a')]);
    await sub.cancel();

    expect(seen.single.phase, PlayPurchasePhase.stuck);
    expect(seen.single.message, contains('problem on our side'));
    // Never acknowledged: Google's auto-refund is the correct outcome when we
    // cannot grant what the user paid for.
    verifyNever(() => iap.completePurchase(any()));
  });

  // A token Play no longer considers active must not be offered back to Play as
  // the `oldPurchaseDetails` of a plan change — that is rejected as
  // "unable to change your subscription plan".
  test('a 409 clears the cached active purchase', () async {
    when(() => remoteDs.verifyPlayPurchase(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        )).thenThrow(const PlayVerifyException(409, 'Subscription not active'));
    service.start();

    await deliver([_purchase('upsenso_starter_monthly')]);

    expect(service.activePurchase, isNull);
  });

  test('an errored purchase clears the cached active purchase', () async {
    when(() => remoteDs.verifyPlayPurchase(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        )).thenAnswer((_) async {});
    service.start();

    await deliver([_purchase('upsenso_starter_monthly')]);
    expect(service.activePurchase, isNotNull);

    await deliver([
      _purchase('upsenso_starter_monthly', status: PurchaseStatus.error),
    ]);

    expect(service.activePurchase, isNull);
  });

  test('reset drops the previous tenant\'s purchase', () async {
    when(() => remoteDs.verifyPlayPurchase(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        )).thenAnswer((_) async {});
    service.start();
    await deliver([_purchase('upsenso_growth_monthly')]);
    expect(service.activePurchase, isNotNull);

    service.reset();

    expect(service.activePurchase, isNull);
  });

  test('off Android nothing attaches and restore is a no-op', () async {
    when(() => iap.isSupportedPlatform).thenReturn(false);
    service.start();

    await service.restore();

    verifyNever(() => iap.restorePurchases());
  });

  // ── Plan change: the superseded old subscription ──────────────────────────
  // The reported bug. After an upgrade Play keeps handing back the replaced
  // subscription; verifying it returned 409, which the client read as "charged
  // but not granted" and raised a blocking dialog over a plan that had in fact
  // just upgraded successfully.
  group('superseded token', () {
    setUp(() {
      when(() => remoteDs.verifyPlayPurchase(
            productId: any(named: 'productId'),
            purchaseToken: any(named: 'purchaseToken'),
          )).thenThrow(const PlayVerifyException(
        409,
        'Subscription superseded',
        code: 'play_superseded',
      ));
    });

    test('never raises a stuck alert', () async {
      service.start();
      final events = <PlayPurchaseEvent>[];
      service.events.listen(events.add);

      await deliver([
        _purchase('upsenso_starter_monthly', status: PurchaseStatus.restored),
      ]);

      expect(
        events.map((e) => e.phase),
        contains(PlayPurchasePhase.superseded),
      );
      expect(
        events.map((e) => e.phase),
        isNot(contains(PlayPurchasePhase.stuck)),
      );
    });

    test('is not acknowledged and clears the cached purchase', () async {
      service.start();

      await deliver([
        _purchase('upsenso_starter_monthly', status: PurchaseStatus.restored),
      ]);

      expect(service.activePurchase, isNull);
      verifyNever(() => iap.completePurchase(any()));
    });
  });

  // The loop: granted → page reload → restore → Play re-emits → verify → granted.
  // Each lap cost a full verify round trip and it only ever ended when a verify
  // FAILED, which is how the stale-token 409 above reliably won the race.
  test('an already-granted token is never re-verified', () async {
    when(() => remoteDs.verifyPlayPurchase(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        )).thenAnswer((_) async {});
    service.start();

    await deliver([_purchase('upsenso_growth_monthly')]);
    // Three restores, as a page reload would produce.
    for (var i = 0; i < 3; i++) {
      await deliver([
        _purchase('upsenso_growth_monthly', status: PurchaseStatus.restored),
      ]);
    }

    verify(() => remoteDs.verifyPlayPurchase(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        )).called(1);
    verify(() => iap.completePurchase(any())).called(1);
  });

  // Play returns the replaced subscription alongside the new one for a while.
  // Letting it win here is what fed the OLD token to the next plan change as
  // `oldPurchaseDetails`, which Play rejects outright.
  test('a restored old token does not displace a granted purchase', () async {
    when(() => remoteDs.verifyPlayPurchase(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        )).thenAnswer((_) async {});
    service.start();

    await deliver([_purchase('upsenso_growth_monthly')]);
    expect(service.activePurchase?.productID, 'upsenso_growth_monthly');

    await deliver([
      _purchase('upsenso_starter_monthly', status: PurchaseStatus.restored),
    ]);

    expect(service.activePurchase?.productID, 'upsenso_growth_monthly');
  });

  // Only a 409 used to clear it, so a 400/403-refused token stayed eligible as
  // the "old purchase" of the next change.
  test('any permanent refusal clears the cached active purchase', () async {
    when(() => remoteDs.verifyPlayPurchase(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        )).thenThrow(const PlayVerifyException(403, 'Belongs to another account'));
    service.start();

    await deliver([_purchase('upsenso_starter_monthly')]);

    expect(service.activePurchase, isNull);
  });

  // The grant is banked server-side; only this device's repaint is missing. It
  // must still report granted, or the purchase flow strands on a spinner.
  test('a failed entitlement refresh still grants, with a notice', () async {
    when(() => remoteDs.verifyPlayPurchase(
          productId: any(named: 'productId'),
          purchaseToken: any(named: 'purchaseToken'),
        )).thenAnswer((_) async {});
    when(() => entitlement.syncEntitlement()).thenAnswer((_) async => false);
    service.start();
    final events = <PlayPurchaseEvent>[];
    service.events.listen(events.add);

    await deliver([_purchase('upsenso_growth_monthly')]);

    final granted =
        events.firstWhere((e) => e.phase == PlayPurchasePhase.granted);
    expect(granted.message, isNotNull);
    verify(() => iap.completePurchase(any())).called(1);
  });

  // Every branch was unreachable: the Android plugin always sets
  // code 'purchase_error' and puts the real answer in `message` as the Dart enum
  // name, so users were shown "BillingResponse.itemAlreadyOwned" verbatim.
  group('Play error messages are translated', () {
    Future<String> messageFor(IAPError error) async {
      service.start();
      final events = <PlayPurchaseEvent>[];
      service.events.listen(events.add);
      await deliver([
        PurchaseDetails(
          purchaseID: 'p',
          productID: 'upsenso_starter_monthly',
          verificationData: PurchaseVerificationData(
            localVerificationData: '{}',
            serverVerificationData: 'tok',
            source: 'google_play',
          ),
          transactionDate: '1700000000000',
          status: PurchaseStatus.error,
        )..error = error,
      ]);
      return events
          .firstWhere((e) => e.phase == PlayPurchasePhase.failed)
          .message!;
    }

    test('the Android enum-name form matches', () async {
      final msg = await messageFor(IAPError(
        source: 'google_play',
        code: 'purchase_error',
        message: 'BillingResponse.itemAlreadyOwned',
      ));
      expect(msg, contains('already own'));
      expect(msg, contains('Restore purchases'));
    });

    test('the screaming-snake form still matches', () async {
      final msg = await messageFor(IAPError(
        source: 'google_play',
        code: 'ITEM_ALREADY_OWNED',
        message: '',
      ));
      expect(msg, contains('already own'));
    });

    test('billing unavailable names the payment method', () async {
      final msg = await messageFor(IAPError(
        source: 'google_play',
        code: 'purchase_error',
        message: 'BillingResponse.billingUnavailable',
      ));
      expect(msg, contains('payment method'));
    });

    test('a developer error points at support', () async {
      final msg = await messageFor(IAPError(
        source: 'google_play',
        code: 'purchase_error',
        message: 'BillingResponse.developerError',
      ));
      expect(msg, contains('contact support'));
    });

    test('an unrecognised error never leaks the raw SDK string', () async {
      final msg = await messageFor(IAPError(
        source: 'google_play',
        code: 'purchase_error',
        message: 'BillingResponse.someFutureCode',
      ));
      expect(msg, isNot(contains('BillingResponse')));
      expect(msg, contains('couldn\'t be completed'));
    });
  });
}
