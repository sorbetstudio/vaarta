import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'thinking_bubble.dart';

// A widget to display streaming content with an optional thinking bubble
class StreamingMessage extends StatelessWidget {
  final String content; // The content to display, possibly with <think> tags

  const StreamingMessage({Key? key, required this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final thinkRegex = RegExp(r'<think>([\s\S]*?)<\/think>', multiLine: true);
    String thinkingContent = '';
    String outputContent = content;

    if (thinkRegex.hasMatch(content)) {
      thinkingContent = thinkRegex
          .allMatches(content)
          .map((match) => match.group(1) ?? '')
          .join('\n\n');
      outputContent = content.replaceAll(thinkRegex, '').trim();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (thinkingContent.isNotEmpty)
          ThinkingBubble(content: thinkingContent),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surface
                : theme.colorScheme.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: MarkdownBody(
            data: outputContent,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 16,
              ),
              code: TextStyle(
                backgroundColor:
                isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                color: theme.colorScheme.onSurface,
                fontFamily: 'monospace',
              ),
              codeblockDecoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              blockquoteDecoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: theme.dividerColor, width: 4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}