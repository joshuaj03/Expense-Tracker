/// Finara color system â€” dark-first with full light mode parity.
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand Accent Gradient ──
  static const Color accentViolet = Color(0xFF7C4DFF);
  static const Color accentCyan = Color(0xFF18FFFF);
  static const LinearGradient brandGradient = LinearGradient(
    colors: [accentViolet, Color(0xFF448AFF), accentCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Semantic Colors ──
  static const Color income = Color(0xFF4CAF50);
  static const Color incomeLight = Color(0xFF81C784);
  static const Color expense = Color(0xFFFF5252);
  static const Color expenseLight = Color(0xFFFF8A80);
  static const Color transfer = Color(0xFF448AFF);
  static const Color warning = Color(0xFFFFB74D);

  // ── Dark Theme ──
  static const Color darkBackground = Color(0xFF0B0B0F);
  static const Color darkSurface = Color(0xFF16161E);
  static const Color darkCard = Color(0xFF1E1E2A);
  static const Color darkCardHover = Color(0xFF262636);
  static const Color darkBorder = Color(0xFF2A2A3A);
  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFF9E9EB8);
  static const Color darkTextTertiary = Color(0xFF6B6B80);

  // ── Light Theme ──
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardHover = Color(0xFFF5F5F8);
  static const Color lightBorder = Color(0xFFE8E8EE);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B6B80);
  static const Color lightTextTertiary = Color(0xFF9E9EB8);

  // ── Glass Effect ──
  static Color glassWhite(double opacity) =>
      Colors.white.withValues(alpha: opacity);
  static Color glassBlack(double opacity) =>
      Colors.black.withValues(alpha: opacity);

  // ── Category Palette (24 curated colors) ──
  static const List<Color> categoryPalette = [
    Color(0xFFFF6B6B),
    Color(0xFFFF8E53),
    Color(0xFFFFB74D),
    Color(0xFFFFD54F),
    Color(0xFF81C784),
    Color(0xFF66BB6A),
    Color(0xFF4ECDC4),
    Color(0xFF26C6DA),
    Color(0xFF42A5F5),
    Color(0xFF5C6BC0),
    Color(0xFF7C4DFF),
    Color(0xFFAB47BC),
    Color(0xFFEC407A),
    Color(0xFFE040FB),
    Color(0xFFBA68C8),
    Color(0xFF78909C),
    Color(0xFF8D6E63),
    Color(0xFF26A69A),
    Color(0xFFFF7043),
    Color(0xFFF06292),
    Color(0xFF7986CB),
    Color(0xFF4DB6AC),
    Color(0xFFAED581),
    Color(0xFFDCE775),
  ];
}
