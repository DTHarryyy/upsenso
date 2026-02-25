import 'package:flutter/material.dart';
import 'status_type.dart';

class StatusBanner extends StatelessWidget {
  final StatusType type;
  final String title;
  final String? message;
  final VoidCallback? onAction;
  final String? actionText;
  final bool dense;

  const StatusBanner({
    super.key,
    required this.type,
    required this.title,
    this.message,
    this.onAction,
    this.actionText,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final _Style s = _styleFor(context, type);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(dense ? 12 : 14),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: s.border, width: 1),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: s.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(s.icon, color: s.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: s.text,
                  ),
                ),
                if (message != null && message!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: s.text.withValues(alpha: 0.85),
                      height: 1.3,
                    ),
                  ),
                ],
                if (onAction != null && actionText != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onAction,
                      icon: Icon(s.actionIcon, size: 18, color: s.text),
                      label: Text(
                        actionText!,
                        style: TextStyle(
                          color: s.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _Style {
  final Color bg;
  final Color border;
  final Color text;

  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  final IconData actionIcon;

  _Style({
    required this.bg,
    required this.border,
    required this.text,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.actionIcon,
  });
}

_Style _styleFor(BuildContext context, StatusType type) {
  // Uses Material colors only (no external icon packs needed)
  switch (type) {
    case StatusType.success:
      return _Style(
        bg: const Color(0xFFE9FBF0),
        border: const Color(0xFFB9F0CD),
        text: const Color(0xFF0F5132),
        icon: Icons.check_circle_rounded,
        iconBg: const Color(0xFFD2F6E1),
        iconColor: const Color(0xFF0F5132),
        actionIcon: Icons.arrow_forward_rounded,
      );
    case StatusType.info:
      return _Style(
        bg: const Color(0xFFEAF3FF),
        border: const Color(0xFFBFD9FF),
        text: const Color(0xFF0B3B80),
        icon: Icons.info_rounded,
        iconBg: const Color(0xFFD7E9FF),
        iconColor: const Color(0xFF0B3B80),
        actionIcon: Icons.open_in_new_rounded,
      );
    case StatusType.warning:
      return _Style(
        bg: const Color(0xFFFFF7E6),
        border: const Color(0xFFFFE0A6),
        text: const Color(0xFF7A4B00),
        icon: Icons.warning_rounded,
        iconBg: const Color(0xFFFFE8BD),
        iconColor: const Color(0xFF7A4B00),
        actionIcon: Icons.refresh_rounded,
      );
    case StatusType.error:
      return _Style(
        bg: const Color(0xFFFFECEB),
        border: const Color(0xFFFFC7C2),
        text: const Color(0xFF842029),
        icon: Icons.error_rounded,
        iconBg: const Color(0xFFFFD7D4),
        iconColor: const Color(0xFF842029),
        actionIcon: Icons.refresh_rounded,
      );
  }
}
