import 'package:flutter/material.dart';

/// ScanVault brand color tokens.
/// All colors are derived from the seed color to maintain Material 3 harmony.
class AppColors {
  AppColors._();

  // Brand / seed color
  static const Color brandTeal = Color(0xFF1D9E75);
  static const Color brandTealDark = Color(0xFF0F6E56);
  static const Color brandTealLight = Color(0xFF4ECBA0);

  // Light scheme generated from seed
  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: brandTeal,
    brightness: Brightness.light,
    surface: const Color(0xFFF5F5F5),
  ).copyWith(
    surface: const Color(0xFFF5F5F5),
    onSurface: const Color(0xFF1A1A1A),
  );

  // Dark scheme generated from seed
  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: brandTeal,
    brightness: Brightness.dark,
    surface: const Color(0xFF1E1E1E),
  ).copyWith(
    surface: const Color(0xFF1E1E1E),
    onSurface: const Color(0xFFF0F0F0),
  );

  // Scan type badge colors
  static const Color urlColor = Color(0xFF2196F3);
  static const Color phoneColor = Color(0xFF4CAF50);
  static const Color emailColor = Color(0xFFFF9800);
  static const Color wifiColor = Color(0xFF9C27B0);
  static const Color vcardColor = Color(0xFF00BCD4);
  static const Color geoColor = Color(0xFFF44336);
  static const Color smsColor = Color(0xFF3F51B5);
  static const Color textColor = Color(0xFF607D8B);

  // Overlay
  static const Color scanOverlayColor = Color(0x99000000);
  static const Color scanCornerColor = brandTeal;
}
