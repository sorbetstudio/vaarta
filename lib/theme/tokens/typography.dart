// lib/theme/tokens/typography.dart

import 'package:flutter/material.dart';

class AppTypography extends ThemeExtension<AppTypography> {
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle h4;
  final TextStyle h5;
  final TextStyle h6;
  final TextStyle body1;
  final TextStyle body2;
  final TextStyle caption;
  final TextStyle button;

  const AppTypography({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
    required this.h5,
    required this.h6,
    required this.body1,
    required this.body2,
    required this.caption,
    required this.button,
  });

  // Base typography from Figma
  static const base = AppTypography(
    h1: TextStyle(
      fontFamily: 'Satoshi',
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      height: 1.3,
    ),
    h2: TextStyle(
      fontFamily: 'Satoshi',
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      height: 1.3,
    ),
    h3: TextStyle(
      fontFamily: 'Satoshi',
      fontSize: 24,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      height: 1.3,
    ),
    h4: TextStyle(
      fontFamily: 'Satoshi',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      height: 1.3,
    ),
    h5: TextStyle(
      fontFamily: 'Satoshi',
      fontSize: 18,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      height: 1.3,
    ),
    h6: TextStyle(
      fontFamily: 'Satoshi',
      fontSize: 16,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      height: 1.3,
    ),
    body1: TextStyle(
      fontFamily: 'Satoshi',
      fontSize: 16,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.15,
      height: 1.5,
    ),
    body2: TextStyle(
      fontFamily: 'Satoshi',
      fontSize: 14,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.15,
      height: 1.5,
    ),
    caption: TextStyle(
      fontFamily: 'Satoshi',
      fontSize: 12,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.4,
      height: 1.5,
    ),
    button: TextStyle(
      fontFamily: 'Satoshi',
      fontSize: 14,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.75,
      height: 1.5,
    ),
  );

  @override
  ThemeExtension<AppTypography> copyWith({
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? h4,
    TextStyle? h5,
    TextStyle? h6,
    TextStyle? body1,
    TextStyle? body2,
    TextStyle? caption,
    TextStyle? button,
  }) {
    return AppTypography(
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      h4: h4 ?? this.h4,
      h5: h5 ?? this.h5,
      h6: h6 ?? this.h6,
      body1: body1 ?? this.body1,
      body2: body2 ?? this.body2,
      caption: caption ?? this.caption,
      button: button ?? this.button,
    );
  }

  @override
  ThemeExtension<AppTypography> lerp(
    ThemeExtension<AppTypography>? other,
    double t,
  ) {
    if (other is! AppTypography) {
      return this;
    }
    return AppTypography(
      h1: TextStyle.lerp(h1, other.h1, t)!,
      h2: TextStyle.lerp(h2, other.h2, t)!,
      h3: TextStyle.lerp(h3, other.h3, t)!,
      h4: TextStyle.lerp(h4, other.h4, t)!,
      h5: TextStyle.lerp(h5, other.h5, t)!,
      h6: TextStyle.lerp(h6, other.h6, t)!,
      body1: TextStyle.lerp(body1, other.body1, t)!,
      body2: TextStyle.lerp(body2, other.body2, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
    );
  }
}
