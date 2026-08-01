import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/branch/branch_cubit.dart';
import 'package:pos/core/branch/branch_state.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/upgrade_prompt.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';

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
                      // Sync status only — online/offline indicator removed.
                      Flexible(
                        child: _StatusPill(
                          color: widget.pendingSyncCount > 0
                              ? AppColors.syncing
                              : AppColors.synced,
                          icon: widget.pendingSyncCount > 0
                              ? Icons.sync_rounded
                              : Icons.cloud_done_rounded,
                          label: widget.pendingSyncCount > 0
                              ? 'Sync: ${widget.pendingSyncCount} pending'
                              : 'All synced',
                          isSyncing: widget.pendingSyncCount > 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Mobile: compact sync badge only — online indicator removed.
              if (isMobile && widget.pendingSyncCount > 0) ...[
                _StatusPill(
                  color: AppColors.syncing,
                  icon: Icons.sync_rounded,
                  label: 'Sync: ${widget.pendingSyncCount} pending',
                  isSyncing: true,
                  compact: true,
                ),
                const SizedBox(width: 4),
              ],

              // Right: theme toggle + notifications
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
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surface,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                widget.notificationCount > 9
                                    ? '9+'
                                    : widget.notificationCount.toString(),
                                style: getOutfitStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textInverse,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const String _addNewBranchValue = '__add_new_branch__';

  void _showAddBranchDialog(BuildContext context) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.add_business_rounded,
                color: AppColors.brand,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Add New Branch',
                style: getOutfitStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Branch Name *',
                      hintText: 'e.g. Downtown Branch',
                      prefixIcon: const Icon(Icons.store_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.borderSoft,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.brand,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Branch name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      hintText: 'e.g. 123 Main St',
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.borderSoft,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.brand,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      hintText: 'e.g. +63 912 345 6789',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.borderSoft,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.brand,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: getOutfitStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final authState = context.read<AuthBloc>().state;
                if (authState is! AuthAuthenticated) return;
                final businessId = authState.user.businessId;
                if (businessId == null || businessId.trim().isEmpty) return;

                Navigator.of(dialogContext).pop();

                final result = await context.read<BranchCubit>().addBranch(
                  businessId: businessId,
                  name: nameController.text,
                  location: addressController.text.isEmpty
                      ? null
                      : addressController.text,
                );

                // The result now says *why*, so we only sell an upgrade that
                // would actually have helped — no second cap query to guess.
                if (result.isCapped && context.mounted) {
                  await showUpgradePrompt(context, UpgradeMoment.branchCap);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: AppColors.textInverse,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Add Branch',
                style: getOutfitStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textInverse,
                ),
              ),
            ),
          ],
        );
      },
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

        return PopupMenuButton<String>(
          onSelected: (value) {
            if (value == _addNewBranchValue) {
              _showAddBranchDialog(context);
            } else if (context.read<BranchCubit>().isBranchNameLocked(value)) {
              // Held above the plan cap — sell the fix instead of pretending
              // the tap did nothing.
              unawaited(showUpgradePrompt(context, UpgradeMoment.branchCap));
            } else if (widget.onBranchChanged != null && canSwitch) {
              unawaited(context.read<BranchCubit>().selectBranch(value));
              widget.onBranchChanged?.call(value);
            }
          },
          enabled: canSwitch,
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) {
            final cubit = context.read<BranchCubit>();
            final items = <PopupMenuEntry<String>>[];
            for (final branch in branches) {
              final locked = cubit.isBranchNameLocked(branch);
              items.add(
                PopupMenuItem<String>(
                  value: branch,
                  child: Row(
                    children: [
                      Icon(
                        locked
                            ? Icons.lock_outline_rounded
                            : branch == BranchCubit.allBranchesLabel
                            ? Icons.all_inclusive_rounded
                            : Icons.store_rounded,
                        size: 18,
                        color: branch == selectedBranch
                            ? AppColors.brand
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          branch,
                          overflow: TextOverflow.ellipsis,
                          style: getOutfitStyle(
                            fontSize: 14,
                            fontWeight: branch == selectedBranch
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: locked
                                ? AppColors.textMuted
                                : branch == selectedBranch
                                ? AppColors.brand
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (locked)
                        Text(
                          'Locked',
                          style: getOutfitStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        )
                      else if (branch == selectedBranch)
                        const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AppColors.brand,
                        ),
                    ],
                  ),
                ),
              );
            }
            if (canSwitch) {
              items.add(const PopupMenuDivider());
              items.add(
                PopupMenuItem<String>(
                  value: _addNewBranchValue,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: AppColors.brand,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add New Branch',
                        style: getOutfitStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brand,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return items;
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.store_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  selectedBranch,
                  overflow: TextOverflow.ellipsis,
                  style: getOutfitStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (canSwitch) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.unfold_more,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ],
          ),
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

        return GestureDetector(
          onTap: canSwitch
              ? () {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final Offset offset = box.localToGlobal(Offset.zero);

                  final cubit = context.read<BranchCubit>();
                  final items = <PopupMenuEntry<String>>[];
                  for (final branch in branches) {
                    final locked = cubit.isBranchNameLocked(branch);
                    items.add(
                      PopupMenuItem<String>(
                        value: branch,
                        child: Row(
                          children: [
                            Icon(
                              locked
                                  ? Icons.lock_outline_rounded
                                  : branch == BranchCubit.allBranchesLabel
                                  ? Icons.all_inclusive_rounded
                                  : Icons.store_rounded,
                              size: 16,
                              color: branch == selectedBranch
                                  ? AppColors.brand
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                branch,
                                overflow: TextOverflow.ellipsis,
                                style: getOutfitStyle(
                                  fontSize: 13,
                                  fontWeight: branch == selectedBranch
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: locked
                                      ? AppColors.textMuted
                                      : branch == selectedBranch
                                      ? AppColors.brand
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (locked)
                              Text(
                                'Locked',
                                style: getOutfitStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              )
                            else if (branch == selectedBranch)
                              const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: AppColors.brand,
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (canSwitch) {
                    items.add(const PopupMenuDivider());
                    items.add(
                      PopupMenuItem<String>(
                        value: _addNewBranchValue,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: AppColors.brand,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add New Branch',
                              style: getOutfitStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  showMenu<String>(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      offset.dx,
                      offset.dy + box.size.height,
                      offset.dx + box.size.width,
                      0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    items: items,
                  ).then((value) {
                    if (value == null) return;
                    if (!context.mounted) return;
                    if (value == _addNewBranchValue) {
                      _showAddBranchDialog(context);
                    } else if (context
                        .read<BranchCubit>()
                        .isBranchNameLocked(value)) {
                      unawaited(
                        showUpgradePrompt(context, UpgradeMoment.branchCap),
                      );
                    } else {
                      unawaited(
                        context.read<BranchCubit>().selectBranch(value),
                      );
                      widget.onBranchChanged?.call(value);
                    }
                  });
                }
              : null,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
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
                ),
                if (canSwitch) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.expand_more,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ],
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
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: getOutfitStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
