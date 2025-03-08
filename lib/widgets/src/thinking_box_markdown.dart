import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// A widget that displays markdown content with an expandable "thinking" section
class ThinkingBoxMarkdownWidget extends StatefulWidget {
  final String markdownContent; // The markdown text to display
  final MarkdownStyleSheet styleSheet; // Styling for the markdown content

  const ThinkingBoxMarkdownWidget({
    Key? key,
    required this.markdownContent,
    required this.styleSheet,
  }) : super(key: key);

  @override
  State<ThinkingBoxMarkdownWidget> createState() => _ThinkingBoxMarkdownWidgetState();
}

class _ThinkingBoxMarkdownWidgetState extends State<ThinkingBoxMarkdownWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _expanded = false;
  bool _hasThinkingContent = false;
  String _thinkingContent = '';
  String _processedMarkdown = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _processContent();
  }

  // Extracts <think> tags and separates thinking content from the main markdown
  void _processContent() {
    final content = widget.markdownContent;
    final thinkRegex = RegExp(r'<think>([\s\S]*?)<\/think>', multiLine: true);

    if (thinkRegex.hasMatch(content)) {
      _hasThinkingContent = true;
      _thinkingContent = thinkRegex
          .allMatches(content)
          .map((match) => match.group(1) ?? '')
          .join('\n\n');
      _processedMarkdown = content.replaceAll(thinkRegex, '').trim();
    } else {
      _hasThinkingContent = false;
      _processedMarkdown = content;
    }
  }

  @override
  void didUpdateWidget(ThinkingBoxMarkdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markdownContent != widget.markdownContent) {
      _processContent();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasThinkingContent) ...[
          InkWell(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
                _expanded ? _controller.forward() : _controller.reverse();
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha:0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha:0.5),
                  width: 1,
                ),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.psychology,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Thinking Process',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        RotationTransition(
                          turns: Tween(begin: 0.0, end: 0.5).animate(_animation),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRect(
                    child: SizeTransition(
                      sizeFactor: _animation,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: MarkdownBody(
                          data: _thinkingContent,
                          styleSheet: widget.styleSheet,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        MarkdownBody(data: _processedMarkdown, styleSheet: widget.styleSheet),
      ],
    );
  }
}