// lib/theme/tokens/spacing.dart

import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;

class AppSpacing extends ThemeExtension<AppSpacing> {
  final double tiny;
  final double extraSmall;
  final double small;
  final double medium;
  final double large;
  final double extraLarge;
  final double huge;

  const AppSpacing({
    required this.tiny,
    required this.extraSmall,
    required this.small,
    required this.medium,
    required this.large,
    required this.extraLarge,
    required this.huge,
  });

  // Base spacing from Figma
  static const base = AppSpacing(
    tiny: 2.0,
    extraSmall: 4.0,
    small: 8.0,
    medium: 16.0,
    large: 24.0,
    extraLarge: 32.0,
    huge: 48.0,
  );

  @override
  ThemeExtension<AppSpacing> copyWith({
    double? tiny,
    double? extraSmall,
    double? small,
    double? medium,
    double? large,
    double? extraLarge,
    double? huge,
  }) {
    return AppSpacing(
      tiny: tiny ?? this.tiny,
      extraSmall: extraSmall ?? this.extraSmall,
      small: small ?? this.small,
      medium: medium ?? this.medium,
      large: large ?? this.large,
      extraLarge: extraLarge ?? this.extraLarge,
      huge: huge ?? this.huge,
    );
  }

  @override
  ThemeExtension<AppSpacing> lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) {
      return this;
    }
    return AppSpacing(
      tiny: lerpDouble(tiny, other.tiny, t)!,
      extraSmall: lerpDouble(extraSmall, other.extraSmall, t)!,
      small: lerpDouble(small, other.small, t)!,
      medium: lerpDouble(medium, other.medium, t)!,
      large: lerpDouble(large, other.large, t)!,
      extraLarge: lerpDouble(extraLarge, other.extraLarge, t)!,
      huge: lerpDouble(huge, other.huge, t)!,
    );
  }
}
