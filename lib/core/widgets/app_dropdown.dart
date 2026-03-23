import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// A single item entry for [AppDropdown].
class AppDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// A beautiful dropdown that opens a **floating overlay panel** directly below
/// the trigger button — does not push surrounding content down.
///
/// Optionally renders an "+ Add [addItemLabel]" action row at the top of the
/// list, separated by a divider from the selectable items.
///
/// ```dart
/// AppDropdown<String>(
///   value: _selectedId,
///   hint: 'Select category',
///   addItemLabel: 'Add Category',
///   onAddItem: _showAddCategorySheet,
///   items: categories
///       .map((c) => AppDropdownItem(value: c.id, label: c.name))
///       .toList(),
///   onChanged: (v) => setState(() => _selectedId = v),
/// )
/// ```
class AppDropdown<T> extends StatefulWidget {
  final T? value;
  final String? hint;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? errorText;

  /// Label for the inline "add new item" action shown at the top of the list.
  final String? addItemLabel;

  /// Called when the user taps the "add new item" action row.
  final VoidCallback? onAddItem;

  const AppDropdown({
    super.key,
    this.value,
    this.hint,
    required this.items,
    this.onChanged,
    this.errorText,
    this.addItemLabel,
    this.onAddItem,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _isOpen = false;

  AppDropdownItem<T>? get _selected =>
      widget.items.where((i) => i.value == widget.value).firstOrNull;

  @override
  void dispose() {
    if (_overlay != null) {
      final entry = _overlay!;
      _overlay = null;
      // Schedule removal after the current build/unmount cycle.
      // Calling OverlayEntry.remove() directly from dispose() triggers
      // Overlay.setState() while Flutter is still unmounting elements,
      // which can schedule a rebuild on an already-defunct element and
      // throw the '_lifecycleState != _ElementLifecycle.defunct' assertion.
      WidgetsBinding.instance.addPostFrameCallback((_) => entry.remove());
    }
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _closeOverlay();
    } else {
      _openOverlay();
    }
  }

  void _openOverlay() {
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final globalPos = box.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final spaceBelow = screenHeight - globalPos.dy - size.height;
    final openUpward = spaceBelow < 264; // 260 max panel + 4 gap

    _overlay = OverlayEntry(
      builder: (overlayCtx) => _OverlayDropdown<T>(
        link: _layerLink,
        triggerWidth: size.width,
        triggerHeight: size.height,
        openUpward: openUpward,
        items: widget.items,
        selectedValue: widget.value,
        addItemLabel: widget.addItemLabel,
        onAddItem: widget.onAddItem != null
            ? () {
                _closeOverlay();
                widget.onAddItem!();
              }
            : null,
        onSelected: (v) {
          _closeOverlay();
          widget.onChanged?.call(v);
        },
        onDismiss: _closeOverlay,
      ),
    );

    Overlay.of(context).insert(_overlay!);
    setState(() => _isOpen = true);
  }

  void _closeOverlay() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? AppColors.error
        : _isOpen
            ? AppColors.brand
            : Colors.transparent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  if (_selected?.icon != null) ...[
                    Icon(_selected!.icon, size: 16, color: AppColors.brand),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      _selected?.label ?? widget.hint ?? '',
                      style: getOutfitStyle(
                        color: _selected != null
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isOpen ? 0.5 : 0,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Error text
        if (hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              widget.errorText!,
              style: getOutfitStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Overlay widget
// ---------------------------------------------------------------------------

class _OverlayDropdown<T> extends StatelessWidget {
  final LayerLink link;
  final double triggerWidth;
  final double triggerHeight;
  final bool openUpward;
  final List<AppDropdownItem<T>> items;
  final T? selectedValue;
  final String? addItemLabel;
  final VoidCallback? onAddItem;
  final ValueChanged<T> onSelected;
  final VoidCallback onDismiss;

  const _OverlayDropdown({
    required this.link,
    required this.triggerWidth,
    required this.triggerHeight,
    required this.openUpward,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    required this.onDismiss,
    this.addItemLabel,
    this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full-screen tap barrier to dismiss
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),

        // Floating panel
        CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          targetAnchor:
              openUpward ? Alignment.topLeft : Alignment.bottomLeft,
          followerAnchor:
              openUpward ? Alignment.bottomLeft : Alignment.topLeft,
          offset: Offset(0, openUpward ? -4 : 4),
          child: SizedBox(
            width: triggerWidth,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 260),
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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Add item action ────────────────────────────
                        if (onAddItem != null) ...[
                          _AddItemRow(
                            label: addItemLabel ?? 'Add Item',
                            onTap: onAddItem!,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.borderSoft,
                          ),
                        ],

                        // ── Selectable items ───────────────────────────
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Text(
                              'No items yet',
                              style: getOutfitStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          ...items.asMap().entries.map((entry) {
                            final item = entry.value;
                            final isLast = entry.key == items.length - 1;
                            final isSelected = item.value == selectedValue;
                            return _DropdownOption(
                              item: item,
                              isSelected: isSelected,
                              isLast: isLast,
                              onTap: () => onSelected(item.value),
                            );
                          }),
                      ],
                    ),
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

// ---------------------------------------------------------------------------
// _AddItemRow
// ---------------------------------------------------------------------------

class _AddItemRow extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _AddItemRow({required this.label, required this.onTap});

  @override
  State<_AddItemRow> createState() => _AddItemRowState();
}

class _AddItemRowState extends State<_AddItemRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) { if (mounted) setState(() => _hovered = true); },
      onExit:  (_) { if (mounted) setState(() => _hovered = false); },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          color: _hovered
              ? AppColors.brandSoft
              : AppColors.brand.withValues(alpha: 0.03),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.brand,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: getOutfitStyle(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DropdownOption
// ---------------------------------------------------------------------------

class _DropdownOption<T> extends StatefulWidget {
  final AppDropdownItem<T> item;
  final bool isSelected;
  final bool isLast;
  final VoidCallback onTap;

  const _DropdownOption({
    required this.item,
    required this.isSelected,
    required this.isLast,
    required this.onTap,
  });

  @override
  State<_DropdownOption<T>> createState() => _DropdownOptionState<T>();
}

class _DropdownOptionState<T> extends State<_DropdownOption<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? AppColors.brandSoft
        : _hovered
            ? AppColors.inputFill
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) { if (mounted) setState(() => _hovered = true); },
      onExit:  (_) { if (mounted) setState(() => _hovered = false); },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            border: widget.isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: AppColors.borderSoft),
                  ),
          ),
          child: Row(
            children: [
              if (widget.item.icon != null) ...[
                Icon(
                  widget.item.icon,
                  size: 16,
                  color: widget.isSelected
                      ? AppColors.brand
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  widget.item.label,
                  style: getOutfitStyle(
                    color: widget.isSelected
                        ? AppColors.brand
                        : AppColors.textPrimary,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: widget.isSelected ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.brand,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
