// lib/providers/theme_notifier.dart

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_notifier.g.dart'; // Add this line!  Tells Riverpod to generate code

@riverpod
class ThemeNotifier extends _$ThemeNotifier { // _$ThemeNotifier is a generated mixin
  @override
  ThemeMode build() { // Must return the initial state (ThemeMode)
    // We'll handle initial loading *inside* build() now.
    _initializeTheme(); // Call a helper method to load the preference.
    return ThemeMode.system; // Return a default value *for now*.
  }

  Future<void> _initializeTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('darkMode') ?? false;
    state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // Use pattern matching for more concise state check
    switch (state) {
      case ThemeMode.dark:
        state = ThemeMode.light;
        await prefs.setBool('darkMode', false);
      case ThemeMode.light:
        state = ThemeMode.dark;
        await prefs.setBool('darkMode', true);
      case ThemeMode.system:
      // If it's system, we'll toggle to dark for simplicity.
      //  A more robust implementation would check the system's actual theme.
        state = ThemeMode.system;
        await prefs.setBool('darkMode', true);
    }
  }
}