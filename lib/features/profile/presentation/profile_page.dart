import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/errors/app_error_mapper.dart';
import 'package:pos/core/services/image_compressor.dart';
import 'package:pos/core/const/breakpoint.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/widgets/app_field_label.dart';
import 'package:pos/core/widgets/app_input_decoration.dart';
import 'package:pos/core/widgets/app_toast.dart';
import 'package:pos/core/widgets/dashboard_card.dart';
import 'package:pos/core/widgets/user_avatar.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';
import 'package:pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_event.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        return _ProfileView(user: user);
      },
    );
  }
}

class _ProfileView extends StatefulWidget {
  final AppUser? user;
  const _ProfileView({required this.user});

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?.fullName ?? '');
    _nameCtrl.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final isDirty =
        _nameCtrl.text.trim() != (widget.user?.fullName ?? '').trim();
    if (isDirty != _dirty) setState(() => _dirty = isDirty);
  }

  @override
  void didUpdateWidget(_ProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user?.fullName != widget.user?.fullName) {
      _nameCtrl.text = widget.user?.fullName ?? '';
      setState(() => _dirty = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final newName = _nameCtrl.text.trim();
    setState(() => _saving = true);
    try {
      final updated = await sl<AuthRepository>().updateProfile(
        fullName: newName,
      );
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthUserContextUpdated(updated));
      setState(() {
        _saving = false;
        _dirty = false;
      });
      AppToast.show(context, 'Profile updated');
    } catch (e, st) {
      debugPrint('[ProfilePage] Error in _save: $e\n$st');
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.show(
        context,
        'Failed to update',
        subtitle: AppErrorMapper.message(e),
        variant: AppToastVariant.error,
      );
    }
  }

  static const _maxAvatarBytes = 5 * 1024 * 1024; // 5 MB

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final raw = await picked.readAsBytes();
    // Avatars are photos and render circular — force small JPEG, drop alpha.
    final compressed = await ImageCompressor.compress(
      raw,
      maxDimension: 512,
      preserveAlpha: false,
    );
    if (!mounted) return;
    final bytes = compressed.bytes;
    if (bytes.length > _maxAvatarBytes) {
      if (!mounted) return;
      AppToast.show(
        context,
        'Image too large',
        subtitle: 'Maximum size is 5 MB.',
        variant: AppToastVariant.error,
      );
      return;
    }
    final userId = widget.user?.id;
    if (userId == null) return;
    setState(() => _saving = true);
    try {
      final updated = await sl<AuthRepository>().uploadAvatar(userId, bytes);
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthUserContextUpdated(updated));
    } catch (e, st) {
      debugPrint('[ProfilePage] Error in avatar upload: $e\n$st');
      if (mounted) {
        AppToast.show(
          context,
          'Upload failed',
          subtitle: AppErrorMapper.message(e),
          variant: AppToastVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final isWide = Breakpoints.isTablet(context);
    if (isWide) {
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        builder: (_) => const _ChangePasswordDialog(),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _ChangePasswordSheet(),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log out?',
          style: getOutfitStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to log out from this account?',
          style: getOutfitStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: getOutfitStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'Log out',
              style: getOutfitStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      context.read<AuthBloc>().add(AuthLogoutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'My Profile',
          style: getOutfitStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_dirty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Save',
                        style: getOutfitStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ──────────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    _saving
                        ? const SizedBox(
                            width: 84,
                            height: 84,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.brand,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : UserAvatar(
                            avatarUrl: user?.avatarUrl,
                            name: user?.fullName,
                            email: user?.email,
                            radius: 42,
                            onTap: _pickAndUploadAvatar,
                            showEditBadge: true,
                          ),
                    const SizedBox(height: 12),
                    Text(
                      user?.fullName ?? user?.email ?? 'User',
                      style: getOutfitStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (user?.roleName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandSoft,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          displayRoleName(user!.roleName) ?? '',
                          style: getOutfitStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Personal Info ─────────────────────────────────────────
              Text(
                'Personal Info',
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              DashboardCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppFieldLabel('Full Name'),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: appInputDeco('Enter your full name'),
                      style: getOutfitStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name cannot be empty'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    AppFieldLabel('Email'),
                    _ReadOnlyField(
                      value: user?.email ?? '—',
                      icon: Icons.lock_outline_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Work Info ─────────────────────────────────────────────
              Text(
                'Work Info',
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              DashboardCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Role',
                      value:
                          displayRoleName(user?.roleName) ??
                          user?.roleId ??
                          '—',
                    ),
                    const Divider(height: 20, color: AppColors.borderSoft),
                    _InfoRow(
                      icon: Icons.business_outlined,
                      label: 'Business',
                      value: user?.businessName ?? '—',
                    ),
                    const Divider(height: 20, color: AppColors.borderSoft),
                    _InfoRow(
                      icon: Icons.store_outlined,
                      label: 'Branch',
                      value: user?.branchName ?? '—',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Security ──────────────────────────────────────────────
              Text(
                'Security',
                style: getOutfitStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              DashboardCard(
                padding: EdgeInsets.zero,
                child: _ActionRow(
                  icon: Icons.lock_reset_rounded,
                  iconBg: AppColors.warningSoft,
                  iconColor: AppColors.warning,
                  label: 'Change Password',
                  onTap: _changePassword,
                ),
              ),
              const SizedBox(height: 20),

              // ── Preferences ───────────────────────────────────────────
              // ── Logout ────────────────────────────────────────────────
              DashboardCard(
                padding: EdgeInsets.zero,
                child: _ActionRow(
                  icon: Icons.logout_rounded,
                  iconBg: const Color(0xFFFFEDED),
                  iconColor: AppColors.error,
                  label: 'Log Out',
                  labelColor: AppColors.error,
                  onTap: _logout,
                  showChevron: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  final String value;
  final IconData icon;
  const _ReadOnlyField({required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: getOutfitStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Icon(icon, size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: getOutfitStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              Text(
                value,
                style: getOutfitStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;
  final bool showChevron;
  const _ActionRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.labelColor,
    required this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: getOutfitStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? AppColors.textPrimary,
                ),
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Change Password Dialog (wide screens) ────────────────────────────────────

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await sl<AuthRepository>().changePassword(_newCtrl.text.trim());
      if (!mounted) return;
      Navigator.pop(context);
      AppToast.show(context, 'Password updated successfully');
    } catch (e, st) {
      debugPrint('[ProfilePage] Error in change password: $e\n$st');
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.show(
        context,
        'Failed to update password',
        subtitle: AppErrorMapper.message(e),
        variant: AppToastVariant.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.warningSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        size: 18,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Change Password',
                      style: getOutfitStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.borderSoft),

              // Form
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppFieldLabel('New Password *'),
                      TextFormField(
                        controller: _newCtrl,
                        obscureText: _obscureNew,
                        decoration: appInputDeco('Enter new password').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNew
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () =>
                                setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                        style: getOutfitStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Password is required';
                          }
                          if (v.trim().length < 8) {
                            return 'At least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      AppFieldLabel('Confirm Password *'),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscureConfirm,
                        decoration: appInputDeco('Confirm new password')
                            .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                            ),
                        style: getOutfitStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (v.trim() != _newCtrl.text.trim()) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.borderSoft)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.borderSoft),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: getOutfitStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _saving ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Update Password',
                                style: getOutfitStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
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
}

// ── Change Password Sheet (mobile) ────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await sl<AuthRepository>().changePassword(_newCtrl.text.trim());
      if (!mounted) return;
      Navigator.pop(context);
      AppToast.show(context, 'Password updated successfully');
    } catch (e, st) {
      debugPrint('[ProfilePage] Error in change password: $e\n$st');
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.show(
        context,
        'Failed to update password',
        subtitle: AppErrorMapper.message(e),
        variant: AppToastVariant.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 16),
            child: Row(
              children: [
                const Spacer(),
                Text(
                  'Change Password',
                  style: getOutfitStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppFieldLabel('New Password *'),
                TextFormField(
                  controller: _newCtrl,
                  obscureText: _obscureNew,
                  decoration: appInputDeco('Enter new password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  style: getOutfitStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Password is required';
                    }
                    if (v.trim().length < 8) {
                      return 'At least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AppFieldLabel('Confirm Password *'),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  decoration: appInputDeco('Confirm new password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  style: getOutfitStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (v.trim() != _newCtrl.text.trim()) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Update Password',
                            style: getOutfitStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
