import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'status_type.dart';

class StatusSnack {
  static void show(
    BuildContext context, {
    required StatusType type,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final s = _snackStyle(type);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        duration: duration,
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    if (title != null && title.trim().isNotEmpty)
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: s.text,
                        ),
                      ),
                    Text(
                      message,
                      style: TextStyle(color: s.text.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        bg: const Color(0xFF842029),
        border: const Color(0xFF842029),
        text: Colors.white,
        icon: Icons.error_rounded,
        iconColor: Colors.white,
      );
  }
}
