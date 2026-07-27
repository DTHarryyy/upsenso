import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Outcome of a product-details query — keeps the found catalog separate from
/// the SKU ids Play didn't recognise (a Play Console config gap) and any hard
/// query error, so the UI can tell "not configured yet" from "network failed".
class IapProductQuery {
  final List<ProductDetails> products;
  final Set<String> notFoundIds;
  final String? error;

  const IapProductQuery({
    this.products = const [],
    this.notFoundIds = const {},
    this.error,
  });

  bool get hasError => error != null;
}

/// Thin wrapper over `in_app_purchase` for Google Play subscriptions
/// (M7.1 → Play Billing). Billing is Android-only — web keeps a read-only plan
/// view — so every entry point is guarded by [isSupportedPlatform] and fails
/// soft off it (empty results, no-ops). On unsupported platforms the store
/// instance is null and is never touched.
///
/// This service NEVER decides entitlement. It only drives the store; a
/// purchase's [PurchaseVerificationData.serverVerificationData] token is handed
/// to the `verify-play-purchase` edge function, which is the sole grantor of
/// Premium access. Supabase stays the single source of truth — nothing here
/// treats a client-side purchase as proof.
class IapService {
  final InAppPurchase? _iap;

  IapService(this._iap);

  /// Play Billing exists only on Android. Web/desktop/iOS return false so the
  /// billing UI routes to the read-only "manage on the Android app" path.
  bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android && _iap != null;

  /// Purchase + restore updates. The cubit listens; each `.purchased` /
  /// `.restored` event must be server-verified, then completed.
  Stream<List<PurchaseDetails>> get purchaseStream =>
      _iap?.purchaseStream ?? const Stream<List<PurchaseDetails>>.empty();

  /// Is the store reachable and billing available on this install?
  Future<bool> isAvailable() async {
    if (!isSupportedPlatform) return false;
    try {
      return await _iap!.isAvailable();
    } catch (e, st) {
      debugPrint('[IapService] Error in isAvailable: $e\n$st');
      return false;
    }
  }

  /// Ask Play for live localized pricing for the given SKUs. The id set comes
  /// from Supabase (`play_product_map`) — never hardcoded here.
  Future<IapProductQuery> queryProducts(Set<String> productIds) async {
    if (!isSupportedPlatform || productIds.isEmpty) {
      return const IapProductQuery();
    }
    try {
      final resp = await _iap!.queryProductDetails(productIds);
      return IapProductQuery(
        products: resp.productDetails,
        notFoundIds: resp.notFoundIDs.toSet(),
        error: resp.error?.message,
      );
    } catch (e, st) {
      debugPrint('[IapService] Error in queryProducts: $e\n$st');
      return IapProductQuery(error: e.toString());
    }
  }

  /// Launch the Play purchase flow for a subscription (subscriptions are
  /// non-consumable). [accountId] binds the purchase to the tenant on Google's
  /// side (obfuscated account id) for anti-fraud + webhook linkage. The return
  /// only says whether the flow LAUNCHED — the real outcome always arrives on
  /// [purchaseStream].
  ///
  /// [oldPurchase] must be set when the tenant already owns a different active
  /// subscription — without it Play treats this as a brand-new purchase and the
  /// old one keeps billing alongside it instead of being replaced.
  /// [replacementMode] controls how the switch is billed; only consulted when
  /// [oldPurchase] is set.
  Future<bool> buySubscription(
    ProductDetails product, {
    String? accountId,
    PurchaseDetails? oldPurchase,
    ReplacementMode replacementMode = ReplacementMode.chargeProratedPrice,
  }) async {
    if (!isSupportedPlatform) return false;
    // Falls back to a plain purchase if the old one isn't a Play purchase —
    // never worth crashing the buy flow over, and Play rejects a bad change
    // param anyway.
    final change = oldPurchase is GooglePlayPurchaseDetails
        ? ChangeSubscriptionParam(
            oldPurchaseDetails: oldPurchase,
            replacementMode: replacementMode,
          )
        : null;
    final param = change == null
        ? PurchaseParam(
            productDetails: product,
            // Mapped to Play's obfuscatedAccountId on Android.
            applicationUserName: accountId,
          )
        : GooglePlayPurchaseParam(
            productDetails: product,
            applicationUserName: accountId,
            changeSubscriptionParam: change,
          );
    try {
      return await _iap!.buyNonConsumable(purchaseParam: param);
    } catch (e, st) {
      debugPrint('[IapService] Error in buySubscription: $e\n$st');
      return false;
    }
  }

  /// Re-emit the account's active purchases on [purchaseStream] so a reinstall
  /// or new device can recover its subscription (a Play requirement). Rethrows
  /// so the cubit can surface a friendly "couldn't restore" message.
  Future<void> restorePurchases() async {
    if (!isSupportedPlatform) return;
    try {
      await _iap!.restorePurchases();
    } catch (e, st) {
      debugPrint('[IapService] Error in restorePurchases: $e\n$st');
      rethrow;
    }
  }

  /// Acknowledge a delivered purchase. MUST be called once the server has
  /// granted entitlement — Play auto-refunds an unacknowledged purchase after
  /// 3 days. No-op if the purchase doesn't need completing.
  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;
    try {
      await _iap!.completePurchase(purchase);
    } catch (e, st) {
      debugPrint('[IapService] Error in completePurchase: $e\n$st');
    }
  }
}
