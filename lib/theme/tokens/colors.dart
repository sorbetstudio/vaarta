import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color error;
  final Color onError;
  final Color success;
  final Color warning;
  final Color info;

  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.error,
    required this.onError,
    required this.success,
    required this.warning,
    required this.info,
  });

  // Light theme colors - Catppuccin Latte palette
  static const light = AppColors(
    primary: Color(0xFF1E66F5), // blue - main brand color
    onPrimary: Color(0xFFEFF1F5), // base - for text on primary
    secondary: Color(0xFF7287FD), // lavender - secondary actions
    onSecondary: Color(0xFFEFF1F5), // base - for text on secondary
    background: Color(0xFFEFF1F5), // base - main background
    onBackground: Color(0xFF4C4F69), // text - main text color
    surface: Color(0xFFE6E9EF), // mantle - card surfaces
    onSurface: Color(0xFF4C4F69), // text - for text on surfaces
    surfaceVariant: Color(0xFFCCD0DA), // surface0 - alternative surface
    error: Color(0xFFD20F39), // red - for errors
    onError: Color(0xFFEFF1F5), // base - for text on error
    success: Color(0xFF40A02B), // green - for success states
    warning: Color(0xFFDF8E1D), // yellow - for warnings
    info: Color(0xFF209FB5), // sapphire - for information
  );

  // Additional Catppuccin Latte colors for future reference:
  // rosewater: Color(0xFFDC8A78),
  // flamingo: Color(0xFFDD7878),
  // pink: Color(0xFFEA76CB),
  // mauve: Color(0xFF8839EF),
  // red: Color(0xFFD20F39),      // Already used for error
  // maroon: Color(0xFFE64553),
  // peach: Color(0xFFFE640B),
  // yellow: Color(0xFFDF8E1D),   // Already used for warning
  // green: Color(0xFF40A02B),    // Already used for success
  // teal: Color(0xFF179299),
  // sky: Color(0xFF04A5E5),
  // sapphire: Color(0xFF209FB5), // Already used for info
  // blue: Color(0xFF1E66F5),     // Already used for primary
  // lavender: Color(0xFF7287FD), // Already used for secondary
  // text: Color(0xFF4C4F69),     // Already used for onBackground/onSurface
  // subtext1: Color(0xFF5C5F77),
  // subtext0: Color(0xFF6C6F85),
  // overlay2: Color(0xFF7C7F93),
  // overlay1: Color(0xFF8C8FA1),
  // overlay0: Color(0xFF9CA0B0),
  // surface2: Color(0xFFACB0BE),
  // surface1: Color(0xFFBCC0CC),
  // surface0: Color(0xFFCCD0DA),  // Already used for surfaceVariant
  // crust: Color(0xFFDCE0E8),
  // mantle: Color(0xFFE6E9EF),    // Already used for surface
  // base: Color(0xFFEFF1F5),      // Already used for background

  // Temporarily swapping mocha and dark
  static const mocha = AppColors(
    primary: Color(0xFF0D6EFD),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF6C757D),
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFF121212),
    onBackground: Color(0xFFE9ECEF),
    surface: Color(0xFF1E1E1E),
    onSurface: Color(0xFFE9ECEF),
    surfaceVariant: Color(0xFF2D2D2D),
    error: Color(0xFFDC3545),
    onError: Color(0xFFFFFFFF),
    success: Color(0xFF28A745),
    warning: Color(0xFFFFC107),
    info: Color(0xFF17A2B8),
  );

  static const dark = AppColors(
    primary: Color(0xFF89B4FA), // blue
    onPrimary: Color(0xFF1E1E2E), // base
    secondary: Color(0xFFCBA6F7), // mauve
    onSecondary: Color(0xFF1E1E2E), // base
    background: Color(0xFF1E1E2E), // base
    onBackground: Color(0xFFCDD6F4), // text
    surface: Color(0xFF313244), // surface0
    onSurface: Color(0xFFCDD6F4), // text
    surfaceVariant: Color(0xFF45475A), // surface1
    error: Color(0xFFF38BA8), // red
    onError: Color(0xFF1E1E2E), // base
    success: Color(0xFFA6E3A1), // green
    warning: Color(0xFFF9E2AF), // yellow
    info: Color(0xFF89DCEB), // sky
  );

  @override
  ThemeExtension<AppColors> copyWith({
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? background,
    Color? onBackground,
    Color? surface,
    Color? onSurface,
    Color? surfaceVariant,
    Color? error,
    Color? onError,
    Color? success,
    Color? warning,
    Color? info,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      background: background ?? this.background,
      onBackground: onBackground ?? this.onBackground,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}
