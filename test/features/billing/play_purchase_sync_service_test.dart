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
    when(() => entitlement.syncEntitlement()).thenAnswer((_) async {});
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

  test('emits granted then failed on the event stream', () async {
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
    expect(seen, [PlayPurchasePhase.granted, PlayPurchasePhase.failed]);
  });

  test('off Android nothing attaches and restore is a no-op', () async {
    when(() => iap.isSupportedPlatform).thenReturn(false);
    service.start();

    await service.restore();

    verifyNever(() => iap.restorePurchases());
  });
}
