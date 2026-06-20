import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/utils/business_clock.dart';

// ── Quick-select presets ─────────────────────────────────────────────────────

enum _Preset {
  today('Today'),
  yesterday('Yesterday'),
  last7Days('Last 7 days'),
  last30Days('Last 30 days'),
  thisMonth('This month'),
  lastMonth('Last month'),
  custom('Custom range…');

  const _Preset(this.label);
  final String label;

  DateTimeRange get range {
    final now = BusinessClock.now();
    final today = BusinessClock.today();
    return switch (this) {
      _Preset.today => DateTimeRange(start: today, end: today),
      _Preset.yesterday => DateTimeRange(
        start: today.subtract(const Duration(days: 1)),
        end: today.subtract(const Duration(days: 1)),
      ),
      _Preset.last7Days => DateTimeRange(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      ),
      _Preset.last30Days => DateTimeRange(
        start: today.subtract(const Duration(days: 29)),
        end: today,
      ),
      _Preset.thisMonth => DateTimeRange(
        start: DateTime(now.year, now.month),
        end: today,
      ),
      _Preset.lastMonth => DateTimeRange(
        start: DateTime(now.year, now.month - 1),
        end: DateTime(now.year, now.month, 0),
      ),
      _Preset.custom => DateTimeRange(start: today, end: today),
    };
  }
}

// ── Widget ───────────────────────────────────────────────────────────────────

class AppDateRangePicker extends StatefulWidget {
  final DateTimeRange? value;
  final ValueChanged<DateTimeRange?> onChanged;
  final String placeholder;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const AppDateRangePicker({
    super.key,
    required this.onChanged,
    this.value,
    this.placeholder = 'Date Range',
    this.firstDate,
    this.lastDate,
  });

  @override
  State<AppDateRangePicker> createState() => _AppDateRangePickerState();
}

class _AppDateRangePickerState extends State<AppDateRangePicker> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _isOpen = false;

  @override
  void dispose() {
    if (_overlay != null) {
      final entry = _overlay!;
      _overlay = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => entry.remove());
    }
    super.dispose();
  }

  void _toggle() => _isOpen ? _close() : _open();

  void _open() {
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final globalPos = box.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final spaceBelow = screenHeight - globalPos.dy - size.height;
    final openUpward = spaceBelow < 340;

    _overlay = OverlayEntry(
      builder: (_) => _PresetOverlay(
        link: _layerLink,
        triggerWidth: size.width,
        triggerHeight: size.height,
        openUpward: openUpward,
        currentValue: widget.value,
        onDismiss: _close,
        onSelected: (range) {
          _close();
          widget.onChanged(range);
        },
        onPickCustom: () async {
          _close();
          await Future<void>.delayed(const Duration(milliseconds: 60));
          if (!mounted) return;
          final picked = await showDateRangePicker(
            context: context,
            firstDate: widget.firstDate ?? DateTime(2020),
            lastDate: widget.lastDate ?? DateTime.now(),
            initialDateRange: widget.value,
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.brand,
                  onPrimary: AppColors.textInverse,
                  surface: AppColors.surface,
                  onSurface: AppColors.textPrimary,
                  secondaryContainer: AppColors.brandSoft,
                  onSecondaryContainer: AppColors.brand,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(foregroundColor: AppColors.brand),
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) widget.onChanged(picked);
        },
      ),
    );

    Overlay.of(context).insert(_overlay!);
    setState(() => _isOpen = true);
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _isOpen = false);
  }

  String get _label {
    if (widget.value == null) return widget.placeholder;
    final s = widget.value!.start;
    final e = widget.value!.end;
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final sameDay = s.year == e.year && s.month == e.month && s.day == e.day;
    return sameDay ? fmt(s) : '${fmt(s)} – ${fmt(e)}';
  }

  bool get _hasValue => widget.value != null;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: _hasValue ? AppColors.brandSoft : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isOpen
                  ? AppColors.brand
                  : _hasValue
                  ? AppColors.brand
                  : AppColors.borderSoft,
            ),
          ),
          child: Row(
            children: [
              Icon(
                IconlyLight.calendar,
                size: 16,
                color: _hasValue ? AppColors.brand : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _label,
                  style: getOutfitStyle(
                    fontSize: 13,
                    color: _hasValue ? AppColors.brand : AppColors.textMuted,
                    fontWeight: _hasValue ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_hasValue)
                GestureDetector(
                  onTap: () => widget.onChanged(null),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      IconlyLight.close_square,
                      size: 14,
                      color: AppColors.brand,
                    ),
                  ),
                )
              else
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _isOpen ? 0.5 : 0,
                  child: const Icon(
                    IconlyLight.arrow_down_2,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Overlay panel ────────────────────────────────────────────────────────────

class _PresetOverlay extends StatelessWidget {
  final LayerLink link;
  final double triggerWidth;
  final double triggerHeight;
  final bool openUpward;
  final DateTimeRange? currentValue;
  final VoidCallback onDismiss;
  final ValueChanged<DateTimeRange> onSelected;
  final VoidCallback onPickCustom;

  const _PresetOverlay({
    required this.link,
    required this.triggerWidth,
    required this.triggerHeight,
    required this.openUpward,
    required this.currentValue,
    required this.onDismiss,
    required this.onSelected,
    required this.onPickCustom,
  });

  _Preset? _activePreset() {
    if (currentValue == null) return null;
    final s = currentValue!.start;
    final e = currentValue!.end;
    for (final p in _Preset.values) {
      if (p == _Preset.custom) continue;
      final r = p.range;
      if (s.year == r.start.year &&
          s.month == r.start.month &&
          s.day == r.start.day &&
          e.year == r.end.year &&
          e.month == r.end.month &&
          e.day == r.end.day) {
        return p;
      }
    }
    return _Preset.custom;
  }

  @override
  Widget build(BuildContext context) {
    final active = _activePreset();
    final panelWidth = triggerWidth < 220 ? 220.0 : triggerWidth;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          targetAnchor: openUpward ? Alignment.topLeft : Alignment.bottomLeft,
          followerAnchor: openUpward ? Alignment.bottomLeft : Alignment.topLeft,
          offset: Offset(0, openUpward ? -4 : 4),
          child: SizedBox(
            width: panelWidth,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.brand, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._Preset.values
                          .where((p) => p != _Preset.custom)
                          .map(
                            (p) => _PresetTile(
                              label: p.label,
                              isActive: active == p,
                              onTap: () => onSelected(p.range),
                            ),
                          ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.borderSoft,
                      ),
                      _PresetTile(
                        label: _Preset.custom.label,
                        isActive: active == _Preset.custom,
                        onTap: onPickCustom,
                        trailingIcon: Icons.tune_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PresetTile extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  const _PresetTile({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isActive ? AppColors.brandSoft.withValues(alpha: 0.6) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: getOutfitStyle(
                  fontSize: 14,
                  color: isActive ? AppColors.brand : AppColors.textPrimary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isActive && trailingIcon == null)
              const Icon(Icons.check_rounded, size: 16, color: AppColors.brand),
            if (trailingIcon != null)
              Icon(trailingIcon, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
