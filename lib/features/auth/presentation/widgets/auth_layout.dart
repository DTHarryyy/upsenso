import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/app_strings.dart';
import 'package:pos/core/const/breakpoint.dart';

/// Shared two-column layout for all auth and onboarding pages.
///
/// Wide (≥600 px): gradient brand panel on the left, white form panel on the right.
/// Narrow: scrollable form with an optional back arrow at the top.
///
/// [onBack]    — shows a back control (arrow on mobile, "← Back" link on desktop).
/// [leftPanel] — override the default brand panel (e.g. for business setup).
class AuthLayout extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBack;
  final Widget? leftPanel;

  const AuthLayout({
    super.key,
    required this.child,
    this.onBack,
    this.leftPanel,
  });

  @override
  Widget build(BuildContext context) {
    if (!Breakpoints.isTablet(context)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onBack != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: IconButton(
                    icon: const Icon(
                      IconlyLight.arrow_left,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: onBack,
                  ),
                ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: leftPanel ?? const _DefaultBrandPanel(),
          ),
          Expanded(
            flex: 4,
            child: _FormPanel(onBack: onBack, child: child),
          ),
        ],
      ),
    );
  }
}

// ── Right panel ────────────────────────────────────────────────────────────

class _FormPanel extends StatelessWidget {
  final VoidCallback? onBack;
  final Widget child;

  const _FormPanel({this.onBack, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onBack != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 20, 40, 0),
                child: TextButton.icon(
                  onPressed: onBack,
                  icon: const Icon(IconlyLight.arrow_left, size: 16),
                  label: const Text('Back'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 40,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Default brand panel ────────────────────────────────────────────────────

class _DefaultBrandPanel extends StatelessWidget {
  const _DefaultBrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D4ED8), Color(0xFF557FF4), Color(0xFF7C9FF8)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Wordmark(),

              const Spacer(),

              // Headline
              const Text(
                'Manage your business\nin one platform.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sales, inventory, branches, and reports — everything you need to run smarter, even offline.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),

              // Feature pills
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _FeaturePill(
                    icon: IconlyLight.info_circle,
                    label: 'Works offline',
                  ),
                  _FeaturePill(
                    icon: Icons.sync_rounded,
                    label: 'Auto sync',
                  ),
                  _FeaturePill(
                    icon: IconlyBold.work,
                    label: 'Multi-branch',
                  ),
                  _FeaturePill(
                    icon: IconlyBold.chart,
                    label: 'Real-time reports',
                  ),
                ],
              ),

              const Spacer(),

              // Footer
              Text(
                '© 2025 ${AppStrings.appName}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "upsenso." in Albert Sans bold. [color] sets the main text; dot is always green.
class AuthWordmark extends StatelessWidget {
  final Color color;
  final double fontSize;

  const AuthWordmark({
    super.key,
    this.color = Colors.white,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.albertSans(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'upsenso', style: base),
          TextSpan(
            text: '.',
            style: base.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

// Private alias used inside the panels — keeps call-sites tidy.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) => const AuthWordmark();
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
