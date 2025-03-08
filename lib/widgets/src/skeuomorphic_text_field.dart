import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A skeuomorphic text field with a custom style, supporting multiple lines and input formatting.
class SkeuomorphicTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const SkeuomorphicTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.maxLines = 1,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF444444) : Colors.grey.shade200;
    final textColor = isDark ? Colors.grey[200] : Colors.grey[700];
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade400;
    final shadowColor = isDark ? Colors.black87 : Colors.grey.shade400;

    return Container(
      decoration: BoxDecoration(
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
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        maxLines: maxLines,
        style: TextStyle(color: textColor, fontFamily: 'Arial'),
        onChanged: onChanged,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: textColor?.withValues(alpha: 0.6) ?? Colors.grey.withValues(alpha: 0.6),
          ),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}