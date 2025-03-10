// lib/widgets/src/rich_message_view.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'thinking_bubble.dart';
import 'tool_call_bubble.dart';
import 'code_block.dart';

class RichMessageView extends StatefulWidget {
  final Stream<String>? messageStream;
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
  StreamSubscription<String>? _streamSubscription;
  String _accumulatedContent = '';
  final RegExp _thinkRegex = RegExp(r'<think>([\s\S]*?)<\/think>', multiLine: true);
  final RegExp _toolRegex = RegExp(r'<tool>([\s\S]*?)<\/tool>', multiLine: true);
  final RegExp _codeRegex = RegExp(r'<code(?:\s+lang="([^"]*)")?>([\s\S]*?)<\/code>', multiLine: true);

  List<StreamController<String>> _codeBlockControllers = []; // Store stream controllers
  String _thinkingContent = '';
  List<String> _toolCalls = [];
  String _plainContent = '';

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

    if (widget.content != oldWidget.content && widget.content != null) {
      _processContent(widget.content!);
    } else if (widget.messageStream != oldWidget.messageStream) {
      _closeCodeBlockStreams(); // Close existing streams
      _streamSubscription?.cancel();
      _accumulatedContent = ''; // Reset accumulated content
      if (widget.messageStream != null) {
        _streamSubscription = widget.messageStream!.listen(_handleStreamUpdate);
      }
    }
  }

  void _handleStreamUpdate(String chunk) {
    _accumulatedContent += chunk;
    _processContent(_accumulatedContent);
  }

  void _processContent(String content) {
    // Extract thinking content and tool calls as before
    _thinkingContent = '';
    if (_thinkRegex.hasMatch(content)) {
      _thinkingContent = _thinkRegex
          .allMatches(content)
          .map((match) => match.group(1) ?? '')
          .join('\n\n');
    }

    _toolCalls = [];
    if (_toolRegex.hasMatch(content)) {
      _toolCalls = _toolRegex
          .allMatches(content)
          .map((match) => match.group(1) ?? '')
          .toList();
    }
    _plainContent = content
        .replaceAll(_thinkRegex, '')
        .replaceAll(_toolRegex, '')
        .replaceAll(_codeRegex, '')
        .trim();

    // Close any existing code block stream controllers
    _closeCodeBlockStreams();
    _codeBlockControllers = []; // Clear the list

    // Find code blocks and create stream controllers
    var matches = _codeRegex.allMatches(content);
    if(matches.isNotEmpty){
      for (var match in matches) {
        var controller = StreamController<String>();
        _codeBlockControllers.add(controller);
        // Don't add to the sink immediately.  Add later in build().
      }
    }


    setState(() {}); // Trigger a rebuild
  }
  void _closeCodeBlockStreams() {
    for (var controller in _codeBlockControllers) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
  }

  @override
  void dispose() {
    _closeCodeBlockStreams();
    _streamSubscription?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    List<Widget> children = [];

    // Thinking bubble
    if (_thinkingContent.isNotEmpty) {
      children.add(ThinkingBubble(content: _thinkingContent));
    }

    // Tool calls
    children.addAll(_toolCalls.map((toolCall) => ToolCallBubble(content: toolCall)));

    // Code blocks (now with streams)
    var codeBlockMatches = _codeRegex.allMatches(_accumulatedContent);

    for (int i = 0; i < codeBlockMatches.length; i++) {
      var match = codeBlockMatches.elementAt(i);
      String language = match.group(1) ?? '';
      String codeContent = match.group(2) ?? '';

      // Check if controller exists for this index
      if (i < _codeBlockControllers.length) {
        final controller = _codeBlockControllers[i];
        // Check to avoid adding to sink after the controller is closed.

        // Add code content to the appropriate stream
        // Use microtask to ensure this happens after the build is complete.

        Future.microtask(() async {
          if (!controller.isClosed) {
            for (var char in codeContent.split('')) {
              if (!controller.isClosed) {
                controller.add(char);
                await Future.delayed(const Duration(milliseconds: 20)); // Add delay
              } else {
                break; // Exit if the stream is closed
              }

            }
            if(!controller.isClosed){
              controller.close(); // Close stream when done

            }
          }

        });

        children.add(CodeBlock(
          contentStream: controller.stream,
          language: language,
        ));
      }
    }
    // Main message content
    if (_plainContent.isNotEmpty) {
      children.add(
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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}