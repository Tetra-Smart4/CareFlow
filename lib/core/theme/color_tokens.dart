import 'package:flutter/material.dart';

/// CareFlow Brand Identity Color Tokens.
/// Single source of truth for all styling, cards, status badges, and typography.
class ColorTokens {
  ColorTokens._();

  // ---------------------------------------------------------------------------
  // CORE BRAND COLORS (Specification Section 9)
  // ---------------------------------------------------------------------------

  /// Primary CareFlow Blue: Primary buttons, active navigation, links, main highlights.
  static const Color primaryBlue = Color(0xFF1677E8);

  /// CareFlow Green: Success, approved, completed, health-positive states, "Flow" branding.
  static const Color careGreen = Color(0xFF35B96F);

  /// Dark Navy: Main headings, titles, important text, logo typography.
  static const Color darkNavy = Color(0xFF10245C);

  /// Background: Main application, dashboard, and page background.
  static const Color background = Color(0xFFF5F9FC);

  /// Card: White background for cards, forms, modals, queue and appointment panels.
  static const Color card = Color(0xFFFFFFFF);

  /// Light Blue: Soft highlight, selected tabs, info cards, tint derived from #1677E8.
  static const Color lightBlue = Color(0xFFEBF3FD);

  /// Light Green: Success cards, approved badges, health status tint derived from #35B96F.
  static const Color lightGreen = Color(0xFFEAF8F1);

  /// Error: Standard accessible red for errors, rejected, cancelled, critical alerts.
  static const Color error = Color(0xFFE53935);

  /// Warning: Amber/orange for pending, waiting, attention required.
  static const Color warning = Color(0xFFF59E0B);

  /// Light Warning: Soft amber background tint for warning badges and banners.
  static const Color lightWarning = Color(0xFFFEF3C7);

  // ---------------------------------------------------------------------------
  // NEUTRAL & SUPPORTING PALETTE
  // ---------------------------------------------------------------------------

  static const Color textPrimary = darkNavy;
  static const Color textSecondary = Color(0xFF5B6E88);
  static const Color textMuted = Color(0xFF8A9BA8);
  static const Color navy = darkNavy;
  static const Color muted = textMuted;
  static const Color border = Color(0xFFE2EAF2);
  static const Color divider = Color(0xFFEEF3F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // BRAND GRADIENT
  // ---------------------------------------------------------------------------

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      primaryBlue,
      careGreen,
    ],
  );

  static const LinearGradient softHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFEBF3FD),
      Color(0xFFEAF8F1),
    ],
  );
}
