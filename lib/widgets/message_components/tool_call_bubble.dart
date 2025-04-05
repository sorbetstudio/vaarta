// lib/widgets/message_components/tool_call_bubble.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vaarta/theme/theme_extensions.dart'; // Import theme extensions

/// A widget that displays tool calls in a styled bubble
class ToolCallBubble extends StatefulWidget {
  final String content; // The tool call content to display

  const ToolCallBubble({super.key, required this.content});

  @override
  State<ToolCallBubble> createState() => _ToolCallBubbleState();
}

class _ToolCallBubbleState extends State<ToolCallBubble>
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
    // Use theme extensions and standard ColorScheme
    final tertiaryColor =
        theme.colorScheme.tertiary; // Use standard ColorScheme
    final onSurfaceColor = context.colors.onSurface; // Custom theme extension
    final tertiaryContainerColor =
        theme.colorScheme.tertiaryContainer; // Standard ColorScheme
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
        color: tertiaryContainerColor.withOpacity(
          0.15,
        ), // Use variable from ColorScheme
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tertiaryColor.withOpacity(
            0.3,
          ), // Use variable from theme extension
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
                    Icons.build_outlined,
                    color: tertiaryColor, // Use variable
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tool Call',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tertiaryColor, // Use variable
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
                      color: tertiaryColor, // Use variable
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
                      color: onSurfaceColor.withOpacity(0.9), // Use variable
                      fontSize: 14,
                    ),
                    code: TextStyle(
                      backgroundColor: codeBackgroundColor, // Use variable
                      color: onSurfaceColor, // Use variable
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
