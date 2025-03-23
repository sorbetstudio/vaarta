// lib/theme/theme_extensions.dart

import 'package:flutter/material.dart';
import 'package:vaarta/theme/tokens/colors.dart';
import 'package:vaarta/theme/tokens/typography.dart';
import 'package:vaarta/theme/tokens/spacing.dart';
import 'package:vaarta/theme/tokens/radius.dart';
import 'package:vaarta/theme/tokens/shadows.dart';

/// Extension methods to easily access theme extensions
extension ThemeExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  AppColors get colors => theme.extension<AppColors>()!;
  AppTypography get typography => theme.extension<AppTypography>()!;
  AppSpacing get spacing => theme.extension<AppSpacing>()!;
  AppRadius get radius => theme.extension<AppRadius>()!;
  AppShadows get shadows => theme.extension<AppShadows>()!;
}
