import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_settings_provider.dart';
import '../core/theme/app_colors.dart';

class ProfileAvatarButton extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry margin;

  const ProfileAvatarButton({
    super.key,
    this.size = 36,
    this.margin = const EdgeInsets.only(right: 16),
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final hasCustomImage = settings.profileImagePath != null &&
        settings.profileImagePath!.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(size / 2),
      onTap: () => Navigator.pushNamed(context, '/profile'),
      child: Container(
        margin: margin,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: hasCustomImage
              ? Image.file(
                  File(settings.profileImagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Image.asset(
                    'assets/images/farmer_avatar.png',
                    fit: BoxFit.cover,
                  ),
                )
              : Image.asset(
                  'assets/images/farmer_avatar.png',
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }
}
