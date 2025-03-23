// lib/theme/tokens/radius.dart

import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;

class AppRadius extends ThemeExtension<AppRadius> {
  final double small;
  final double medium;
  final double large;
  final double extraLarge;
  final double circle;

  const AppRadius({
    required this.small,
    required this.medium,
    required this.large,
    required this.extraLarge,
    required this.circle,
  });

  // Base radius from Figma
  static const base = AppRadius(
    small: 4.0,
    medium: 8.0,
    large: 16.0,
    extraLarge: 24.0,
    circle: 999.0,
  );

  @override
  ThemeExtension<AppRadius> copyWith({
    double? small,
    double? medium,
    double? large,
    double? extraLarge,
    double? circle,
  }) {
    return AppRadius(
      small: small ?? this.small,
      medium: medium ?? this.medium,
      large: large ?? this.large,
      extraLarge: extraLarge ?? this.extraLarge,
      circle: circle ?? this.circle,
    );
  }

  @override
  ThemeExtension<AppRadius> lerp(ThemeExtension<AppRadius>? other, double t) {
    if (other is! AppRadius) {
      return this;
    }
    return AppRadius(
      small: lerpDouble(small, other.small, t)!,
      medium: lerpDouble(medium, other.medium, t)!,
      large: lerpDouble(large, other.large, t)!,
      extraLarge: lerpDouble(extraLarge, other.extraLarge, t)!,
      circle: lerpDouble(circle, other.circle, t)!,
    );
  }
}
