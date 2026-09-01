import 'package:flutter/material.dart';

/// Citadel design tokens — earthy, farmer-friendly palette.
class AppColors {
  AppColors._();

  // Primary
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color primaryGreenLight = Color(0xFF60AD5E);
  static const Color primaryGreenDark = Color(0xFF005005);

  // Background
  static const Color background = Color(0xFFF4F7F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF1EA);

  // Severity
  static const Color severityCritical = Color(0xFFD32F2F);
  static const Color severityCriticalBg = Color(0xFFFDE8E8);
  static const Color severityWarning = Color(0xFFF9A825);
  static const Color severityWarningBg = Color(0xFFFFF8E1);
  static const Color severityInfo = Color(0xFF1976D2);
  static const Color severityInfoBg = Color(0xFFE3F2FD);
  static const Color severityOk = Color(0xFF388E3C);
  static const Color severityOkBg = Color(0xFFE8F5E9);

  // Text
  static const Color textPrimary = Color(0xFF1B3A20);
  static const Color textSecondary = Color(0xFF5D6D60);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status indicators
  static const Color statusLive = Color(0xFF4CAF50);
  static const Color statusStale = Color(0xFFFFC107);
  static const Color statusOffline = Color(0xFFF44336);
}
