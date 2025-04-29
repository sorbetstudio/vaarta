// lib/theme/icons/app_icons.dart

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// App icons generated from Figma
class AppIcons {
  AppIcons._();

  // Method to get SVG icon from assets
  static Widget svg(
    String name, {
    double? width,
    double? height,
    Color? color,
  }) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: width,
      height: height,
      colorFilter:
          color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }

  // Define icon constants - can be auto-generated from Figma
  static const String chat = 'chat';
  static const String send = 'send';
  static const String settings = 'settings';
  static const String delete = 'delete';
  static const String add = 'add';
  static const String edit = 'edit';
  static const String close = 'close';
  static const String menu = 'menu';
  static const String search = 'search';
  static const String profile = 'profile';
  // Add more icons as needed
}

/// Icon component for easy usage
class AppIcon extends StatelessWidget {
  final String icon;
  final double? size;
  final Color? color;

  const AppIcon(this.icon, {super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return AppIcons.svg(icon, width: size, height: size, color: color);
  }
}
