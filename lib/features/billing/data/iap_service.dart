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

  /// Android `applicationId`. Play's subscription deep link needs it and no
  /// runtime API here exposes it — kept beside the billing code it serves so a
  /// rename shows up next to the purchase flow it would break.
  static const playPackageName = 'com.ledgidy.pos';

  /// Deep link to Google Play's subscription management screen — the only place
  /// a subscription can legitimately be changed or cancelled. Without
  /// [productId] it opens the user's subscription list, which is still the right
  /// destination.
  static Uri manageSubscriptionUri({String? productId}) {
    final base = 'https://play.google.com/store/account/subscriptions';
    if (productId == null || productId.isEmpty) return Uri.parse(base);
    return Uri.parse('$base?sku=$productId&package=$playPackageName');
  }

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

  /// Pick the [ProductDetails] that actually represents [basePlanId]'s standard
  /// price.
  ///
  /// Play returns ONE entry per base plan *and per discounted offer*, and every
  /// one of them carries the same product id — so keying a map on the id keeps
  /// whichever happened to come last. That is how a free-trial offer's token and
  /// its ₱0 price can end up driving a purchase the user isn't eligible for.
  /// Prefer the entry whose `offerId` is null: that is the plain base plan.
  static ProductDetails? selectBasePlanOffer(
    Iterable<ProductDetails> candidates,
    String basePlanId,
  ) {
    ProductDetails? basePlanMatch;
    ProductDetails? anyMatch;
    ProductDetails? fallback;

    for (final d in candidates) {
      fallback ??= d;
      final offer = _offerOf(d);
      if (offer == null) continue;
      if (basePlanId.isNotEmpty && offer.basePlanId != basePlanId) continue;
      anyMatch ??= d;
      if (offer.offerId == null) basePlanMatch ??= d;
    }
    return basePlanMatch ?? anyMatch ?? fallback;
  }

  static SubscriptionOfferDetailsWrapper? _offerOf(ProductDetails d) {
    if (d is! GooglePlayProductDetails) return null;
    final offers = d.productDetails.subscriptionOfferDetails;
    final i = d.subscriptionIndex;
    if (offers == null || i == null || i < 0 || i >= offers.length) return null;
    return offers[i];
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
    ReplacementMode replacementMode = ReplacementMode.withTimeProration,
  }) async {
    if (!isSupportedPlatform) return false;
    // Falls back to a plain purchase if the old one isn't a Play purchase —
    // never worth crashing the buy flow over. It used to fail mute, which hid
    // the case where a replacement silently became a second subscription.
    if (oldPurchase != null && oldPurchase is! GooglePlayPurchaseDetails) {
      debugPrint('[IapService] oldPurchase is ${oldPurchase.runtimeType}, not a '
          'GooglePlayPurchaseDetails — buying without replacement');
    }
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
