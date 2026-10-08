import 'package:flutter/material.dart';

/// Central color palette for the Mobile EMI Manager app.
/// All colors must be referenced from here — no hardcoded color values in widgets.
class AppColors {
  AppColors._();

  // ─── Primary Brand Colors ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF9B8FF0);
  static const Color primaryDark = Color(0xFF4A3CBF);

  // ─── Secondary / Accent ───────────────────────────────────────────────────
  static const Color secondary = Color(0xFF00B894);
  static const Color accent = Color(0xFFF59E0B);

  // ─── Semantic Colors ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFE17055);
  static const Color info = Color(0xFF0984E3);

  // ─── Neutral / Backgrounds ────────────────────────────────────────────────
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF1E293B);

  // ─── Text Colors ──────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color textInverse = Color(0xFFFFFFFF);

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // ─── Border / Divider ─────────────────────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF334155);
  static const Color divider = Color(0xFFF3F4F6);

  // ─── Status Colors ────────────────────────────────────────────────────────
  static const Color overdue = Color(0xFFE17055);
  static const Color pending = Color(0xFFF59E0B);
  static const Color paid = Color(0xFF00B894);
  static const Color inactive = Color(0xFF9CA3AF);

  // ─── Shimmer ──────────────────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFE5E7EB);
  static const Color shimmerHighlight = Color(0xFFF9FAFB);
}
