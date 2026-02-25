import 'package:flutter/material.dart';
import 'status_type.dart';

class StatusPage extends StatelessWidget {
  final StatusType type;
  final String title;
  final String message;
  final String? primaryText;
  final VoidCallback? onPrimary;
  final String? secondaryText;
  final VoidCallback? onSecondary;

  const StatusPage({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.primaryText,
    this.onPrimary,
    this.secondaryText,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final s = _pageStyle(type);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: s.iconBg,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(s.icon, size: 34, color: s.iconColor),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black.withValues(alpha: 0.7),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (primaryText != null && onPrimary != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onPrimary,
                        child: Text(primaryText!),
                      ),
                    ),
                  if (secondaryText != null && onSecondary != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onSecondary,
                        child: Text(secondaryText!),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageStyle {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  _PageStyle({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}

_PageStyle _pageStyle(StatusType type) {
  switch (type) {
    case StatusType.success:
      return _PageStyle(
        icon: Icons.check_circle_rounded,
        iconBg: const Color(0xFFE9FBF0),
        iconColor: const Color(0xFF0F5132),
      );
    case StatusType.info:
      return _PageStyle(
        icon: Icons.info_rounded,
        iconBg: const Color(0xFFEAF3FF),
        iconColor: const Color(0xFF0B3B80),
      );
    case StatusType.warning:
      return _PageStyle(
        icon: Icons.warning_rounded,
        iconBg: const Color(0xFFFFF7E6),
        iconColor: const Color(0xFF7A4B00),
      );
    case StatusType.error:
      return _PageStyle(
        icon: Icons.error_rounded,
        iconBg: const Color(0xFFFFECEB),
        iconColor: const Color(0xFF842029),
      );
  }
}
