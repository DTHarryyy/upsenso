import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'status_type.dart';

class StatusSnack {
  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required StatusType type,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Dismiss any toast already on screen.
    _current?.remove();
    _current = null;

    if (!context.mounted) return;

    final overlay = Overlay.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final toastWidth = screenWidth > 600 ? 420.0 : screenWidth - 32.0;
    final topInset = MediaQuery.paddingOf(context).top + 16;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopToast(
        type: type,
        title: title,
        message: message,
        duration: duration,
        width: toastWidth,
        topInset: topInset,
        onDismiss: () {
          entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );

    _current = entry;
    overlay.insert(entry);
  }
}

// ── Animated top toast ─────────────────────────────────────────────────────

class _TopToast extends StatefulWidget {
  final StatusType type;
  final String? title;
  final String message;
  final Duration duration;
  final double width;
  final double topInset;
  final VoidCallback onDismiss;

  const _TopToast({
    required this.type,
    required this.title,
    required this.message,
    required this.duration,
    required this.width,
    required this.topInset,
    required this.onDismiss,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _ctrl.forward();
    Future.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _snackStyle(widget.type);

    return Positioned(
      top: widget.topInset,
      left: 0,
      right: 0,
      child: Center(
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: GestureDetector(
              onTap: _dismiss,
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: widget.width,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: s.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: s.border),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                          color: Colors.black.withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(s.icon, color: s.iconColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.title != null &&
                                  widget.title!.trim().isNotEmpty)
                                Text(
                                  widget.title!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: s.text,
                                  ),
                                ),
                              Text(
                                widget.message,
                                style: TextStyle(
                                  color: s.text.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Style helpers ──────────────────────────────────────────────────────────

class _SnackStyle {
  final Color bg;
  final Color border;
  final Color text;
  final IconData icon;
  final Color iconColor;

  _SnackStyle({
    required this.bg,
    required this.border,
    required this.text,
    required this.icon,
    required this.iconColor,
  });
}

_SnackStyle _snackStyle(StatusType type) {
  switch (type) {
    case StatusType.success:
      return _SnackStyle(
        bg: AppColors.success,
        border: const Color.fromARGB(222, 34, 197, 94),
        text: Colors.white,
        icon: Icons.check_circle_rounded,
        iconColor: Colors.white,
      );
    case StatusType.info:
      return _SnackStyle(
        bg: const Color(0xFF0B3B80),
        border: const Color(0xFF0B3B80),
        text: Colors.white,
        icon: Icons.info_rounded,
        iconColor: Colors.white,
      );
    case StatusType.warning:
      return _SnackStyle(
        bg: const Color(0xFF7A4B00),
        border: const Color(0xFF7A4B00),
        text: Colors.white,
        icon: Icons.warning_rounded,
        iconColor: Colors.white,
      );
    case StatusType.error:
      return _SnackStyle(
        bg: AppColors.error,
        border: AppColors.error.withValues(alpha: 0.2),
        text: Colors.white,
        icon: Icons.error_rounded,
        iconColor: Colors.white,
      );
  }
}
