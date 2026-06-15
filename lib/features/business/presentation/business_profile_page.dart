import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';
import 'package:pos/core/widgets/image_source_sheet.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';
import 'package:pos/features/settings/data/receipt_settings_repository.dart';
import 'package:pos/features/settings/domain/receipt_settings.dart';

class BusinessProfilePage extends StatefulWidget {
  const BusinessProfilePage({super.key});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  // Single source of truth for the unified business logo (offline-first).
  final _repo = sl<ReceiptSettingsRepository>();
  bool _isUploading = false;

  // Cache the watch stream per business so rebuilds don't resubscribe.
  Stream<ReceiptSettings?>? _logoStream;
  String? _watchedBusinessId;

  Stream<ReceiptSettings?> _logoStreamFor(String businessId) {
    if (_watchedBusinessId != businessId || _logoStream == null) {
      _watchedBusinessId = businessId;
      _logoStream = _repo.watch(businessId);
    }
    return _logoStream!;
  }

  // ── Logo upload (offline-first via the shared repository) ─────────────────────

  Future<void> _pickLogo(String businessId) async {
    if (_isUploading) return;

    final source = await showImageSourceSheet(
      context,
      title: 'Update Business Logo',
    );
    if (source == null) return;

    // Camera permission — native only (browser handles it via pickImage)
    if (!kIsWeb && source == ImageSource.camera) {
      var status = await Permission.camera.status;
      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        final shouldOpen = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Camera Permission Required'),
            content: const Text(
              'Camera access has been permanently denied. '
              'Please enable it in App Settings to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        if (shouldOpen != true) return;
        await openAppSettings();
        // Re-check after user returns from settings
        status = await Permission.camera.status;
      } else if (!status.isGranted) {
        status = await Permission.camera.request();
      }
      if (!status.isGranted) return;
    }

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 512,
      imageQuality: 90,
    );
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = Uint8List.fromList(await picked.readAsBytes());
      final ext = p.extension(picked.path).toLowerCase();
      final safeExt = ext.isNotEmpty ? ext : '.jpg';
      final mimeType = safeExt == '.png'
          ? 'image/png'
          : safeExt == '.webp'
          ? 'image/webp'
          : 'image/jpeg';

      await _repo.saveLogo(
        businessId: businessId,
        bytes: bytes,
        ext: safeExt,
        mimeType: mimeType,
      );

      if (mounted) {
        StatusSnack.show(
          context,
          type: StatusType.success,
          title: 'Logo Updated',
          message: 'Saved — it will sync automatically when you\'re online.',
        );
      }
    } catch (e, st) {
      debugPrint('[Logo] Business profile upload failed: $e\n$st');
      if (mounted) {
        final msg = e.toString();
        final isCameraDenied =
            kIsWeb &&
            (msg.toLowerCase().contains('notallowederror') ||
                msg.toLowerCase().contains('permission'));
        StatusSnack.show(
          context,
          type: StatusType.error,
          title: isCameraDenied ? 'Camera Access Denied' : 'Upload Failed',
          message: isCameraDenied
              ? 'Allow camera access in your browser settings, then try again.'
              : msg,
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              'Business Profile',
              style: getOutfitStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.borderSoft),
            ),
          ),
          body: user == null
              ? const Center(child: CircularProgressIndicator())
              : user.businessId == null
              ? _Body(
                  user: user,
                  logoLocalPath: '',
                  logoUrl: '',
                  isUploading: _isUploading,
                  onUploadLogo: () {},
                )
              : StreamBuilder<ReceiptSettings?>(
                  stream: _logoStreamFor(user.businessId!),
                  builder: (context, snap) {
                    final s = snap.data;
                    return _Body(
                      user: user,
                      logoLocalPath: s?.logoLocalPath ?? '',
                      logoUrl: s?.logoUrl ?? '',
                      isUploading: _isUploading,
                      onUploadLogo: () => _pickLogo(user.businessId!),
                    );
                  },
                ),
        );
      },
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final AppUser user;
  final String logoLocalPath;
  final String logoUrl;
  final bool isUploading;
  final VoidCallback onUploadLogo;

  const _Body({
    required this.user,
    required this.logoLocalPath,
    required this.logoUrl,
    required this.isUploading,
    required this.onUploadLogo,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;
    final hPad = isDesktop ? 32.0 : 20.0;
    final maxW = isDesktop ? 1080.0 : double.infinity;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BusinessHeader(
                user: user,
                logoLocalPath: logoLocalPath,
                logoUrl: logoUrl,
                isUploading: isUploading,
                onUpload: onUploadLogo,
              ),
              const SizedBox(height: 16),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _BusinessDetailsCard(user: user)),
                    const SizedBox(width: 16),
                    Expanded(child: _AccountCard(user: user)),
                  ],
                )
              else ...[
                _BusinessDetailsCard(user: user),
                const SizedBox(height: 16),
                _AccountCard(user: user),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Business identity header ─────────────────────────────────────────────────

class _BusinessHeader extends StatelessWidget {
  final AppUser user;
  final String logoLocalPath;
  final String logoUrl;
  final bool isUploading;
  final VoidCallback onUpload;

  const _BusinessHeader({
    required this.user,
    required this.logoLocalPath,
    required this.logoUrl,
    required this.isUploading,
    required this.onUpload,
  });

  String _initial(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'B';
    final words = clean
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return clean.substring(0, clean.length > 1 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = user.businessName ?? 'My Business';
    final type = user.businessTemplateName;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          // Tappable logo block
          GestureDetector(
            onTap: onUpload,
            child: Stack(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _LogoContent(
                      logoLocalPath: logoLocalPath,
                      logoUrl: logoUrl,
                      isUploading: isUploading,
                      initial: _initial(name),
                    ),
                  ),
                ),
                // Camera badge
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.borderSoft,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      IconlyLight.camera,
                      size: 12,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: getOutfitStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Tooltip(
                      message: 'Account status: Active',
                      child: Icon(
                        IconlyBold.tick_square,
                        size: 16,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                if (type != null && type.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    type,
                    style: getOutfitStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoContent extends StatelessWidget {
  final String logoLocalPath;
  final String logoUrl;
  final bool isUploading;
  final String initial;

  const _LogoContent({
    required this.logoLocalPath,
    required this.logoUrl,
    required this.isUploading,
    required this.initial,
  });

  @override
  Widget build(BuildContext context) {
    if (isUploading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
      );
    }

    // Prefer the local file (shows instantly, even offline), then the URL.
    if (logoLocalPath.isNotEmpty && !kIsWeb) {
      return Image.file(
        File(logoLocalPath),
        fit: BoxFit.cover,
        width: 68,
        height: 68,
        errorBuilder: (_, _, _) => _networkOrInitial(),
      );
    }
    return _networkOrInitial();
  }

  Widget _networkOrInitial() {
    if (logoUrl.isNotEmpty) {
      return Image.network(
        logoUrl,
        fit: BoxFit.cover,
        width: 68,
        height: 68,
        errorBuilder: (_, _, _) => _Initial(initial: initial),
      );
    }
    return _Initial(initial: initial);
  }
}

class _Initial extends StatelessWidget {
  final String initial;
  const _Initial({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: getOutfitStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── Business details card ────────────────────────────────────────────────────

class _BusinessDetailsCard extends StatelessWidget {
  final AppUser user;
  const _BusinessDetailsCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: IconlyLight.work,
      title: 'Business Information',
      rows: [
        _InfoRow(
          icon: IconlyLight.work,
          label: 'Business Name',
          value: user.businessName ?? '—',
        ),
        if (user.businessTemplateName?.isNotEmpty == true)
          _InfoRow(
            icon: IconlyLight.category,
            label: 'Business Type',
            value: user.businessTemplateName!,
          ),
      ],
    );
  }
}

// ─── Account card ─────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final AppUser user;
  const _AccountCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final branch = user.branchName?.isNotEmpty == true
        ? user.branchName!
        : 'All Branches';

    return _SectionCard(
      icon: IconlyLight.profile,
      title: 'Your Account',
      rows: [
        _InfoRow(
          icon: IconlyLight.profile,
          label: 'Full Name',
          value: user.fullName ?? '—',
        ),
        _InfoRow(
          icon: IconlyLight.message,
          label: 'Email',
          value: user.email ?? '—',
        ),
        _InfoRow(
          icon: IconlyLight.shield_done,
          label: 'Role',
          value: displayRoleName(user.roleName) ?? '—',
          valueStyle: getOutfitStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.brand,
          ),
        ),
        _InfoRow(
          icon: IconlyLight.location,
          label: 'Assigned Branch',
          value: branch,
        ),
      ],
    );
  }
}

// ─── Shared primitives ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_InfoRow> rows;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.brand),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: getOutfitStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.borderSoft),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: List.generate(rows.length, (i) {
                return Column(
                  children: [
                    rows[i],
                    if (i < rows.length - 1)
                      Container(height: 1, color: AppColors.borderSoft),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
    this.valueStyle,
  }) : assert(value != null || valueWidget != null);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: getOutfitStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child:
                valueWidget ??
                Text(
                  value!,
                  textAlign: TextAlign.end,
                  style:
                      valueStyle ??
                      getOutfitStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
          ),
        ],
      ),
    );
  }
}
