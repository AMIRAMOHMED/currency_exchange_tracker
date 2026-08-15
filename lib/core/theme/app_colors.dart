import 'package:flutter/material.dart';

/// App color palette based on the design system
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary500 = Color(0xFF1FB8CB);
  static const Color primary400 = Color(0xFF22888D);
  static const Color primary300 = Color(0xFF308E83);
  static const Color primary200 = Color(0xFF398CA8);
  static const Color primary100 = Color(0xFF308CA3);

  // Semantic Colors
  static const Color negative = Color(0xFFEF4444);
  static const Color negativeSoft = Color(0xFFFEE2E2);
  static const Color positive = Color(0xFF10B981);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF687280);

  // Background & Surface
  static const Color background = Color(0xFFF7F8FC);
  static const Color surface = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);

  /// White elevated card on the gray page background.
  static BoxDecoration get surfaceCard => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: border),
  );

  /// Teal-tinted banner for alerts (offline, info).
  static BoxDecoration get primaryTintBanner => BoxDecoration(
    color: primary500.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: primary500.withValues(alpha: 0.25)),
  );
}
