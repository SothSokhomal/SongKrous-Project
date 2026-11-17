import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography: Inter for Latin, Noto Sans Khmer as fallback for Khmer script
/// so mixed EN/KH strings render correctly.
abstract final class AppTypography {
  static const List<String> _khmerFallback = ['Noto Sans Khmer'];

  static TextStyle _s(double size, FontWeight weight) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: AppColors.textPrimary,
    // Khmer glyphs need more vertical room than Latin.
    height: 1.4,
  ).copyWith(fontFamilyFallback: _khmerFallback);

  static TextTheme textTheme() => TextTheme(
    displayLarge: _s(40, FontWeight.w800),
    headlineMedium: _s(26, FontWeight.w700),
    titleLarge: _s(20, FontWeight.w700),
    titleMedium: _s(16, FontWeight.w600),
    bodyLarge: _s(16, FontWeight.w400),
    bodyMedium: _s(14, FontWeight.w400),
    labelLarge: _s(14, FontWeight.w600),
    labelSmall: _s(11, FontWeight.w500),
  );
}
