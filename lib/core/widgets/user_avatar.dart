import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pos/core/const/app_colors.dart';
import 'package:pos/core/const/font_utils.dart';

/// Displays a user avatar — network image when [avatarUrl] is set,
/// otherwise an initials circle derived from [name] or [email].
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? name;
  final String? email;
  final double radius;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.name,
    this.email,
    this.radius = 20,
    this.onTap,
    this.showEditBadge = false,
  });

  String _initials() {
    final src = (name?.trim().isNotEmpty == true ? name! : email ?? '');
    final parts = src
        .split(RegExp(r'[\s._@\-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final f = parts[0];
      return f.substring(0, f.length > 1 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final circle = _AvatarCircle(
      avatarUrl: avatarUrl,
      initials: _initials(),
      radius: radius,
    );

    if (onTap == null && !showEditBadge) return circle;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          circle,
          if (showEditBadge)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: radius * 0.4,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final double radius;

  const _AvatarCircle({
    required this.avatarUrl,
    required this.initials,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final hasUrl = avatarUrl != null && avatarUrl!.isNotEmpty;
    final isLocal = hasUrl && !avatarUrl!.startsWith('http');

    Widget content;
    if (hasUrl) {
      content = isLocal
          ? Image.file(
              File(avatarUrl!),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (ctx, e, _) =>
                  _InitialsFill(initials: initials, radius: radius),
            )
          : Image.network(
              avatarUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (ctx, e, _) =>
                  _InitialsFill(initials: initials, radius: radius),
            );
    } else {
      content = _InitialsFill(initials: initials, radius: radius);
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(child: content),
    );
  }
}

class _InitialsFill extends StatelessWidget {
  final String initials;
  final double radius;
  const _InitialsFill({required this.initials, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: AppColors.brandSoft,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: getOutfitStyle(
          fontSize: radius * 0.55,
          fontWeight: FontWeight.w700,
          color: AppColors.brand,
        ),
      ),
    );
  }
}
