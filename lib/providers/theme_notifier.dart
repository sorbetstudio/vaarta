// lib/providers/theme_notifier.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaarta/theme/theme_config.dart';

part 'theme_notifier.g.dart';

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  static const _themeKey = 'app_theme';

  @override
  Future<AppTheme> build() async {
    return _loadTheme();
  }

  Future<AppTheme> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    return AppTheme.values.firstWhere(
      (e) => e.name == themeString,
      orElse: () => AppTheme.system,
    );
  }

  Future<void> setTheme(AppTheme theme) async {
    state = const AsyncLoading();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme.name);
      state = AsyncData(theme);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}

@riverpod
ThemeMode themeMode(Ref ref) {
  final themeAsync = ref.watch(themeNotifierProvider);

  return themeAsync.when(
    loading: () => ThemeMode.system,
    error: (_, __) => ThemeMode.system,
    data:
        (theme) => switch (theme) {
          AppTheme.light => ThemeMode.light,
          AppTheme.dark => ThemeMode.dark,
          AppTheme.mocha => ThemeMode.dark, //mocka is
          AppTheme.custom => ThemeMode.light,
          //todo: Custom brightness would be fixed later
          AppTheme.system => ThemeMode.system,
        },
  );
}
