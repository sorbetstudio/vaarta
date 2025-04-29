// lib/widgets/src/code_block.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class CodeBlock extends StatefulWidget {
  final Stream<String>? contentStream;
  final String? content;
  final String? language;

  const CodeBlock({super.key, this.contentStream, this.content, this.language})
    : assert(
        contentStream != null || content != null,
        "Either contentStream or content must be provided",
      );

  @override
  _CodeBlockState createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  String _accumulatedContent = '';
  StreamSubscription<String>? _streamSubscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize with static content
    if (widget.content != null) {
      _accumulatedContent = widget.content ?? '';
    }

    // Setup stream subscription
    if (widget.contentStream != null) {
      _isLoading = true;
      _streamSubscription = widget.contentStream!.listen(
        (chunk) {
          if (mounted) {
            setState(() {
              _accumulatedContent += chunk;
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );
    }
  }

  @override
  void didUpdateWidget(CodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle content changes
    if (widget.content != oldWidget.content && widget.content != null) {
      setState(() {
        _accumulatedContent = widget.content ?? '';
      });
    }

    // Handle stream changes
    if (widget.contentStream != oldWidget.contentStream) {
      _streamSubscription?.cancel();
      _accumulatedContent = '';

      if (widget.contentStream != null) {
        _isLoading = true;
        _streamSubscription = widget.contentStream!.listen(
          (chunk) {
            if (mounted) {
              setState(() {
                _accumulatedContent += chunk;
              });
            }
          },
          onDone: () {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasContent = _accumulatedContent.isNotEmpty;

    return Container(
      width: double.infinity,
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
          // Code content
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              hasContent ? _accumulatedContent : ' ',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade900,
                height: 1.5,
              ),
            ),
          ),

          // Footer with language and copy button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.language != null && widget.language!.isNotEmpty)
                  Text(
                    widget.language!,
                    style: TextStyle(
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const Spacer(),
                if (_isLoading)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(
                      Icons.copy_outlined,
                      size: 18,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                    tooltip: 'Copy to clipboard',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: _accumulatedContent),
                      );
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

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
