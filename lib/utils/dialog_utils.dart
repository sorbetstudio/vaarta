import 'package:flutter/material.dart';
import 'package:vaarta/theme/theme_extensions.dart';

/// Shows a confirmation dialog with customizable title, content and actions
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  Color confirmColor = Colors.red,
}) async {
  return await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(title, style: context.typography.h6),
          content: Text(content, style: context.typography.body1),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText, style: context.typography.button),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                confirmText,
                style: context.typography.button.copyWith(color: confirmColor),
              ),
            ),
          ],
        ),
  );
}

/// Shows a text input dialog with customizable title, hint and actions
Future<String?> showTextInputDialog({
  required BuildContext context,
  required String title,
  String hintText = '',
  String initialValue = '',
  String confirmText = 'Save',
  String cancelText = 'Cancel',
}) async {
  final controller = TextEditingController(text: initialValue);

  return await showDialog<String>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(title, style: context.typography.h6),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: context.typography.body1.copyWith(
                color: context.colors.onBackground.withOpacity(0.5),
              ),
            ),
            style: context.typography.body1,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(cancelText, style: context.typography.button),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.of(context).pop(value);
                }
              },
              child: Text(confirmText, style: context.typography.button),
            ),
          ],
        ),
  );
}
