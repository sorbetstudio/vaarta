// lib/widgets/message_components/code_block.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:vaarta/theme/theme_extensions.dart'; // Import theme extensions

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
              // Optionally display an error message
              _accumulatedContent = 'Error loading code: $error';
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
      // Reset state when stream changes
      _accumulatedContent =
          widget.content ?? ''; // Reset to initial static content if provided

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
                _accumulatedContent = 'Error loading code: $error';
              });
            }
          },
        );
      } else {
        // If new stream is null, ensure loading is false
        _isLoading = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasContent = _accumulatedContent.isNotEmpty;

    // Use theme extensions for colors where appropriate, fallback to greys
    final codeColor = isDark ? Colors.grey.shade300 : context.colors.onSurface;
    final langColor =
        isDark
            ? Colors.grey.shade400
            : context.colors.onSurface.withOpacity(0.7);
    final backgroundColor =
        isDark
            ? context.colors.surfaceVariant.withOpacity(0.5)
            : context.colors.surfaceVariant;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor, // Use theme color
        borderRadius: BorderRadius.circular(
          context.radius.small,
        ), // Use theme radius
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code content with horizontal scrolling
          Padding(
            padding: EdgeInsets.only(
              top: context.spacing.small,
              bottom: context.spacing.small,
              left: context.spacing.medium,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                hasContent
                    ? _accumulatedContent
                    : ' ', // Prevent error on empty
                style: context.typography.code.copyWith(
                  // Use theme typography
                  color: codeColor,
                  height: 1.5, // Keep line height for readability
                ),
              ),
            ),
          ),

          // Footer with language and copy button
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.medium,
              vertical: context.spacing.small,
            ),
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.5),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(context.radius.small),
                bottomRight: Radius.circular(context.radius.small),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.language != null && widget.language!.isNotEmpty)
                  Text(
                    widget.language!,
                    style: context.typography.caption.copyWith(
                      // Use theme typography
                      color: langColor,
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
                      color: langColor,
                    ),
                  )
                else if (hasContent) // Only show copy button if there's content
                  IconButton(
                    icon: Icon(Icons.copy_outlined, size: 18, color: langColor),
                    tooltip: 'Copy to clipboard',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: _accumulatedContent),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Code copied to clipboard',
                            style: context.typography.body2.copyWith(
                              color:
                                  context
                                      .colors
                                      .onPrimary, // Assuming SnackBar uses primary background
                            ),
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: context.colors.primary,
                          behavior: SnackBarBehavior.floating,
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
