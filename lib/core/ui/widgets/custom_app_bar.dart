import 'dart:async';

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
  void initState() {
    super.initState();
  }

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

              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (isMobile)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 170),
                            child: _buildCompactBranchSelector(),
                          ),
                        ),
                      )
                    else ...[
                      _StatusIndicator(
                        isOnline: widget.isOnline,
                        label: widget.isOnline ? 'Online' : 'Offline',
                      ),
                      const SizedBox(width: 16),
                      if (widget.pendingSyncCount > 0)
                        _StatusIndicator(
                          isOnline: true,
                          label: 'Syncing...',
                          isSyncing: true,
                        )
                      else if (widget.isOnline)
                        _StatusIndicator(
                          isOnline: true,
                          label: 'Synced',
                          isSyncing: false,
                        ),
                    ],
                  ],
                ),
              ),

              if (isMobile && (!widget.isOnline || widget.pendingSyncCount > 0))
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _StatusIndicator(
                    isOnline: widget.isOnline,
                    label: widget.pendingSyncCount > 0
                        ? 'Syncing...'
                        : (widget.isOnline ? 'Online' : 'Offline'),
                    isSyncing: widget.pendingSyncCount > 0,
                  ),
                ),

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
        // Use branches from BranchCubit state, fallback to widget props
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
        // Use branches from BranchCubit state, fallback to widget props
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

class _StatusIndicator extends StatelessWidget {
  final bool isOnline;
  final String label;
  final bool isSyncing;

  const _StatusIndicator({
    required this.isOnline,
    required this.label,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isSyncing
        ? AppColors.syncing
        : (isOnline ? AppColors.success : AppColors.offline);

    final isMobile = Breakpoints.isTablet(context) == false;
    final showLabel = label.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSyncing)
          SizedBox(
            width: 10,
            height: 10,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withValues(alpha: 0.7),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),

        if (showLabel && (!isMobile || !isOnline))
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              label,
              style: getOutfitStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ),
      ],
    );
  }
}
