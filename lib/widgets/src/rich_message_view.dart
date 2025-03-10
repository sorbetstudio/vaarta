// lib/widgets/src/rich_message_view.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'thinking_bubble.dart';
import 'tool_call_bubble.dart';
import 'code_block.dart';

/// A widget that displays streaming content with support for special tokens
/// such as thinking, tool calls, and code blocks
class RichMessageView extends StatefulWidget {
  // Stream of message content as it arrives
  final Stream<String>? messageStream;

  // Static content when not streaming
  final String? content;

  const RichMessageView({
    super.key,
    this.messageStream,
    this.content,
  }) : assert(messageStream != null || content != null,
  'Either messageStream or content must be provided');

  @override
  State<RichMessageView> createState() => _RichMessageViewState();
}

class _RichMessageViewState extends State<RichMessageView> {
  // Fixed: Removed 'late' keyword, kept it as nullable
  StreamSubscription<String>? _streamSubscription;
  String _accumulatedContent = '';

  // Extracted content segments
  String _thinkingContent = '';
  List<String> _toolCalls = [];
  List<Map<String, String>> _codeBlocks = []; // [{content: '...', language: '...'}]
  String _plainContent = '';

  // Regular expressions for parsing special tokens
  final RegExp _thinkRegex = RegExp(r'<think>([\s\S]*?)<\/think>', multiLine: true);
  final RegExp _toolRegex = RegExp(r'<tool>([\s\S]*?)<\/tool>', multiLine: true);
  // Improved regex for code blocks to better handle multi-line content and optional language attribute
  final RegExp _codeRegex = RegExp(r'<code(?:\s+lang="([^"]*)")?>([\s\S]*?)<\/code>', multiLine: true);


  @override
  void initState() {
    super.initState();
    if (widget.content != null) {
      _processContent(widget.content!);
    } else if (widget.messageStream != null) {
      _streamSubscription = widget.messageStream!.listen(_handleStreamUpdate);
    }
  }

  @override
  void didUpdateWidget(RichMessageView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle changes in content or stream
    if (widget.content != oldWidget.content && widget.content != null) {
      _processContent(widget.content!);
    } else if (widget.messageStream != oldWidget.messageStream) {
      _streamSubscription?.cancel();
      if (widget.messageStream != null) {
        _streamSubscription = widget.messageStream!.listen(_handleStreamUpdate);
      }
    }
  }

  void _handleStreamUpdate(String chunk) {
    _accumulatedContent += chunk;
    _processContent(_accumulatedContent);
  }

  /// Process the content string and extract special tokens
  void _processContent(String content) {
    setState(() {
      // Extract thinking content
      _thinkingContent = '';
      if (_thinkRegex.hasMatch(content)) {
        _thinkingContent = _thinkRegex
            .allMatches(content)
            .map((match) => match.group(1) ?? '')
            .join('\n\n');
      }

      // Extract tool calls
      _toolCalls = [];
      if (_toolRegex.hasMatch(content)) {
        _toolCalls = _toolRegex
            .allMatches(content)
            .map((match) => match.group(1) ?? '')
            .toList();
      }

      // Extract code blocks with optional language
      _codeBlocks = [];
      if (_codeRegex.hasMatch(content)) {
        _codeBlocks = _codeRegex
            .allMatches(content)
            .map((match) => {
          'language': match.group(1) ?? '',
          //Corrected content extraction
          'content': match.group(2) ?? '',
        })
            .toList();
      }

      // Remove all special tokens for plain content
      _plainContent = content
          .replaceAll(_thinkRegex, '')
          .replaceAll(_toolRegex, '')
          .replaceAll(_codeRegex, '')
          .trim();
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thinking bubble (if thinking content exists)
        if (_thinkingContent.isNotEmpty)
          ThinkingBubble(content: _thinkingContent),

        // Tool call bubbles
        ..._toolCalls.map((toolCall) => ToolCallBubble(content: toolCall)),

        // Code blocks
        ..._codeBlocks.map((codeBlock) => CodeBlock(
          content: codeBlock['content'] ?? '',
          language: codeBlock['language'],
        )),

        // Main message content
        if (_plainContent.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: MarkdownBody(
              data: _plainContent,
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