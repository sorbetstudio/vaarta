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

  // Light theme colors - directly from Figma
  static const light = AppColors(
    primary: Color(0xFF007BFF),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF6C757D),
    onSecondary: Color(0xFFFFFFFF),
    background: Color(0xFFF0F0F0),
    onBackground: Color(0xFF212529),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF212529),
    surfaceVariant: Color(0xFFF8F9FA),
    error: Color(0xFFDC3545),
    onError: Color(0xFFFFFFFF),
    success: Color(0xFF28A745),
    warning: Color(0xFFFFC107),
    info: Color(0xFF17A2B8),
  );

  // Dark theme colors - directly from Figma
  static const dark = AppColors(
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

  static const mocha = AppColors(
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
