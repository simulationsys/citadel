import 'package:flutter/material.dart';

/// Citadel design tokens — earthy, farmer-friendly palette.
class AppColors {
  AppColors._();

  // Primary
  static const Color primaryGreen = Color(0xFF006B3D);
  static const Color primaryGreenLight = Color(0xFFE8F5E9);
  static const Color primaryGreenDark = Color(0xFF004D2C);

  // Background
  static const Color background = Color(0xFFF7F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF1EA);
  static const Color cardPurpleLight = Color(0xFFEFF2FF);

  // Severity
  static const Color severityCritical = Color(0xFFD32F2F);
  static const Color severityCriticalBg = Color(0xFFFDE8E8);
  static const Color severityWarning = Color(0xFFB06000);
  static const Color severityWarningBg = Color(0xFFFFF3E0);
  static const Color severityInfo = Color(0xFF1976D2);
  static const Color severityInfoBg = Color(0xFFE3F2FD);
  static const Color severityOk = Color(0xFF008940);
  static const Color severityOkBg = Color(0xFFE8F5E9);

  // Text
  static const Color textPrimary = Color(0xFF1B1D1B);
  static const Color textSecondary = Color(0xFF5A5D5A);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status indicators
  static const Color statusLive = Color(0xFF008940);
  static const Color statusStale = Color(0xFFFFC107);
  static const Color statusOffline = Color(0xFFF44336);

  // Specific elements
  static const Color soilMoistureBrown = Color(0xFF8D4A00);
  static const Color lightBlueBackground = Color(0xFFE8EAF6);
}
