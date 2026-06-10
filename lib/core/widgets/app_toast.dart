import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

enum AppToastVariant { success, info, warning, error }

class _ToastEntry {
  final OverlayEntry entry;
  final Completer<void> completer;
  _ToastEntry(this.entry, this.completer);
}

/// Global overlay-based toast. Never blocks the UI — shown at the bottom of the
/// screen, auto-dismisses, and stacks when multiple toasts fire quickly.
///
/// Simple usage (success only):
/// ```dart
/// AppToast.show(context, 'Saved successfully');
/// ```
///
/// With variant + subtitle + actions:
/// ```dart
/// AppToast.show(
///   context,
///   'Something went wrong',
///   subtitle: 'Check your connection and try again.',
///   variant: AppToastVariant.error,
///   actions: [
///     AppToastAction(label: 'Retry', onTap: retry),
///     AppToastAction(label: 'Dismiss'),
///   ],
/// );
/// ```
class AppToast {
  AppToast._();

  static const _animDuration = Duration(milliseconds: 220);
  static const _defaultDuration = Duration(seconds: 3);

  /// Show a toast on the nearest [Overlay].
  static void show(
    BuildContext context,
    String title, {
    String? subtitle,
    AppToastVariant variant = AppToastVariant.success,
    Duration duration = _defaultDuration,
    List<AppToastAction> actions = const [],
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late _ToastEntry ref;
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        title: title,
        subtitle: subtitle,
        variant: variant,
        actions: actions,
        onDismiss: () {
          ref.completer.complete();
        },
      ),
    );

    final completer = Completer<void>();
    ref = _ToastEntry(entry, completer);

    overlay.insert(entry);

    // Auto-dismiss after [duration] + animation.
    Timer(duration, () {
      if (!completer.isCompleted) completer.complete();
    });

    completer.future.then((_) {
      // Let the exit animation finish before removing.
      Future.delayed(_animDuration, () {
        if (entry.mounted) entry.remove();
      });
    });
  }
}

class AppToastAction {
  final String label;
  final VoidCallback? onTap;
  const AppToastAction({required this.label, this.onTap});
}

// ── Internal widget ────────────────────────────────────────────────────────────

class _ToastWidget extends StatefulWidget {
  final String title;
  final String? subtitle;
  final AppToastVariant variant;
  final List<AppToastAction> actions;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.title,
    required this.subtitle,
    required this.variant,
    required this.actions,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: bottom + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: _ToastCard(
              title: widget.title,
              subtitle: widget.subtitle,
              variant: widget.variant,
              actions: widget.actions,
              onDismiss: _dismiss,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final AppToastVariant variant;
  final List<AppToastAction> actions;
  final VoidCallback onDismiss;

  const _ToastCard({
    required this.title,
    required this.subtitle,
    required this.variant,
    required this.actions,
    required this.onDismiss,
  });

  ({Color icon, Color iconBg, IconData iconData}) get _style {
    switch (variant) {
      case AppToastVariant.success:
        return (
          icon: AppColors.success,
          iconBg: AppColors.successSoft,
          iconData: Icons.check_circle_rounded,
        );
      case AppToastVariant.info:
        return (
          icon: AppColors.info,
          iconBg: AppColors.infoSoft,
          iconData: Icons.info_rounded,
        );
      case AppToastVariant.warning:
        return (
          icon: AppColors.warning,
          iconBg: AppColors.warningSoft,
          iconData: Icons.warning_amber_rounded,
        );
      case AppToastVariant.error:
        return (
          icon: AppColors.error,
          iconBg: AppColors.errorSoft,
          iconData: Icons.cancel_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A101828),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: s.iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(s.iconData, size: 18, color: s.icon),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: getOutfitStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: getOutfitStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: actions.map((a) {
                        final isFirst = actions.first == a;
                        return Padding(
                          padding: EdgeInsets.only(right: isFirst ? 12 : 0),
                          child: GestureDetector(
                            onTap: () {
                              a.onTap?.call();
                              onDismiss();
                            },
                            child: Text(
                              a.label,
                              style: getOutfitStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isFirst
                                    ? AppColors.brand
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            // Dismiss
            GestureDetector(
              onTap: onDismiss,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
