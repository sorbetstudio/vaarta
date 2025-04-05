// lib/widgets/src/assistant_message.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logging/logging.dart'; // Import logger
import 'package:vaarta/theme/theme_extensions.dart';
import '../message_components/thinking_bubble.dart';
import '../message_components/tool_call_bubble.dart';
import '../message_components/code_block.dart';
import '../message_components/processing_animation.dart';
import '../../utils/token_parser.dart';

// Added logger instance
final _logger = Logger('AssistantMessageWidget');

/// Configuration for AssistantMessage rendering
class AssistantMessageConfig {
  final bool enableLogging;
  final Duration streamTimeout;
  final bool enableMarkdown;

  const AssistantMessageConfig({
    this.enableLogging = false,
    this.streamTimeout = const Duration(seconds: 30),
    this.enableMarkdown = true, // Keep markdown enabled by default
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
  }) : assert(
         messageStream != null || content != null,
         'Either messageStream or content must be provided',
       );

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
      _processContent(widget.content!); // Process static content
    } else if (widget.messageStream != null) {
      _isStreaming = true; // Set streaming flag
      _setupStreamSubscription(); // Start listening
    }
  }

  void _setupStreamSubscription() {
    _logger.fine("Setting up stream subscription");
    _streamSubscription = widget.messageStream!.listen(
      (chunk) {
        _accumulatedContent += chunk;
        // Re-parse the entire content on each chunk
        if (mounted) {
          _logger.finest(
            "Chunk received, processing content. Len: ${_accumulatedContent.length}",
          );
          _processContent(_accumulatedContent);
        }
      },
      onDone: () {
        _logger.fine("Stream done received");
        if (mounted) {
          setState(() {
            _isStreaming = false; // Clear streaming flag when done
          });
        }
      },
      onError: (error) {
        _logger.warning(
          "Error in AssistantMessage stream: $error",
        ); // Add logging
        if (mounted) {
          setState(() {
            _isStreaming = false;
            // Optionally display error state in UI if needed
            _parsedTokens = [
              ParsedToken(
                type: TokenType.plainText,
                content: "Error: $error",
                startIndex: 0,
                endIndex: 0,
              ),
            ];
          });
        }
      },
      cancelOnError: true, // Cancel subscription on error
    );
  }

  @override
  void didUpdateWidget(AssistantMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _logger.fine("didUpdateWidget called");

    // Handle changes in static content
    if (widget.content != oldWidget.content && widget.content != null) {
      _logger.fine("Static content changed");
      _streamSubscription?.cancel(); // Cancel any active stream
      _isStreaming = false;
      _accumulatedContent = widget.content!; // Reset accumulated
      _processContent(_accumulatedContent); // Process new static content
    }
    // Handle changes in the stream source
    else if (widget.messageStream != oldWidget.messageStream) {
      _logger.fine("Stream source changed");
      _streamSubscription?.cancel(); // Cancel old subscription
      _accumulatedContent = ''; // Reset content
      _parsedTokens = []; // Reset tokens

      if (widget.messageStream != null) {
        _isStreaming = true;
        _setupStreamSubscription(); // Set up new subscription
      } else {
        _isStreaming = false; // No stream provided
      }
      if (mounted)
        setState(() {}); // Trigger rebuild for potential processing anim
    }
  }

  /// Processes the content string into tokens and updates the state.
  void _processContent(String content) {
    if (mounted) {
      _logger.finest("Processing content, length: ${content.length}");
      setState(() {
        // Parse content using the selected parser with isFinal set based on streaming state
        _parsedTokens = _tokenParser.parse(content, isFinal: !_isStreaming);
        _logger.finest("Parsed into ${_parsedTokens.length} tokens");
      });
    }
  }

  @override
  void dispose() {
    _logger.fine("Disposing AssistantMessage");
    _streamSubscription?.cancel(); // Ensure subscription is cancelled
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finest(
      "Building AssistantMessage. Streaming: $_isStreaming, Tokens: ${_parsedTokens.length}",
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Show processing animation ONLY if no tokens have been parsed yet.
    if (_parsedTokens.isEmpty && _isStreaming) {
      // Also check _isStreaming to avoid showing it for initial empty static content
      _logger.finest("Showing processing animation");
      return ProcessingAnimation(
        key: const ValueKey('internal_processing'),
        color: context.colors.primary,
      );
    }

    // If not streaming or if tokens exist, build the list of token widgets.
    // Using a Column ensures widgets appear vertically.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildTokenWidgets(theme, isDark),
    );
  }

  /// Builds a list of Widgets based on the parsed tokens.
  List<Widget> _buildTokenWidgets(ThemeData theme, bool isDark) {
    final List<Widget> widgets = [];
    final bool isCurrentlyStreaming = _isStreaming; // Capture current state

    _logger.finest(
      "Building token widgets. Count: ${_parsedTokens.length}, Streaming: $isCurrentlyStreaming",
    );

    for (int i = 0; i < _parsedTokens.length; i++) {
      final token = _parsedTokens[i];
      _logger.finest(
        "Building widget for token $i: type=${token.type}, content='${token.content.substring(0, (token.content.length > 20 ? 20 : token.content.length))}'",
      );
      // Determine if this token is the last one currently being streamed
      // This logic might be flawed for complex streaming scenarios (e.g., code block streaming)
      final bool isLastPotentiallyStreamingToken =
          isCurrentlyStreaming && (i == _parsedTokens.length - 1);

      switch (token.type) {
        case TokenType.thinking:
          widgets.add(
            ThinkingBubble(key: ValueKey('think_$i'), content: token.content),
          );
          break;
        case TokenType.toolCall:
          widgets.add(
            ToolCallBubble(key: ValueKey('tool_$i'), content: token.content),
          );
          break;
        case TokenType.codeBlock:
          // Pass content directly to CodeBlock.
          widgets.add(
            CodeBlock(
              // Use a key derived from token info for stability
              key: ValueKey('code_${i}_${token.startIndex}'),
              // Pass static content found so far. CodeBlock itself handles internal state.
              content: token.content,
              language: token.metadata?['language'],
            ),
          );
          break;
        case TokenType.plainText:
          if (token.content.trim().isNotEmpty) {
            // Use MarkdownBody for plain text rendering
            widgets.add(
              _buildMarkdownContent(token.content, theme, isDark, context),
            );
          }
          break;
      }
    }
    // Note: The processing animation is now handled in the main build method
    return widgets;
  }

  /// Builds the Markdown widget for plain text content.
  Widget _buildMarkdownContent(
    String content,
    ThemeData theme,
    bool isDark,
    BuildContext context,
  ) {
    return MarkdownBody(
      selectable: true,
      data: content.isEmpty ? ' ' : content, // Handle potential empty string
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: context.typography.body1.copyWith(color: context.colors.onSurface),
        code: context.typography.code.copyWith(
          color: context.colors.onSurface,
          backgroundColor: context.colors.surfaceVariant.withOpacity(0.5),
        ),
        codeblockDecoration: BoxDecoration(
          color: context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(context.radius.small),
        ),
        blockquoteDecoration: BoxDecoration(
          color: context.colors.surfaceVariant.withOpacity(0.3),
          border: Border(
            left: BorderSide(color: context.colors.secondary, width: 4),
          ),
        ),
      ),
    );
  }
}
