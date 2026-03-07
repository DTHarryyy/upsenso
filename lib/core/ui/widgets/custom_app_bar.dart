import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/breakpoint.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  /// List of available branches for the dropdown
  final List<String> branches;

  /// Currently selected branch
  final String selectedBranch;

  /// Callback when branch is selected
  final ValueChanged<String>? onBranchChanged;

  /// Whether the app is online or not
  final bool isOnline;

  /// Number of pending syncs
  final int pendingSyncCount;

  /// User's full name
  final String userName;

  /// User's role/title
  final String userRole;

  /// User's email (optional for profile popup)
  final String? userEmail;

  /// User's business name (optional for profile popup)
  final String? businessName;

  /// User's avatar URL or initials
  final String? userAvatar;

  /// Number of unread notifications
  final int notificationCount;

  /// Callback when notification bell is tapped
  final VoidCallback? onNotificationTapped;

  /// Callback when user profile is tapped
  final VoidCallback? onProfileTapped;

  /// Callback when logout is tapped in profile popup
  final VoidCallback? onLogoutTapped;

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
    this.businessName,
    this.userAvatar,
    this.notificationCount = 0,
    this.onNotificationTapped,
    this.onProfileTapped,
    this.onLogoutTapped,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

class _CustomAppBarState extends State<CustomAppBar> {
  late String _selectedBranch;
  final GlobalKey _profileAnchorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedBranch = widget.selectedBranch;
  }

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              // ┌─ LEFT: Branches Dropdown
              Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedBranch,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedBranch = newValue;
                        });
                        widget.onBranchChanged?.call(newValue);
                      }
                    },
                    underline: SizedBox.shrink(),
                    icon: Icon(
                      Icons.unfold_more,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    items: widget.branches.map<DropdownMenuItem<String>>((
                      String branch,
                    ) {
                      return DropdownMenuItem<String>(
                        value: branch,
                        child: Text(
                          branch,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),

              // ┌─ CENTER: Status Indicators
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Online Status - Circle only on mobile when online
                    _StatusIndicator(
                      isOnline: widget.isOnline,
                      label: widget.isOnline ? 'Online' : 'Offline',
                    ),
                    const SizedBox(width: 16),

                    // Sync Status
                    if (widget.pendingSyncCount > 0)
                      _StatusIndicator(
                        isOnline: true,
                        label: widget.pendingSyncCount > 0
                            ? 'Syncing...'
                            : 'Synced',
                        isSyncing: widget.pendingSyncCount > 0,
                      )
                    else if (widget.isOnline)
                      _StatusIndicator(
                        isOnline: true,
                        label: 'Synced',
                        isSyncing: false,
                      ),
                  ],
                ),
              ),

              // ┌─ RIGHT: Notifications & Profile
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Notification Bell
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
                                size: 24,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        // Badge
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
                                  style: GoogleFonts.outfit(
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
                    const SizedBox(width: 16),

                    // User Profile
                    KeyedSubtree(
                      key: _profileAnchorKey,
                      child: _UserProfileSection(
                        userName: widget.userName,
                        userRole: widget.userRole,
                        userAvatar: widget.userAvatar,
                        onProfileTapped: _showProfileMenu,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showProfileMenu() async {
    if (widget.onProfileTapped == null && widget.onLogoutTapped == null) {
      return;
    }

    final anchorContext = _profileAnchorKey.currentContext;
    if (anchorContext == null) return;

    final anchorRender = anchorContext.findRenderObject();
    final overlayRender = Overlay.of(context).context.findRenderObject();
    if (anchorRender is! RenderBox || overlayRender is! RenderBox) return;

    final topLeft = anchorRender.localToGlobal(
      Offset.zero,
      ancestor: overlayRender,
    );
    final bottomRight = anchorRender.localToGlobal(
      anchorRender.size.bottomRight(Offset.zero),
      ancestor: overlayRender,
    );

    final position = RelativeRect.fromRect(
      Rect.fromPoints(topLeft, bottomRight),
      Offset.zero & overlayRender.size,
    );

    final selected = await showMenu<_ProfileMenuAction>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem<_ProfileMenuAction>(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.userName,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if ((widget.userEmail ?? '').isNotEmpty)
                  Text(
                    widget.userEmail!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Role: ${widget.userRole}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if ((widget.businessName ?? '').isNotEmpty)
                  Text(
                    'Business: ${widget.businessName}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.onProfileTapped != null) ...[
          const PopupMenuDivider(height: 1),
          PopupMenuItem<_ProfileMenuAction>(
            value: _ProfileMenuAction.viewProfile,
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Profile',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (widget.onLogoutTapped != null) ...[
          const PopupMenuDivider(height: 1),
          PopupMenuItem<_ProfileMenuAction>(
            value: _ProfileMenuAction.logout,
            child: Row(
              children: [
                const Icon(Icons.logout, size: 18, color: AppColors.error),
                const SizedBox(width: 8),
                Text(
                  'Logout',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    switch (selected) {
      case _ProfileMenuAction.viewProfile:
        widget.onProfileTapped?.call();
        break;
      case _ProfileMenuAction.logout:
        widget.onLogoutTapped?.call();
        break;
      case null:
        break;
    }
  }
}

enum _ProfileMenuAction { viewProfile, logout }

/// Status indicator widget for displaying online/offline and sync status
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

    // Check if mobile (screen width < 600)
    final isMobile = Breakpoints.isTablet(context) == false;
    final showLabel = label.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated indicator dot
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

        // Label - hide on mobile if online, show otherwise
        if (showLabel && (!isMobile || !isOnline))
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              label,
              style: GoogleFonts.outfit(
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

/// User profile section - responsive (avatar only on mobile, full on tablet+)
class _UserProfileSection extends StatelessWidget {
  final String userName;
  final String userRole;
  final String? userAvatar;
  final VoidCallback? onProfileTapped;

  const _UserProfileSection({
    required this.userName,
    required this.userRole,
    this.userAvatar,
    this.onProfileTapped,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = !Breakpoints.isTablet(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onProfileTapped,
        borderRadius: BorderRadius.circular(8),
        splashColor: AppColors.brand.withAlpha(30),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 4 : 8,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar - Always visible
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brand, width: 1.5),
                ),
                child: userAvatar != null && userAvatar!.startsWith('http')
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(userAvatar!, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(
                          _getInitials(userName),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
              ),

              // User Info & Arrow - Hidden on mobile
              if (!isMobile) ...[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      userRole,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.expand_more,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Generate initials from user name
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    final first = parts.first;
    final len = first.length > 1 ? 2 : 1;
    return first.substring(0, len).toUpperCase();
  }
}
