// lib/theme/tokens/shadows.dart

import 'package:flutter/material.dart';

class AppShadows extends ThemeExtension<AppShadows> {
  final List<BoxShadow> small;
  final List<BoxShadow> medium;
  final List<BoxShadow> large;

  const AppShadows({
    required this.small,
    required this.medium,
    required this.large,
  });

  // Light theme shadows from Figma
  static const light = AppShadows(
    small: [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.05),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
    medium: [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.1),
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
    large: [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.1),
        blurRadius: 16,
        offset: Offset(0, 8),
      ),
    ],
  );

  // Dark theme shadows from Figma
  static const dark = AppShadows(
    small: [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.3),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
    medium: [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.4),
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
    large: [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.5),
        blurRadius: 16,
        offset: Offset(0, 8),
      ),
    ],
  );

  @override
  ThemeExtension<AppShadows> copyWith({
    List<BoxShadow>? small,
    List<BoxShadow>? medium,
    List<BoxShadow>? large,
  }) {
    return AppShadows(
      small: small ?? this.small,
      medium: medium ?? this.medium,
      large: large ?? this.large,
    );
  }

  @override
  ThemeExtension<AppShadows> lerp(ThemeExtension<AppShadows>? other, double t) {
    if (other is! AppShadows) {
      return this;
    }

    List<BoxShadow> lerpShadowList(
      List<BoxShadow> a,
      List<BoxShadow> b,
      double t,
    ) {
      final int length = a.length;
      return List<BoxShadow>.generate(length, (i) {
        return BoxShadow.lerp(a[i], b[i], t)!;
      });
    }

    return AppShadows(
      small: lerpShadowList(small, other.small, t),
      medium: lerpShadowList(medium, other.medium, t),
      large: lerpShadowList(large, other.large, t),
    );
  }
}
