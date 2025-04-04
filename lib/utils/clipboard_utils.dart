import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vaarta/theme/theme_extensions.dart';

/// Copies text to clipboard and shows feedback
Future<void> copyToClipboard({
  required BuildContext context,
  required String text,
  bool useHapticFeedback = true,
}) async {
  await Clipboard.setData(ClipboardData(text: text));

  if (useHapticFeedback) {
    await HapticFeedback.lightImpact();
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Copied to clipboard', style: context.typography.body2),
      backgroundColor: context.colors.surface,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
    ),
  );
}
