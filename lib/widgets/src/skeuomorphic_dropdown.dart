import 'package:flutter/material.dart';

/// A skeuomorphic dropdown menu with a custom appearance for light and dark themes.
class SkeuomorphicDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const SkeuomorphicDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF444444) : Colors.grey.shade200;
    final textColor = isDark ? Colors.grey[200] : Colors.grey[700];
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade400;
    final shadowColor = isDark ? Colors.black87 : Colors.grey.shade400;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dropdownColor: backgroundColor,
        items: items,
        onChanged: onChanged,
        style: TextStyle(color: textColor, fontFamily: 'Arial'),
      ),
    );
  }
}