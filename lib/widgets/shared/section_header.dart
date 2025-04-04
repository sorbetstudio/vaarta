import 'package:flutter/material.dart';
import 'package:vaarta/theme/theme_extensions.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const SectionHeader(this.title, {super.key, this.textStyle, this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: context.spacing.medium,
            vertical: context.spacing.small,
          ),
      child: Text(
        title,
        style:
            textStyle ??
            context.typography.h6.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
