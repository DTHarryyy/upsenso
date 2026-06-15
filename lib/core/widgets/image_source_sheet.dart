import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// Bottom sheet that lets the user choose a camera or gallery image source.
/// Shared by every "upload an image" flow so the picker looks identical
/// everywhere (business logo, receipt logo, …). Camera is hidden on web —
/// the browser handles capture inside `pickImage`.
Future<ImageSource?> showImageSourceSheet(
  BuildContext context, {
  required String title,
  String subtitle = 'Choose a square image for best results.',
}) {
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
              title,
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
              subtitle,
              style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          if (!kIsWeb)
            _SourceTile(
              icon: IconlyLight.camera,
              title: 'Take Photo',
              subtitle: 'Open camera',
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          _SourceTile(
            icon: IconlyLight.image,
            title: 'Choose from Gallery',
            subtitle: 'Browse your photos',
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.brandSoft,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: AppColors.brand, size: 18),
      ),
      title: Text(
        title,
        style: getOutfitStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: getOutfitStyle(fontSize: 12, color: AppColors.textMuted),
      ),
      onTap: onTap,
    );
  }
}
