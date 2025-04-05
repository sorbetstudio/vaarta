// lib/widgets/message_components/thinking_bubble.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vaarta/theme/theme_extensions.dart'; // Import theme extensions

// A collapsible widget to display thinking content in a styled bubble
class ThinkingBubble extends StatefulWidget {
  final String content; // The content to display inside the bubble

  const ThinkingBubble({super.key, required this.content});

  @override
  State<ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use theme extensions for colors
    final primaryColor = context.colors.primary;
    final onSurfaceColor = context.colors.onSurface;
    // final primaryContainerColor = context.colors.primaryContainer; // Incorrect - use theme.colorScheme
    final primaryContainerColor =
        theme.colorScheme.primaryContainer; // Use standard ColorScheme
    final backgroundColor =
        theme.brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.grey.shade200;
    final codeBackgroundColor =
        theme.brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade200;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: primaryContainerColor.withOpacity(
          0.15,
        ), // Use variable from ColorScheme
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.3), // Use theme extension
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
                _isExpanded
                    ? _expandController.forward()
                    : _expandController.reverse();
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    color: primaryColor, // Use theme extension
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thinking Process',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor, // Use theme extension
                    ),
                  ),
                  const Spacer(),
                  RotationTransition(
                    turns: Tween(
                      begin: 0.0,
                      end: 0.5,
                    ).animate(_expandAnimation),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: primaryColor, // Use theme extension
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: SizeTransition(
              sizeFactor: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: MarkdownBody(
                  data: widget.content,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: onSurfaceColor.withOpacity(
                        0.9,
                      ), // Use theme extension
                      fontSize: 14,
                    ),
                    code: TextStyle(
                      backgroundColor: codeBackgroundColor, // Use variable
                      color: onSurfaceColor, // Use theme extension
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: backgroundColor, // Use variable
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
