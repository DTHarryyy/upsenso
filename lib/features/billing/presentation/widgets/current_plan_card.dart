import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_typography.dart';
import 'package:pos/core/permissions/plan_display.dart';
import 'package:pos/core/utils/formatters.dart';
import 'package:pos/core/widgets/app_soft_button.dart';
import 'package:pos/core/widgets/settings_tile.dart';
import 'package:pos/features/billing/data/iap_service.dart';
import 'package:pos/features/billing/domain/billing_models.dart';
import 'package:pos/features/billing/domain/upgrade_pitch.dart';
import 'package:pos/features/billing/presentation/widgets/locked_price_chip.dart';

/// What a paying tenant sees instead of the plan ladder: their tier name and
/// how to manage the subscription. Price, benefits and usage meters live on the
/// other tabs — repeating them here is noise once someone has bought.
///
/// Anyone with a tier above them gets an upgrade nudge on top; for a subscriber
/// it's the only route to the plan ladder, so it is never dismissible.
///
/// Purely presentational: everything it needs is passed in.
class CurrentPlanCard extends StatelessWidget {
  final String planCode;
  final String effectiveStatus; // active | past_due

  /// Catalog entry for [planCode]. Null offline — the catalog needs a network,
  /// which is also when you can't buy, so the nudge simply doesn't appear.
  final PlanOption? currentPlan;

  /// First tier above [currentPlan]; null on the top tier.
  final PlanOption? nextTier;

  /// Legacy price below list, already validated by the caller (see §4.9).
  final double? lockedPrice;

  /// End of the current paid period (renewal or, on past_due, grace expiry).
  /// Null offline before the entitlement cache has ever landed.
  final DateTime? renewsOn;

  /// Play product this device knows is owned — narrows the deep link to the
  /// exact subscription instead of the account's whole list.
  final String? ownedProductId;

  final bool playSupported;
  final bool canManage;

  /// Opens the upgrade sheet — wired to the nudge only.
  final VoidCallback onUpgrade;

  const CurrentPlanCard({
    super.key,
    required this.planCode,
    required this.effectiveStatus,
    required this.playSupported,
    required this.canManage,
    required this.onUpgrade,
    this.currentPlan,
    this.nextTier,
    this.lockedPrice,
    this.renewsOn,
    this.ownedProductId,
  });

  bool get _pastDue => effectiveStatus == 'past_due';

  /// "Active until"/"Access ends" rather than "Renews on" — true for both an
  /// auto-renewing Play subscription and an admin-comped period, neither of
  /// which we should promise will renew itself.
  String _periodLabel(DateTime d) =>
      '${_pastDue ? 'Access ends' : 'Active until'} ${AppFormatters.shortDate(d)}';

  /// Gated on the same conditions as the manage CTA — pointing someone at a
  /// ladder they can't buy from is worse than showing nothing.
  bool get _showUpgrade =>
      currentPlan != null && nextTier != null && playSupported && canManage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showUpgrade) ...[
          _UpgradeBanner(
            pitch: upgradePitch(currentPlan!, nextTier!),
            onTap: onUpgrade,
          ),
          const SizedBox(height: 16),
        ],
        SettingsSection(
          label: 'Account plan',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${planLabelOf(planCode)} Plan',
                    style: AppTextStyles.title(
                      context,
                    ).copyWith(color: AppColors.textPrimary),
                  ),
                  if (renewsOn != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _periodLabel(renewsOn!),
                      style: AppTextStyles.caption(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                  if (lockedPrice != null) ...[
                    const SizedBox(height: 10),
                    LockedPriceChip(price: lockedPrice!),
                  ],
                  const SizedBox(height: 14),
                  _manageCta(context),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Manage ──────────────────────────────────────────────────────────────────
  Widget _manageCta(BuildContext context) {
    if (!playSupported) {
      return const _MutedNote(
        'Your subscription is managed in the Upsenso Android app. '
        'Here you can review your plan anytime.',
      );
    }
    if (!canManage) {
      return const _MutedNote(
        'Only the business owner can change or cancel this subscription.',
      );
    }
    return AppSoftButton(
      label: _pastDue ? 'Fix payment in Google Play' : 'Manage subscription',
      icon: Icons.open_in_new_rounded,
      onPressed: () => _openPlayManage(context),
    );
  }

  /// Cancelling and changing payment method belong to Google, not to us — Play
  /// policy requires it and the merchant's card details never touch this app.
  Future<void> _openPlayManage(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = IapService.manageSubscriptionUri(productId: ownedProductId);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Couldn\'t open Google Play. Manage your subscription '
              'from the Play Store app under Payments & subscriptions.',
            ),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('[CurrentPlanCard] Error in _openPlayManage: $e\n$st');
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Couldn\'t open Google Play. Manage your subscription '
            'from the Play Store app under Payments & subscriptions.',
          ),
        ),
      );
    }
  }
}

/// Nudge for a tenant who can still move up — leads with what the next tier
/// actually unlocks rather than repeating the whole ladder.
class _UpgradeBanner extends StatelessWidget {
  final UpgradePitch pitch;
  final VoidCallback onTap;

  const _UpgradeBanner({required this.pitch, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decorative only — sits behind the copy and never intercepts taps.
          Positioned(
            right: -8,
            bottom: -14,
            child: Icon(
              Icons.rocket_launch_rounded,
              size: 96,
              color: AppColors.brandSoft,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pitch.title,
                  style: AppTextStyles.title(
                    context,
                  ).copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  // Keeps the copy clear of the illustration on narrow phones.
                  width: 260,
                  child: Text(
                    pitch.body,
                    style: AppTextStyles.caption(
                      context,
                    ).copyWith(color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
                const SizedBox(height: 14),
                AppSoftButton(
                  label: 'Upgrade',
                  showChevron: true,
                  onPressed: onTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MutedNote extends StatelessWidget {
  final String text;

  const _MutedNote(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        height: 1.4,
        color: AppColors.textSecondary,
      ),
    );
  }
}
