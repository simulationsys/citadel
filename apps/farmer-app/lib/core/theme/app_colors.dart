import 'package:flutter/material.dart';

/// Citadel design tokens — earthy, farmer-friendly palette.
class AppColors {
  AppColors._();

  // Primary
  static const Color primaryGreen = Color(0xFF0F7A3E); // Deeper, richer green
  static const Color primaryGreenLight = Color(0xFF60AD5E);
  static const Color primaryGreenDark = Color(0xFF005005);
  
  // Background
  static const Color background = Color(0xFFF9FAFB); // Very subtle gray for contrast
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F4F8); // Muted surface for some cards

  // Severity - Critical
  static const Color severityCritical = Color(0xFFC62828);
  static const Color severityCriticalBg = Color(0xFFFCEBEB);
  
  // Severity - Warning
  static const Color severityWarning = Color(0xFFE65100);
  static const Color severityWarningBg = Color(0xFFFFF3E0);
  
  // Severity - Info
  static const Color severityInfo = Color(0xFF1565C0);
  static const Color severityInfoBg = Color(0xFFE8F0FE);
  
  // Severity - Ok
  static const Color severityOk = Color(0xFF2E7D32);
  static const Color severityOkBg = Color(0xFFE8F5E9);

  // Text
  static const Color textPrimary = Color(0xFF111827); // Dark gray/black
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Status indicators
  static const Color statusLive = Color(0xFF0F7A3E);
  static const Color statusStale = Color(0xFFF59E0B);
  static const Color statusOffline = Color(0xFFEF4444);
  
  // Custom Card Backgrounds
  static const Color cardBlueBg = Color(0xFFF0F5FF);
  static const Color cardGreenBg = Color(0xFFF0FDF4);
  static const Color cardYellowBg = Color(0xFFFEF9C3);
}
