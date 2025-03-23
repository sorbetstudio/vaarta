// lib/theme/theme_config.dart

import 'package:flutter/material.dart';

enum AppTheme {
  system,
  light,
  dark,
  mocha,
  custom;

  String get label => switch (this) {
    AppTheme.system => 'System',
    AppTheme.light => 'Light',
    AppTheme.dark => 'Dark',
    AppTheme.mocha => 'Mocha',
    AppTheme.custom => 'Custom',
  };

  IconData get icon => switch (this) {
    AppTheme.system => Icons.brightness_auto,
    AppTheme.light => Icons.light_mode,
    AppTheme.dark => Icons.dark_mode,
    AppTheme.mocha => Icons.coffee,
    AppTheme.custom => Icons.settings,
  };
}
