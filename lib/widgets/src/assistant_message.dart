// lib/widgets/src/assistant_message.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'thinking_bubble.dart';
import 'tool_call_bubble.dart';
import 'code_block.dart';

/// Represents different types of tokens that can be parsed
enum TokenType {
  thinking,
  toolCall,
  codeBlock,
  plainText,
}

/// Represents a parsed token from the content
class ParsedToken {
  final TokenType type;
  final String content;
  final Map<String, String>? metadata;

  const ParsedToken({
    required this.type,
    required this.content,
    this.metadata,
  });
}

/// Abstract base class for token parsing strategies
abstract class TokenParser {
  List<ParsedToken> parse(String content);
}

/// Improved implementation of token parsing with better code detection
class DefaultTokenParser implements TokenParser {
  @override
  List<ParsedToken> parse(String content) {
    final List<ParsedToken> parsedTokens = [];
    String remainingContent = content;

    // Parse thinking tokens
    final thinkMatches = RegExp(r'<think>([\s\S]*?)<\/think>', multiLine: true).allMatches(content);
    for (final match in thinkMatches) {
      final thinkingContent = match.group(1);
      if (thinkingContent != null && thinkingContent.isNotEmpty) {
        parsedTokens.add(ParsedToken(
          type: TokenType.thinking,
          content: thinkingContent,
        ));
        remainingContent = remainingContent.replaceFirst(match.group(0)!, '').trim();
      }
    }

    // Parse tool call tokens
    final toolMatches = RegExp(r'<tool>([\s\S]*?)<\/tool>', multiLine: true).allMatches(remainingContent);
    for (final match in toolMatches) {
      final toolContent = match.group(1);
      if (toolContent != null && toolContent.isNotEmpty) {
        parsedTokens.add(ParsedToken(
          type: TokenType.toolCall,
          content: toolContent,
        ));
        remainingContent = remainingContent.replaceFirst(match.group(0)!, '').trim();
      }
    }

    // Parse code block tokens - Modified to improve detection
    // First try specific code tags
    final codeMatches = RegExp(r'<code(?:\s+lang="([^"]*)")?>([\s\S]*?)<\/code>', multiLine: true).allMatches(remainingContent);
    for (final match in codeMatches) {
      final codeContent = match.group(2);
      final language = match.group(1);
      if (codeContent != null && codeContent.isNotEmpty) {
        parsedTokens.add(ParsedToken(
          type: TokenType.codeBlock,
          content: codeContent,
          metadata: language != null ? {'language': language} : null,
        ));
        remainingContent = remainingContent.replaceFirst(match.group(0)!, '').trim();
      }
    }

    // Then check for markdown-style code blocks (```code```)
    final markdownCodeMatches = RegExp(r'```([a-z]*)\n([\s\S]*?)```', multiLine: true).allMatches(remainingContent);
    for (final match in markdownCodeMatches) {
      final codeContent = match.group(2);
      final language = match.group(1);
      if (codeContent != null && codeContent.isNotEmpty) {
        parsedTokens.add(ParsedToken(
          type: TokenType.codeBlock,
          content: codeContent,
          metadata: language != null && language.isNotEmpty ? {'language': language} : null,
        ));
        remainingContent = remainingContent.replaceFirst(match.group(0)!, '').trim();
      }
    }

    // Add remaining content as plain text if not empty
    if (remainingContent.isNotEmpty) {
      parsedTokens.add(ParsedToken(
        type: TokenType.plainText,
        content: remainingContent,
      ));
    }

    return parsedTokens;
  }
}

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
  final TokenParser? customTokenParser;

  const AssistantMessage({
    super.key,
    this.messageStream,
    this.content,
    this.config = const AssistantMessageConfig(),
    this.customTokenParser,
  }) : assert(messageStream != null || content != null,
  'Either messageStream or content must be provided');

  @override
  State<AssistantMessage> createState() => _AssistantMessageState();
}

class _AssistantMessageState extends State<AssistantMessage> {
  StreamSubscription<String>? _streamSubscription;
  String _accumulatedContent = '';
  List<ParsedToken> _parsedTokens = [];
  late TokenParser _tokenParser;
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    _tokenParser = widget.customTokenParser ?? DefaultTokenParser();

    if (widget.content != null) {
      _processContent(widget.content!);
    } else if (widget.messageStream != null) {
      _isStreaming = true;
      _setupStreamSubscription();
    }
  }

  void _setupStreamSubscription() {
    _streamSubscription = widget.messageStream!.listen(
          (chunk) {
        _accumulatedContent += chunk;
        _processContent(_accumulatedContent);
      },
      onDone: () {
        setState(() {
          _isStreaming = false;
        });
      },
    );
  }

  @override
  void didUpdateWidget(AssistantMessage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.content != oldWidget.content && widget.content != null) {
      _processContent(widget.content!);
    } else if (widget.messageStream != oldWidget.messageStream) {
      _streamSubscription?.cancel();
      _accumulatedContent = '';
      _parsedTokens = [];

      if (widget.messageStream != null) {
        _isStreaming = true;
        _setupStreamSubscription();
      } else {
        _isStreaming = false;
      }
    }
  }

  void _processContent(String content) {
    setState(() {
      _parsedTokens = _tokenParser.parse(content);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildTokenWidgets(theme, isDark),
    );
  }

  List<Widget> _buildTokenWidgets(ThemeData theme, bool isDark) {
    final List<Widget> widgets = [];

    for (final token in _parsedTokens) {
      switch (token.type) {
        case TokenType.thinking:
          widgets.add(ThinkingBubble(content: token.content));
          break;
        case TokenType.toolCall:
          widgets.add(ToolCallBubble(content: token.content));
          break;
        case TokenType.codeBlock:
        // Create CodeBlock with either direct content or a content stream
          if (_isStreaming) {
            // For streaming, we need to create a stream controller that can be updated
            // with each tokenization pass
            final controller = StreamController<String>();
            controller.add(token.content);
            widgets.add(CodeBlock(
              contentStream: controller.stream,
              language: token.metadata?['language'],
            ));
            // Schedule closure after the build is complete
            Future.microtask(() => controller.close());
          } else {
            widgets.add(CodeBlock(
              content: token.content,
              language: token.metadata?['language'],
            ));
          }
          break;
        case TokenType.plainText:
          if (token.content.isNotEmpty) {
            widgets.add(_buildMarkdownContent(token.content, theme, isDark));
          }
          break;
      }
    }

    return widgets;
  }

  Widget _buildMarkdownContent(String content, ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface
            : theme.colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: MarkdownBody(
        data: content,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 16,
          ),
          code: TextStyle(
            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
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
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
