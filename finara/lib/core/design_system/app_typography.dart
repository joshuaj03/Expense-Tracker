/// Finara typography system â€” Manrope for display, Inter for body.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  // ── Display / Headers (Manrope) ──
  static TextStyle displayLarge = GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static TextStyle displaySmall = GoogleFonts.manrope(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static TextStyle headlineMedium = GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle headlineSmall = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // ── Body (Inter) ──
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // ── Currency / Numbers (Inter with tabular figures) ──
  static TextStyle currencyLarge = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    fontFeatures: const [FontFeature.tabularFigures()],
    letterSpacing: -0.5,
  );

  static TextStyle currencyMedium = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle currencySmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // ── Labels ──
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
}
