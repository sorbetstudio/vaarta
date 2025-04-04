// lib/screens/settings/settings_api_key.dart
import 'package:flutter/material.dart';
import 'package:vaarta/theme/theme_extensions.dart';

class SettingsApiKeyInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SettingsApiKeyInput({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.medium,
        vertical: context.spacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("API Key", style: context.typography.body1),
          SizedBox(height: context.spacing.small),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "Enter your API key",
              filled: true,
              fillColor: context.colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.radius.medium),
                borderSide: BorderSide(color: context.colors.outline),
              ),
              prefixIcon: Icon(Icons.key, color: context.colors.primary),
            ),
            obscureText: true,
            onChanged: onChanged, // Use the passed callback
          ),
          SizedBox(height: context.spacing.small),
          Text(
            "Your API key is stored only on this device",
            style: context.typography.caption.copyWith(
              color: context.colors.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }
}
