// lib/widgets/src/assistant_message.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vaarta/theme/theme_extensions.dart';
import 'package:gpt_markdown/gpt_markdown.dart'; // Import gpt_markdown

// import 'thinking_bubble.dart'; // Commented out as thinking bubble logic is removed
// import 'tool_call_bubble.dart'; // Removed as tool call bubble logic is removed
// import 'code_block.dart'; // Removed as code block rendering is handled by gpt_markdown

/// Configuration for AssistantMessage rendering
class AssistantMessageConfig {
  final bool enableLogging;
  final Duration streamTimeout;
  final bool enableMarkdown;

  const AssistantMessageConfig({
    this.enableLogging = false,
    this.streamTimeout = const Duration(seconds: 30),
    this.enableMarkdown = true,
  });
}

/// Widget for rendering assistant messages with support for streaming and static content
class AssistantMessage extends StatefulWidget {
  final Stream<String>? messageStream;
  final String? content;
  final AssistantMessageConfig config;
  const AssistantMessage({
    super.key,
    this.messageStream,
    this.content,
    this.config = const AssistantMessageConfig(),
  }) : assert(
         messageStream != null || content != null,
         'Either messageStream or content must be provided',
       );

  @override
  State<AssistantMessage> createState() => _AssistantMessageState();
}

class _AssistantMessageState extends State<AssistantMessage> {
  StreamSubscription<String>? _streamSubscription;
  String _content = '';

  @override
  void initState() {
    super.initState();
    if (widget.content != null) {
      _content = widget.content!;
    } else if (widget.messageStream != null) {
      _setupStreamSubscription();
    }
  }

  void _setupStreamSubscription() {
    _streamSubscription = widget.messageStream!.listen((chunk) {
      setState(() {
        _content += chunk;
      });
    });
  }

  @override
  void didUpdateWidget(AssistantMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.content != oldWidget.content && widget.content != null) {
      setState(() {
        _content = widget.content!;
      });
    } else if (widget.messageStream != oldWidget.messageStream) {
      _streamSubscription?.cancel();
      _content = '';
      if (widget.messageStream != null) {
        _setupStreamSubscription();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return _buildMarkdownContent(_content, theme, isDark, context);
  }

  Widget _buildMarkdownContent(
    String content,
    ThemeData theme,
    bool isDark,
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDark
                ? context.colors.background
                : context.colors.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.symmetric(
        vertical: context.spacing.small,
        horizontal: context.spacing.tiny,
      ),
      child: GptMarkdown(
        content,
        style: context.typography.serif,
        components: [
          CodeBlockMd(),
          NewLines(),
          BlockQuote(),
          ImageMd(),
          ATagMd(),
          TableMd(),
          HTag(),
          UnOrderedList(),
          OrderedList(),
          CheckBoxMd(),
          HrLine(),
          StrikeMd(),
          BoldMd(),
          ItalicMd(),
        ],
        inlineComponents: [
          ImageMd(),
          ATagMd(),
          TableMd(),
          StrikeMd(),
          BoldMd(),
          ItalicMd(),
        ],
        // Simplified configuration while maintaining core markdown features
      ),
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
