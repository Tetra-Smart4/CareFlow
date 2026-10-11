import 'package:flutter/material.dart';
import 'color_tokens.dart';

/// Centralized color system for CareFlow.
///
/// Aliases to [ColorTokens] for complete brand consistency.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // BRAND COLORS (Section 9)
  // ---------------------------------------------------------------------------

  /// Primary CareFlow Blue (#1677E8).
  static const Color primaryBlue = ColorTokens.primaryBlue;

  /// CareFlow Green (#35B96F).
  static const Color primaryGreen = ColorTokens.careGreen;

  /// Dark Navy (#10245C) for headings, titles, emphasis.
  static const Color darkNavy = ColorTokens.darkNavy;
  static const Color deepBlue = ColorTokens.darkNavy;

  /// Light blue background tint.
  static const Color lightBlue = ColorTokens.lightBlue;

  /// Light green background tint.
  static const Color lightGreen = ColorTokens.lightGreen;

  // ---------------------------------------------------------------------------
  // BACKGROUND & SURFACES
  // ---------------------------------------------------------------------------

  static const Color background = ColorTokens.background;
  static const Color surface = ColorTokens.surface;
  static const Color white = ColorTokens.white;
  static const Color card = ColorTokens.card;

  // ---------------------------------------------------------------------------
  // TEXT COLORS
  // ---------------------------------------------------------------------------

  static const Color textPrimary = ColorTokens.textPrimary;
  static const Color textSecondary = ColorTokens.textSecondary;
  static const Color textMuted = ColorTokens.textMuted;

  // ---------------------------------------------------------------------------
  // COMPATIBILITY ALIASES
  // ---------------------------------------------------------------------------

  static const Color primary = primaryBlue;
  static const Color green = primaryGreen;
  static const Color text = textPrimary;
  static const Color muted = textSecondary;

  // ---------------------------------------------------------------------------
  // UI COLORS
  // ---------------------------------------------------------------------------

  static const Color border = ColorTokens.border;
  static const Color divider = ColorTokens.divider;

  // ---------------------------------------------------------------------------
  // STATUS COLORS
  // ---------------------------------------------------------------------------

  static const Color success = ColorTokens.careGreen;
  static const Color approved = ColorTokens.careGreen;
  static const Color completed = ColorTokens.careGreen;
  static const Color warning = ColorTokens.warning;
  static const Color pending = ColorTokens.warning;
  static const Color error = ColorTokens.error;
  static const Color rejected = ColorTokens.error;
  static const Color notification = Color(0xFF7C5CFC);
  static const Color billing = Color(0xFF4F46E5);

  // ---------------------------------------------------------------------------
  // BRAND GRADIENTS
  // ---------------------------------------------------------------------------

  static const LinearGradient primaryGradient = ColorTokens.primaryGradient;
  static const LinearGradient softHeroGradient = ColorTokens.softHeroGradient;
}