import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_settings_provider.dart';
import '../core/config/app_strings.dart';
import '../core/theme/app_colors.dart';

/// Shared bottom navigation with centre scan FAB, matching the mockups:
/// Home | (scan) | Advisory | Profile.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  void _go(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
        break;
      case 1:
        Navigator.pushNamed(context, '/scan');
        break;
      case 2:
        Navigator.pushNamed(context, '/analytics');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _item(context, Icons.home_rounded, AppStrings.translate('Home', settings.language), 0)),
              Expanded(child: _item(context, Icons.qr_code_scanner_rounded, AppStrings.translate('Scanner', settings.language), 1)),
              Expanded(child: _item(context, Icons.analytics_outlined, AppStrings.translate('Insights', settings.language), 2)),
              Expanded(child: _item(context, Icons.person_outline_rounded, AppStrings.translate('Profile', settings.language), 3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, int index) {
    final selected = currentIndex == index;
    final isScanner = index == 1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _go(context, index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isScanner)
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryGreen : AppColors.cardGreenBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: selected ? Colors.white : AppColors.primaryGreen,
                    size: 20,
                  ),
                )
              else
                Icon(
                  icon,
                  color: selected ? AppColors.primaryGreen : Colors.grey[600],
                  size: 24,
                ),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? AppColors.primaryGreen : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


