import 'package:flutter/material.dart';

/// A skeuomorphic toggle switch with a sliding thumb, styled for light and dark themes.
class SkeuomorphicToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;

  const SkeuomorphicToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 60.0,
    this.height = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark ? const Color(0xFF444444) : Colors.grey.shade300;
    final thumbColor = isDark ? const Color(0xFFDDDDDD) : Colors.grey.shade100;
    final shadowColor = isDark ? Colors.black87 : Colors.grey.shade400;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          color: value ? Colors.blue.shade300 : trackColor,
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: AnimatedAlign(
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Container(
              width: height - 4,
              height: height - 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: thumbColor,
                border: Border.all(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}