import 'package:flutter/material.dart';

/// Centralized color system for CareFlow.
///
/// Keep all application colors here so screens, widgets and themes
/// use one consistent design system.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // BRAND COLORS
  // ---------------------------------------------------------------------------

  /// Primary CareFlow blue.
  static const Color primaryBlue = Color(0xFF1976D2);

  /// Primary CareFlow green.
  static const Color primaryGreen = Color(0xFF26A69A);

  /// Dark blue used for stronger headings and emphasis.
  static const Color deepBlue = Color(0xFF0D47A1);

  /// Light blue background.
  static const Color lightBlue = Color(0xFFEAF4FF);

  /// Light green background.
  static const Color lightGreen = Color(0xFFE8F7F3);

  // ---------------------------------------------------------------------------
  // BACKGROUND COLORS
  // ---------------------------------------------------------------------------

  static const Color background = Color(0xFFF7FAFC);

  static const Color surface = Color(0xFFFFFFFF);

  static const Color white = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // TEXT COLORS
  // ---------------------------------------------------------------------------

  /// Main text color.
  static const Color textPrimary = Color(0xFF172033);

  /// Secondary text color.
  static const Color textSecondary = Color(0xFF667085);

  // ---------------------------------------------------------------------------
  // COMPATIBILITY ALIASES
  //
  // Existing screens in the project use these shorter names.
  // Keep them as aliases instead of rewriting dozens of widgets.
  // ---------------------------------------------------------------------------

  /// Compatibility alias for primaryBlue.
  static const Color primary = primaryBlue;

  /// Compatibility alias for primaryGreen.
  static const Color green = primaryGreen;

  /// Compatibility alias for textPrimary.
  static const Color text = textPrimary;

  /// Compatibility alias for textSecondary.
  static const Color muted = textSecondary;

  // ---------------------------------------------------------------------------
  // UI COLORS
  // ---------------------------------------------------------------------------

  static const Color border = Color(0xFFE4EAF0);

  static const Color divider = Color(0xFFE9EEF3);

  // ---------------------------------------------------------------------------
  // STATUS COLORS
  // ---------------------------------------------------------------------------

  static const Color success = Color(0xFF2EAD7B);

  static const Color warning = Color(0xFFF5A623);

  static const Color error = Color(0xFFE53935);

  static const Color notification = Color(0xFF7C5CFC);

  static const Color billing = Color(0xFF4F46E5);

  // ---------------------------------------------------------------------------
  // BRAND GRADIENT
  // ---------------------------------------------------------------------------

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      primaryBlue,
      primaryGreen,
    ],
  );
}