import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_search_bar.dart';

/// A single item entry for [AppDropdown].
class AppDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const AppDropdownItem({required this.value, required this.label, this.icon});
}

/// A dropdown that opens a floating overlay panel and integrates with [Form]
/// validation via the [validator] parameter — works just like [TextFormField].
///
/// ```dart
/// AppDropdown<String>(
///   value: _selectedId,
///   hint: 'Select category',
///   validator: (v) => v == null ? 'Required' : null,
///   addItemLabel: 'Add Category',
///   onAddItem: _showAddCategorySheet,
///   items: categories
///       .map((c) => AppDropdownItem(value: c.id, label: c.name))
///       .toList(),
///   onChanged: (v) => setState(() => _selectedId = v),
/// )
/// ```
class AppDropdown<T> extends FormField<T> {
  final String? hint;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool dense;

  /// Label for the inline "add new item" action shown at the top of the list.
  final String? addItemLabel;

  /// Called when the user taps the "add new item" action row.
  final VoidCallback? onAddItem;

  /// Shows a search field pinned atop the option list that filters items by
  /// label — use for lists too long to scan, e.g. audit log action types.
  final bool searchable;
  final String searchHint;

  AppDropdown({
    super.key,
    T? value,
    this.hint,
    required this.items,
    this.onChanged,
    this.dense = false,
    this.addItemLabel,
    this.onAddItem,
    this.searchable = false,
    this.searchHint = 'Search...',
    super.validator,
    super.autovalidateMode = AutovalidateMode.disabled,
  }) : super(
         initialValue: value,
         builder: (field) => (field as _AppDropdownState<T>)._buildWidget(),
       );

  @override
  FormFieldState<T> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends FormFieldState<T> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _isOpen = false;

  AppDropdown<T> get _w => widget as AppDropdown<T>;

  AppDropdownItem<T>? get _selected =>
      _w.items.where((i) => i.value == value).firstOrNull;

  @override
  void didUpdateWidget(covariant AppDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep FormField's internal value in sync when the parent rebuilds
    // with a new value (e.g. after adding a new category).
    if (oldWidget.initialValue != widget.initialValue) {
      setValue(widget.initialValue);
    }
  }

  @override
  void dispose() {
    if (_overlay != null) {
      final entry = _overlay!;
      _overlay = null;
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
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final spaceBelow = screenHeight - globalPos.dy - size.height;
    // A search field adds its own row above the option list, so a searchable
    // panel needs more headroom before it's worth flipping upward.
    final openUpward = spaceBelow < (_w.searchable ? 320 : 264);

    // Filter rows can squeeze the trigger down to a third of the screen —
    // don't force option labels to wrap to match it. Grow the panel to a
    // comfortable minimum, but stop short of running off the screen edge.
    const minPanelWidth = 200.0;
    const screenMargin = 16.0;
    final maxAvailableWidth = screenSize.width - globalPos.dx - screenMargin;
    final panelWidth = math.min(
      math.max(size.width, minPanelWidth),
      math.max(size.width, maxAvailableWidth),
    );

    _overlay = OverlayEntry(
      builder: (overlayCtx) => _OverlayDropdown<T>(
        link: _layerLink,
        triggerWidth: size.width,
        panelWidth: panelWidth,
        triggerHeight: size.height,
        openUpward: openUpward,
        items: _w.items,
        selectedValue: value,
        addItemLabel: _w.addItemLabel,
        searchable: _w.searchable,
        searchHint: _w.searchHint,
        onAddItem: _w.onAddItem != null
            ? () {
                _closeOverlay();
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _w.onAddItem?.call(),
                );
              }
            : null,
        onSelected: (v) {
          _closeOverlay();
          didChange(v); // updates FormField value + triggers validation
          _w.onChanged?.call(v);
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

  Widget _buildWidget() {
    final displayError = errorText; // from FormFieldState (validator result)
    final hasError = displayError != null;
    // Border only surfaces for error/focus states; otherwise the trigger is
    // a flat, borderless chip that relies on shadow for separation.
    final border = hasError
        ? Border.all(color: AppColors.error, width: 1)
        : _isOpen
        ? Border.all(color: AppColors.brand, width: 1)
        : null;
    // Dense dropdowns are filter controls — the hint ("All X") is itself a
    // meaningful selection, not an unfilled required field, so it reads as
    // primary text rather than the muted placeholder color forms use.
    final textColor = _w.dense
        ? AppColors.textPrimary
        : (_selected != null ? AppColors.textPrimary : AppColors.textMuted);

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
              padding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: _w.dense ? 12 : 14,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: border,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_selected?.icon != null) ...[
                    Icon(_selected!.icon, size: 16, color: AppColors.brand),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      _selected?.label ?? _w.hint ?? '',
                      style: getOutfitStyle(
                        fontSize: _w.dense ? 13 : 14,
                        fontWeight: _w.dense
                            ? FontWeight.w500
                            : FontWeight.normal,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isOpen ? 0.5 : 0,
                    child: const Icon(
                      IconlyLight.arrow_down_2,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              displayError,
              style: getOutfitStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}

class _OverlayDropdown<T> extends StatefulWidget {
  final LayerLink link;
  final double triggerWidth;
  final double panelWidth;
  final double triggerHeight;
  final bool openUpward;
  final List<AppDropdownItem<T>> items;
  final T? selectedValue;
  final String? addItemLabel;
  final VoidCallback? onAddItem;
  final ValueChanged<T> onSelected;
  final VoidCallback onDismiss;
  final bool searchable;
  final String searchHint;

  const _OverlayDropdown({
    required this.link,
    required this.triggerWidth,
    required this.panelWidth,
    required this.triggerHeight,
    required this.openUpward,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    required this.onDismiss,
    this.addItemLabel,
    this.onAddItem,
    this.searchable = false,
    this.searchHint = 'Search...',
  });

  @override
  State<_OverlayDropdown<T>> createState() => _OverlayDropdownState<T>();
}

class _OverlayDropdownState<T> extends State<_OverlayDropdown<T>> {
  String _query = '';

  List<AppDropdownItem<T>> get _filteredItems {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((i) => i.label.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;

    return Stack(
      children: [
        // Full-screen tap barrier to dismiss
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),

        // Floating panel
        CompositedTransformFollower(
          link: widget.link,
          showWhenUnlinked: false,
          targetAnchor: widget.openUpward
              ? Alignment.topLeft
              : Alignment.bottomLeft,
          followerAnchor: widget.openUpward
              ? Alignment.bottomLeft
              : Alignment.topLeft,
          offset: Offset(0, widget.openUpward ? -4 : 4),
          child: SizedBox(
            width: widget.panelWidth,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Search field ──────────────────────────────────
                      if (widget.searchable) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                          child: AppSearchBar(
                            hint: widget.searchHint,
                            onChanged: (v) => setState(() => _query = v),
                          ),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSoft,
                        ),
                      ],

                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 260),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── Add item action ──────────────────────
                              if (widget.onAddItem != null) ...[
                                _AddItemRow(
                                  label: widget.addItemLabel ?? 'Add Item',
                                  onTap: widget.onAddItem!,
                                ),
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: AppColors.borderSoft,
                                ),
                              ],

                              // ── Selectable items ─────────────────────
                              if (filteredItems.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  child: Text(
                                    widget.items.isEmpty
                                        ? 'No items yet'
                                        : 'No matches found',
                                    style: getOutfitStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              else
                                ...filteredItems.map((item) {
                                  final isSelected =
                                      item.value == widget.selectedValue;
                                  return _DropdownOption(
                                    item: item,
                                    isSelected: isSelected,
                                    onTap: () => widget.onSelected(item.value),
                                  );
                                }),
                            ],
                          ),
                        ),
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
      onEnter: (_) {
        if (mounted) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _hovered = false);
      },
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
                  IconlyBold.plus,
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

class _DropdownOption<T> extends StatefulWidget {
  final AppDropdownItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;

  const _DropdownOption({
    required this.item,
    required this.isSelected,
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
      onEnter: (_) {
        if (mounted) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _hovered = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(color: bg),
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
                  Icons.check,
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
