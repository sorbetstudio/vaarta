// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vaarta/theme/tokens/colors.dart';
import 'package:vaarta/theme/tokens/typography.dart';
import 'package:vaarta/theme/tokens/spacing.dart';
import 'package:vaarta/theme/tokens/radius.dart';
import 'package:vaarta/theme/tokens/shadows.dart';
import 'package:vaarta/theme/theme_config.dart';

class AppThemeData {
  static ThemeData getThemeData(AppTheme theme, BuildContext context) {
    return switch (theme) {
      AppTheme.light => _buildLightTheme(),
      AppTheme.dark => _buildDarkTheme(),
      AppTheme.mocha => _buildMochaTheme(),
      AppTheme.custom => _buildCustomTheme(),
      AppTheme.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark
            ? _buildDarkTheme()
            : _buildLightTheme(),
    };
  }

  static ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      extensions: <ThemeExtension<dynamic>>[
        AppColors.light,
        AppTypography.base,
        AppSpacing.base,
        AppRadius.base,
        AppShadows.light,
      ],
      scaffoldBackgroundColor: AppColors.light.background,
      colorScheme: ColorScheme.light(
        primary: AppColors.light.primary,
        secondary: AppColors.light.secondary,
        surface: AppColors.light.surface,
        background: AppColors.light.background,
        error: AppColors.light.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.light.surface,
        foregroundColor: AppColors.light.onSurface,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardTheme(
        color: AppColors.light.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.base.medium),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.light.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base.large),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.base.medium,
          vertical: AppSpacing.base.small,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.light.primary,
          foregroundColor: AppColors.light.onPrimary,
          elevation: 3,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.base.large,
            vertical: AppSpacing.base.medium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.base.medium),
          ),
        ),
      ),
      textTheme: _buildTextTheme(AppColors.light.onBackground),
    );
  }

  static ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      extensions: <ThemeExtension<dynamic>>[
        AppColors.dark,
        AppTypography.base,
        AppSpacing.base,
        AppRadius.base,
        AppShadows.dark,
      ],
      scaffoldBackgroundColor: AppColors.dark.background,
      colorScheme: ColorScheme.dark(
        primary: AppColors.dark.primary,
        secondary: AppColors.dark.secondary,
        surface: AppColors.dark.surface,
        background: AppColors.dark.background,
        error: AppColors.dark.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.dark.surface,
        foregroundColor: AppColors.dark.onSurface,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardTheme(
        color: AppColors.dark.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.base.medium),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.dark.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base.large),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.base.medium,
          vertical: AppSpacing.base.small,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dark.primary,
          foregroundColor: AppColors.dark.onPrimary,
          elevation: 3,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.base.large,
            vertical: AppSpacing.base.medium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.base.medium),
          ),
        ),
      ),
      textTheme: _buildTextTheme(AppColors.dark.onBackground),
    );
  }

  static ThemeData _buildMochaTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      extensions: <ThemeExtension<dynamic>>[
        AppColors.mocha,
        AppTypography.base,
        AppSpacing.base,
        AppRadius.base,
        AppShadows.dark,
      ],
      scaffoldBackgroundColor: AppColors.mocha.background,
      colorScheme: ColorScheme.dark(
        primary: AppColors.mocha.primary,
        secondary: AppColors.mocha.secondary,
        surface: AppColors.mocha.surface,
        background: AppColors.mocha.background,
        error: AppColors.mocha.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.mocha.surface,
        foregroundColor: AppColors.mocha.onSurface,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardTheme(
        color: AppColors.mocha.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.base.medium),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.mocha.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base.large),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.base.medium,
          vertical: AppSpacing.base.small,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mocha.primary,
          foregroundColor: AppColors.mocha.onPrimary,
          elevation: 3,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.base.large,
            vertical: AppSpacing.base.medium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.base.medium),
          ),
        ),
      ),
      textTheme: _buildTextTheme(AppColors.mocha.onBackground),
    );
  }

  static ThemeData _buildCustomTheme() {
    // Similar to _buildLightTheme() but with user-defined yaml
    return _buildLightTheme().copyWith(
      // Add custom overrides
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: AppTypography.base.h1.copyWith(color: textColor),
      displayMedium: AppTypography.base.h2.copyWith(color: textColor),
      displaySmall: AppTypography.base.h3.copyWith(color: textColor),
      headlineMedium: AppTypography.base.h4.copyWith(color: textColor),
      headlineSmall: AppTypography.base.h5.copyWith(color: textColor),
      titleLarge: AppTypography.base.h6.copyWith(color: textColor),
      bodyLarge: AppTypography.base.body1.copyWith(color: textColor),
      bodyMedium: AppTypography.base.body2.copyWith(color: textColor),
    );
  }
}
