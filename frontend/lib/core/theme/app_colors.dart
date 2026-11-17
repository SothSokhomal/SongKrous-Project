import 'package:flutter/material.dart';

/// SONGKROUS design tokens — Red, Blue & White.
abstract final class AppColors {
  // Brand
  static const Color red = Color(0xFFD91E2A); // emergency
  static const Color redDark = Color(0xFFB3121F);
  static const Color redSoft = Color(0xFFFEE2E2);
  static const Color blue = Color(0xFF1D4ED8); // interactive / active
  static const Color blueDeep = Color(0xFF0F3D91); // headers, primary CTA
  static const Color blueDark = Color(0xFF0B2A6B);
  static const Color blueSoft = Color(0xFFE6EDFD);
  static const Color white = Color(0xFFFFFFFF);

  // Neutrals
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color slate = Color(
    0xFF64748B,
  ); // inactive nav / icons / captions
  static const Color slateLight = Color(0xFFCBD5E1); // inactive step dots
  static const Color ink = Color(0xFF0F172A); // headlines
  static const Color redTint = Color(0xFFFEF2F2);
  static const Color blueTint = Color(0xFFEFF6FF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color callBackground = Color(0xFF162229);

  // Facility categories
  static const Color hospital = red;
  static const Color police = blue;
  static const Color fire = red;
  static const Color gold = Color(0xFFF5B301);
  static const Color flame = Color(0xFFFFC107);

  static const Color success = Color(0xFF16A34A);
}
