import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// A themed, reusable search bar that follows the app's design system.
///
/// - Focused state shows the brand-colored border (via [appInputDeco])
/// - Shows an animated clear (×) button when text is non-empty
/// - [hint] defaults to `'Search...'`
/// - [onChanged] fires on every keystroke
class AppSearchBar extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final String hint;
  final TextEditingController? controller;

  const AppSearchBar({
    super.key,
    this.onChanged,
    this.hint = 'Search...',
    this.controller,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(() {
      final nonEmpty = _controller.text.isNotEmpty;
      if (nonEmpty != _hasText) setState(() => _hasText = nonEmpty);
    });
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    const radius = 12.0;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        style: getOutfitStyle(color: AppColors.textPrimary, fontSize: 14),

        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: getOutfitStyle(color: AppColors.textPrimary, fontSize: 14),
          filled: true,
          fillColor: AppColors.surface,
          isDense: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              IconlyLight.search,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),

          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                  splashRadius: 16,
                  onPressed: _clear,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: AppColors.borderSoft, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
          ),
        ),
      ),
    );
  }
}
