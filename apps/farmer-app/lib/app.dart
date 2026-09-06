import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_colors.dart';
import 'features/home/home_screen.dart';
import 'features/advisory_detail/advisory_detail_screen.dart';
import 'features/scan/scan_screen.dart';
import 'features/history/history_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/profile/profile_screen.dart';

class CitadelApp extends StatelessWidget {
  const CitadelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Citadel Farm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/advisory-detail': (_) => const AdvisoryDetailScreen(),
        '/scan': (_) => const ScanScreen(),
        '/history': (_) => const HistoryScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }
}
