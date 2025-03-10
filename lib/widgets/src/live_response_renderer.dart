// lib/widgets/src/live_response_renderer.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'thinking_bubble.dart';
import 'tool_call_bubble.dart';
import 'code_block.dart';

// A widget to display streaming content, parsing special tokens.
class LiveResponseRenderer extends StatefulWidget {
  final Stream<String> responseStream;

  const LiveResponseRenderer({super.key, required this.responseStream});

  @override
  State<LiveResponseRenderer> createState() => _LiveResponseRendererState();
}

class _LiveResponseRendererState extends State<LiveResponseRenderer> {
  final List<Widget> _renderedWidgets = [];
  String _accumulatedResponse = ""; // Accumulate text here

  @override
  void initState() {
    super.initState();
    widget.responseStream.listen((chunk) {
      _processChunk(chunk);
    });
  }

  void _processChunk(String chunk) {
    print('Received chunk: $chunk');

    final thinkRegex = RegExp(r'<think>([\s\S]*?)<\/think>', multiLine: true);
    final toolRegex = RegExp(r'<tool>([\s\S]*?)<\/tool>', multiLine: true);
    final codeRegex = RegExp(r'<code>([\s\S]*?)<\/code>', multiLine: true);

    String remainingChunk = chunk;

    // Extract and process <think> blocks
    if (thinkRegex.hasMatch(remainingChunk)) {
      // Add any accumulated text before the special token
      if (_accumulatedResponse.isNotEmpty) {
        _renderedWidgets.add(MarkdownBody(data: _accumulatedResponse));
        _accumulatedResponse = ""; // Reset
      }

      final thinkingContent = thinkRegex
          .allMatches(remainingChunk)
          .map((match) => match.group(1) ?? '')
          .join('\n\n');
      if (thinkingContent.isNotEmpty) {
        _renderedWidgets.add(ThinkingBubble(content: thinkingContent));
        ThinkingBubble.hasThinkingContent = true;
        print('Added ThinkingBubble: $thinkingContent');
      }
      remainingChunk = remainingChunk.replaceAll(thinkRegex, '').trim();
    }

    // Extract and process <tool> blocks
    if (toolRegex.hasMatch(remainingChunk)) {
      // Add any accumulated text before the special token
      if (_accumulatedResponse.isNotEmpty) {
        _renderedWidgets.add(MarkdownBody(data: _accumulatedResponse));
        _accumulatedResponse = ""; // Reset
      }

      final toolContent = toolRegex
          .allMatches(remainingChunk)
          .map((match) => match.group(1) ?? '')
          .join('\n\n');
      if (toolContent.isNotEmpty) {
        _renderedWidgets.add(ToolCallBubble(content: toolContent));
        print('Added ToolCallBubble: $toolContent');
      }
      remainingChunk = remainingChunk.replaceAll(toolRegex, '').trim();
    }

    // Extract and process <code> blocks
    if (codeRegex.hasMatch(remainingChunk)) {
      // Add any accumulated text before the special token
      if (_accumulatedResponse.isNotEmpty) {
        _renderedWidgets.add(MarkdownBody(data: _accumulatedResponse));
        _accumulatedResponse = ""; // Reset
      }

      final codeContent = codeRegex
          .allMatches(remainingChunk)
          .map((match) => match.group(1) ?? '')
          .join('\n\n');
      if (codeContent.isNotEmpty) {
        _renderedWidgets.add(CodeBlock(content: codeContent));
        print('Added CodeBlock: $codeContent');
      }
      remainingChunk = remainingChunk.replaceAll(codeRegex, '').trim();
    }

    // Accumulate remaining text
    _accumulatedResponse += remainingChunk;

    setState(() {});
    print('Rendered widgets count: ${_renderedWidgets.length}, Accumulated text length: ${_accumulatedResponse.length}');
  }

    @override
  Widget build(BuildContext context) {
     // Add a MarkdownBody for any remaining accumulated text
    List<Widget> finalWidgets = List.from(_renderedWidgets); // Copy the list
    if (_accumulatedResponse.isNotEmpty) {
      finalWidgets.add(MarkdownBody(data: _accumulatedResponse));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: finalWidgets,
    );
  }
}