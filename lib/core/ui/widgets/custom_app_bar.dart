import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/ui/widgets/user_profile_section.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final List<String> branches;
  final String selectedBranch;
  final ValueChanged<String>? onBranchChanged;
  final bool isOnline;
  final int pendingSyncCount;
  final String userName;
  final String userRole;
  final String? userEmail;
  final String? userId;
  final String? businessName;
  final String? userAvatar;
  final int notificationCount;
  final VoidCallback? onNotificationTapped;
  final VoidCallback? onMenuTapped;
  final VoidCallback? onThemeToggleTapped;
  final bool showThemeToggle;
  final bool isDarkMode;

  const CustomAppBar({
    super.key,
    required this.branches,
    required this.selectedBranch,
    this.onBranchChanged,
    this.isOnline = true,
    this.pendingSyncCount = 0,
    required this.userName,
    required this.userRole,
    this.userEmail,
    this.userId,
    this.businessName,
    this.userAvatar,
    this.notificationCount = 0,
    this.onNotificationTapped,
    this.onMenuTapped,
    this.onThemeToggleTapped,
    this.showThemeToggle = true,
    this.isDarkMode = false,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    final isMobile = !Breakpoints.isTablet(context);

    return SafeArea(
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(color: AppColors.borderSoft, width: 1),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: 8,
          ),
          child: Row(
            children: [
              // Left: hamburger (mobile) or branch dropdown (desktop)
              if (isMobile)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onMenuTapped,
                    borderRadius: BorderRadius.circular(8),
                    splashColor: AppColors.brand.withAlpha(30),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.menu,
                        size: 22,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                _buildBranchDropdown(),

              if (isMobile) const SizedBox(width: 8),

              // Center: branch selector (mobile) or status pills (desktop)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (isMobile)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 150),
                            child: _buildCompactBranchSelector(),
                          ),
                        ),
                      )
                    else ...[
                      _StatusPill(
                        color: widget.isOnline
                            ? AppColors.synced
                            : AppColors.offline,
                        icon: widget.isOnline
                            ? Icons.wifi_rounded
                            : Icons.wifi_off_rounded,
                        label: widget.isOnline ? 'Online' : 'Offline',
                      ),
                      const SizedBox(width: 8),
                      if (widget.isOnline)
                        _StatusPill(
                          color: widget.pendingSyncCount > 0
                              ? AppColors.syncing
                              : AppColors.synced,
                          icon: widget.pendingSyncCount > 0
                              ? Icons.sync_rounded
                              : Icons.cloud_done_rounded,
                          label: widget.pendingSyncCount > 0
                              ? 'Syncing...'
                              : 'Synced',
                          isSyncing: widget.pendingSyncCount > 0,
                        ),
                    ],
                  ],
                ),
              ),

              // Mobile: compact status badges (always visible)
              if (isMobile) ...[
                _StatusPill(
                  color: widget.isOnline ? AppColors.synced : AppColors.offline,
                  icon: widget.isOnline
                      ? Icons.wifi_rounded
                      : Icons.wifi_off_rounded,
                  label: widget.isOnline ? 'Online' : 'Offline',
                  compact: true,
                ),
                const SizedBox(width: 4),
                if (widget.isOnline) ...[
                  _StatusPill(
                    color: widget.pendingSyncCount > 0
                        ? AppColors.syncing
                        : AppColors.synced,
                    icon: widget.pendingSyncCount > 0
                        ? Icons.sync_rounded
                        : Icons.cloud_done_rounded,
                    label: widget.pendingSyncCount > 0 ? 'Syncing' : 'Synced',
                    isSyncing: widget.pendingSyncCount > 0,
                    compact: true,
                  ),
                  const SizedBox(width: 4),
                ],
              ],

              // Right: theme toggle + notifications + avatar
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMobile && widget.showThemeToggle)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onThemeToggleTapped,
                        borderRadius: BorderRadius.circular(8),
                        splashColor: AppColors.brand.withAlpha(30),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            widget.isDarkMode
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            size: 22,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),

                  Stack(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onNotificationTapped,
                          borderRadius: BorderRadius.circular(8),
                          splashColor: AppColors.brand.withAlpha(30),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.notifications_outlined,
                              size: isMobile ? 22 : 24,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      if (widget.notificationCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                widget.notificationCount > 9
                                    ? '9+'
                                    : widget.notificationCount.toString(),
                                style: getOutfitStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textInverse,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: isMobile ? 4 : 12),

                  UserProfileSection(
                    userName: widget.userName,
                    userRole: widget.userRole,
                    userAvatar: widget.userAvatar,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranchDropdown() {
    return BlocBuilder<BranchCubit, BranchState>(
      builder: (context, branchState) {
        final selectedBranch =
            branchState.selectedBranch ?? widget.selectedBranch;
        final canSwitch = branchState.canSwitchBranches;
        final branches = branchState.availableBranches.isNotEmpty
            ? branchState.availableBranches
            : widget.branches;

        return DropdownButton<String>(
          value: selectedBranch,
          onChanged: widget.onBranchChanged != null && canSwitch
              ? (String? newValue) {
                  if (newValue != null) {
                    unawaited(
                      context.read<BranchCubit>().selectBranch(newValue),
                    );
                    widget.onBranchChanged?.call(newValue);
                  }
                }
              : null,
          underline: const SizedBox.shrink(),
          icon: Icon(
            Icons.unfold_more,
            size: 18,
            color: AppColors.textSecondary,
          ),
          items: branches.map<DropdownMenuItem<String>>((String branch) {
            return DropdownMenuItem<String>(
              value: branch,
              child: Text(
                branch,
                overflow: TextOverflow.ellipsis,
                style: getOutfitStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          style: getOutfitStyle(fontSize: 14, color: AppColors.textPrimary),
        );
      },
    );
  }

  Widget _buildCompactBranchSelector() {
    return BlocBuilder<BranchCubit, BranchState>(
      builder: (context, branchState) {
        final selectedBranch =
            branchState.selectedBranch ?? widget.selectedBranch;
        final canSwitch = branchState.canSwitchBranches;
        final branches = branchState.availableBranches.isNotEmpty
            ? branchState.availableBranches
            : widget.branches;

        return Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedBranch,
              onChanged: widget.onBranchChanged != null && canSwitch
                  ? (String? newValue) {
                      if (newValue != null) {
                        unawaited(
                          context.read<BranchCubit>().selectBranch(newValue),
                        );
                        widget.onBranchChanged?.call(newValue);
                      }
                    }
                  : null,
              icon: Icon(
                Icons.expand_more,
                size: 16,
                color: AppColors.textSecondary,
              ),
              selectedItemBuilder: (context) {
                return branches.map((branch) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      selectedBranch,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: getOutfitStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList();
              },
              items: branches.map<DropdownMenuItem<String>>((String branch) {
                return DropdownMenuItem<String>(
                  value: branch,
                  child: Text(
                    branch,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: getOutfitStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Status Pill — used for both connectivity and sync states
// ---------------------------------------------------------------------------

class _StatusPill extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String label;
  final bool isSyncing;

  /// compact = icon-only circle (used on mobile)
  final bool compact;

  const _StatusPill({
    required this.color,
    required this.icon,
    required this.label,
    this.isSyncing = false,
    this.compact = false,
  });

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isSyncing) _spin.repeat();
  }

  @override
  void didUpdateWidget(_StatusPill old) {
    super.didUpdateWidget(old);
    if (widget.isSyncing && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.isSyncing && _spin.isAnimating) {
      _spin.stop();
      _spin.reset();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Widget _icon(double size) {
    final icon = Icon(widget.icon, size: size, color: widget.color);
    if (!widget.isSyncing) return icon;
    return AnimatedBuilder(
      animation: _spin,
      builder: (_, child) =>
          Transform.rotate(angle: _spin.value * 2 * math.pi, child: child),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.color.withAlpha(20);
    final border = widget.color.withAlpha(45);

    // ── Compact (mobile): icon-only circle with tooltip ──────────────────────
    if (widget.compact) {
      return Tooltip(
        message: widget.label,
        preferBelow: true,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 1),
          ),
          child: Center(child: _icon(14)),
        ),
      );
    }

    // ── Full (desktop): rounded pill with icon + label ────────────────────────
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _icon(13),
          const SizedBox(width: 5),
          Text(
            widget.label,
            style: getOutfitStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}
