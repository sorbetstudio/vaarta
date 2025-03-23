// lib/widgets/theme_toggle.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaarta/providers/theme_notifier.dart';
import 'package:vaarta/theme/theme_config.dart';
import 'package:vaarta/theme/theme_extensions.dart';

class ThemeToggle extends ConsumerWidget {
  final bool isCompact;

  const ThemeToggle({Key? key, this.isCompact = false}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeNotifierProvider);

    return themeAsync.when(
      loading:
          () => const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      error: (_, __) => const Icon(Icons.error),
      data:
          (currentTheme) =>
              isCompact
                  ? _buildCompactToggle(context, ref, currentTheme)
                  : _buildFullToggle(context, ref, currentTheme),
    );
  }

  Widget _buildCompactToggle(
    BuildContext context,
    WidgetRef ref,
    AppTheme currentTheme,
  ) {
    final icon = switch (currentTheme) {
      AppTheme.light => Icons.dark_mode,
      AppTheme.dark => Icons.light_mode,
      _ => Icons.brightness_auto,
    };

    return IconButton(
      icon: Icon(icon),
      tooltip: 'Toggle theme',
      onPressed: () {
        ref.read(themeNotifierProvider.notifier).toggleTheme();
      },
    );
  }

  Widget _buildFullToggle(
    BuildContext context,
    WidgetRef ref,
    AppTheme currentTheme,
  ) {
    return PopupMenuButton<AppTheme>(
      initialValue: currentTheme,
      tooltip: 'Select theme',
      onSelected: (theme) {
        ref.read(themeNotifierProvider.notifier).setTheme(theme);
      },
      itemBuilder:
          (context) =>
              AppTheme.values.map((theme) {
                return PopupMenuItem(
                  value: theme,
                  child: Row(
                    children: [
                      Icon(theme.icon, color: context.colors.primary),
                      SizedBox(width: context.spacing.small),
                      Text(theme.label, style: context.typography.body1),
                    ],
                  ),
                );
              }).toList(),
      child: Padding(
        padding: EdgeInsets.all(context.spacing.small),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(currentTheme.icon),
            if (!isCompact) ...[
              SizedBox(width: context.spacing.small),
              Text(currentTheme.label),
              SizedBox(width: context.spacing.small),
              const Icon(Icons.arrow_drop_down),
            ],
          ],
        ),
      ),
    );
  }
}
