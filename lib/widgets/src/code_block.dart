// lib/widgets/src/code_block.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // Add this line

class CodeBlock extends StatefulWidget { // Changed to StatefulWidget
  final Stream<String>? contentStream; // Stream of code content
  final String? content; // Static content (for fallback)
  final String? language;

  const CodeBlock({
    super.key,
    this.contentStream,
    this.content,
    this.language,
  }) : assert(contentStream != null || content != null, "Either contentStream or content must be provided");

  @override
  _CodeBlockState createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  String _accumulatedContent = '';
  late StreamSubscription<String>? _streamSubscription; // Subscribe to the stream

  @override
  void initState() {
    super.initState();
    if (widget.contentStream != null) {
      _streamSubscription = widget.contentStream!.listen((chunk) {
        setState(() {
          _accumulatedContent += chunk;
        });
      });
    } else {
      _accumulatedContent = widget.content ?? '';
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel(); // Cancel subscription on dispose
    super.dispose();
  }
  @override
  void didUpdateWidget(covariant CodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(widget.contentStream != oldWidget.contentStream){
      _streamSubscription?.cancel();
      _accumulatedContent = '';
      if(widget.contentStream != null){
        _streamSubscription = widget.contentStream!.listen((event) {
          setState(() {
            _accumulatedContent += event;
          });
        });
      }
    }
    if (widget.content != oldWidget.content) {
      _accumulatedContent = widget.content ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                _accumulatedContent, // Display accumulated content
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade900,
                  height: 1.5,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.language != null && widget.language!.isNotEmpty)
                  Text(
                    widget.language!,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.copy_outlined,
                    size: 18,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                  tooltip: 'Copy to clipboard',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _accumulatedContent));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}