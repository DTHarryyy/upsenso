import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// A single node in an [AppTimeline].
///
/// [done] controls the filled vs. hollow dot so a timeline can show both
/// completed history and pending/future steps in one list.
class TimelineEvent {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final String? time;
  final bool done;

  const TimelineEvent({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.time,
    this.done = true,
  });
}

/// Vertical activity timeline with a connecting rail between nodes.
///
/// Reusable for PO lifecycle, supplier activity, audit history, shifts, etc.
/// so event histories render identically across the app.
class AppTimeline extends StatelessWidget {
  final List<TimelineEvent> events;

  const AppTimeline({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          _Node(event: events[i], isLast: i == events.length - 1),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;

  const _Node({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: event.done
                      ? event.color.withAlpha(22)
                      : AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  event.icon,
                  size: 14,
                  color: event.done ? event.color : AppColors.textMuted,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    // Tint the rail under a completed node so the lifecycle
                    // reads as one continuous flow; pending steps stay grey.
                    color: event.done
                        ? event.color.withAlpha(90)
                        : AppColors.borderSoft,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: getOutfitStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: event.done
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (event.time != null)
                        Text(
                          event.time!,
                          style: getOutfitStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                  if (event.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.subtitle!,
                      style: getOutfitStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
