// lib/screens/settings/settings_theme_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaarta/providers/theme_notifier.dart';
import 'package:vaarta/theme/theme_config.dart';
import 'package:vaarta/theme/theme_extensions.dart';

class SettingsThemeSelector extends ConsumerWidget {
  const SettingsThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeNotifierProvider);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.medium,
        vertical: context.spacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Theme Mode", style: context.typography.body1),
          const SizedBox(height: 8),
          Card(
            color: context.colors.surfaceVariant,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.radius.medium),
            ),
            child: Column(
              children:
                  AppTheme.values.map((theme) {
                    final isSelected = currentTheme.valueOrNull == theme;
                    return ListTile(
                      leading: Icon(
                        theme.icon,
                        color:
                            isSelected
                                ? context.colors.primary
                                : context.colors.onSurface.withAlpha(150),
                      ),
                      title: Text(
                        theme.label,
                        style: context.typography.body1.copyWith(
                          color: context.colors.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing:
                          isSelected
                              ? Icon(
                                Icons.check_circle,
                                color: context.colors.primary,
                              )
                              : null,
                      onTap: () {
                        ref
                            .read(themeNotifierProvider.notifier)
                            .setTheme(theme);
                      },
                      tileColor:
                          isSelected
                              ? context.colors.primary.withAlpha(25)
                              : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.radius.small,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
