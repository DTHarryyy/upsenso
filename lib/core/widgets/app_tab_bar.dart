import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// Underline tab bar (brand-tinted active label with a sliding underline) so
/// every tabbed page in the app — Reports, Billing, Settings — reads with one
/// tab language.
///
/// Driven by an index + callback so it stays a drop-in for a manual body
/// switch (e.g. an [IndexedStack]); it owns a private [TabController] purely
/// to borrow Material's sliding indicator instead of hand-rolling one.
class AppTabBar extends StatefulWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const AppTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<AppTabBar> createState() => _AppTabBarState();
}

class _AppTabBarState extends State<AppTabBar>
    with SingleTickerProviderStateMixin {
  TabController? _controller;

  @override
  void initState() {
    super.initState();
    _rebuildController();
  }

  void _rebuildController() {
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    _controller = TabController(
      length: widget.tabs.length,
      initialIndex: _clampedIndex,
      vsync: this,
    )..addListener(_onControllerChanged);
  }

  int get _clampedIndex => widget.tabs.isEmpty
      ? 0
      : widget.selectedIndex.clamp(0, widget.tabs.length - 1);

  void _onControllerChanged() {
    final c = _controller!;
    // Fire once the selection settles, not on every animation frame, and never
    // echo back the value the parent already gave us (avoids a rebuild loop).
    if (c.indexIsChanging) return;
    if (c.index != widget.selectedIndex) widget.onTabSelected(c.index);
  }

  @override
  void didUpdateWidget(AppTabBar old) {
    super.didUpdateWidget(old);
    // Tab sets can change under us (e.g. a branch-count-driven tab) — rebuild
    // the controller when the count changes.
    if (old.tabs.length != widget.tabs.length) {
      _rebuildController();
    } else if (widget.selectedIndex != _controller!.index) {
      _controller!.index = _clampedIndex;
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) return const SizedBox.shrink();
    return TabBar(
      controller: _controller,
      tabs: widget.tabs.map((t) => Tab(text: t)).toList(),
      indicatorColor: AppColors.brand,
      indicatorWeight: 2.5,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: AppColors.brand,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: getOutfitStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      unselectedLabelStyle: getOutfitStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      dividerColor: Colors.transparent,
    );
  }
}
