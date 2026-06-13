import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:pos/core/config/di.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';
import 'package:pos/core/ui/status/status_snack.dart';
import 'package:pos/core/ui/status/status_type.dart';
import 'package:pos/features/auth/domain/entities/app_user.dart';
import 'package:pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pos/features/auth/presentation/bloc/auth_state.dart';

class BusinessProfilePage extends StatefulWidget {
  const BusinessProfilePage({super.key});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  String? _businessId;
  String? _logoUrl;
  bool _isUploading = false;

  // ── Logo loading ─────────────────────────────────────────────────────────────

  Future<void> _initLogo(String businessId) async {
    if (_businessId == businessId) return;
    _businessId = businessId;

    // 1. Check local cache for instant display
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('biz_logo_$businessId');
    if (cached != null && mounted) setState(() => _logoUrl = cached);

    // 2. Fetch from Supabase DB in background (authoritative source)
    try {
      final row = await sl<SupabaseClient>()
          .from('businesses')
          .select('logo_url')
          .eq('id', businessId)
          .maybeSingle();
      final remote = row?['logo_url'] as String?;
      if (remote != null && remote.isNotEmpty && mounted) {
        final url = '$remote?t=${DateTime.now().millisecondsSinceEpoch}';
        setState(() => _logoUrl = url);
        await prefs.setString('biz_logo_$businessId', url);
      }
    } catch (_) {
      // Silently use cached value
    }
  }

  // ── Logo upload ──────────────────────────────────────────────────────────────

  Future<void> _pickLogo() async {
    if (_isUploading || _businessId == null) return;

    final source = await _showSourceSheet();
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
      final contentType = safeExt == '.png'
          ? 'image/png'
          : safeExt == '.webp'
          ? 'image/webp'
          : 'image/jpeg';

      final storagePath = '$_businessId/logo$safeExt';
      final client = sl<SupabaseClient>();

      await client.storage
          .from('business-logos')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );

      final rawUrl = client.storage
          .from('business-logos')
          .getPublicUrl(storagePath);
      final url = '$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // Persist URL to DB and local cache
      await client
          .from('businesses')
          .update({'logo_url': rawUrl})
          .eq('id', _businessId!);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('biz_logo_$_businessId', url);

      if (mounted) {
        setState(() => _logoUrl = url);
        StatusSnack.show(
          context,
          type: StatusType.success,
          title: 'Logo Updated',
          message: 'Business logo saved successfully.',
        );
      }
    } catch (e) {
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

  Future<ImageSource?> _showSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Update Business Logo',
                style: getOutfitStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Choose a square image for best results.',
                style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 12),
            if (!kIsWeb)
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    IconlyLight.camera,
                    color: AppColors.brand,
                    size: 18,
                  ),
                ),
                title: Text(
                  'Take Photo',
                  style: getOutfitStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Open camera',
                  style: getOutfitStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  IconlyLight.image,
                  color: AppColors.brand,
                  size: 18,
                ),
              ),
              title: Text(
                'Choose from Gallery',
                style: getOutfitStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Browse your photos',
                style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        if (user?.businessId != null) {
          _initLogo(user!.businessId!);
        }

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
              : _Body(
                  user: user,
                  logoUrl: _logoUrl,
                  isUploading: _isUploading,
                  onUploadLogo: _pickLogo,
                ),
        );
      },
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final AppUser user;
  final String? logoUrl;
  final bool isUploading;
  final VoidCallback onUploadLogo;

  const _Body({
    required this.user,
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
  final String? logoUrl;
  final bool isUploading;
  final VoidCallback onUpload;

  const _BusinessHeader({
    required this.user,
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
                    SizedBox(width: 6),
                    Tooltip(
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
  final String? logoUrl;
  final bool isUploading;
  final String initial;

  const _LogoContent({
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

    if (logoUrl != null) {
      return Image.network(
        logoUrl!,
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
