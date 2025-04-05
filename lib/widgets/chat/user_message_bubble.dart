// lib/widgets/chat/user_message_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaarta/models/messages/chat_message.dart';
import 'package:vaarta/providers/messages_notifier.dart';
import 'package:vaarta/services/database/message_repository.dart';
import 'package:vaarta/theme/theme_extensions.dart';

class UserMessageBubble extends ConsumerStatefulWidget {
  final ChatMessage message;
  final bool isEditing;
  final String chatId;
  final MessageRepository messageRepository;

  const UserMessageBubble({
    // Use message timestamp as part of the key for better state preservation
    super.key, // Key passed from parent builder
    required this.message,
    required this.isEditing,
    required this.chatId,
    required this.messageRepository,
  });

  @override
  ConsumerState<UserMessageBubble> createState() => _UserMessageBubbleState();
}

class _UserMessageBubbleState extends ConsumerState<UserMessageBubble> {
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false; // Track focus state locally

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.message.content);
    // Add listener to update Riverpod state and DB on text change
    _textController.addListener(_onTextChanged);
    // Add listener to handle focus changes for cursor positioning
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(UserMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the message content changes externally (e.g., undo/redo), update controller
    if (widget.message.content != oldWidget.message.content &&
        widget.message.content != _textController.text) {
      // Temporarily remove listener to prevent loop
      _textController.removeListener(_onTextChanged);
      _textController.text = widget.message.content;
      _moveCursorToEnd(); // Ensure cursor is at end after external change
      // Re-add listener
      _textController.addListener(_onTextChanged);
    }
    // If switching to editing mode, request focus
    if (widget.isEditing && !oldWidget.isEditing) {
      // Request focus after the build frame completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
          // Move cursor to end AFTER focus request
          _moveCursorToEnd();
        }
      });
    }
    // If switching *away* from editing, ensure focus is lost
    else if (!widget.isEditing && oldWidget.isEditing && _hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    _textController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChange);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Update state and DB
    final updatedMessage = widget.message.copyWith(
      content: _textController.text,
    );
    // Use read here to avoid listening loops within the listener
    ref
        .read(messagesNotifierProvider(widget.chatId).notifier)
        .updateMessage(updatedMessage);
    widget.messageRepository.updateMessage(updatedMessage); // Update DB
  }

  void _onFocusChange() {
    if (!mounted) return; // Check if widget is still mounted
    final hasFocusNow = _focusNode.hasFocus;
    if (hasFocusNow != _hasFocus) {
      // Only update state if focus actually changed
      setState(() {
        _hasFocus = hasFocusNow;
      });
    }
    if (hasFocusNow) {
      // Move cursor to end when TextField gains focus
      _moveCursorToEnd();
    }
  }

  void _moveCursorToEnd() {
    // Ensure this runs after the text field has potentially rebuilt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check mount status and focus again inside the callback
      if (mounted && _focusNode.hasFocus) {
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(context.radius.medium),
        // Add subtle highlight if focused and editing
        border:
            widget.isEditing && _hasFocus
                ? Border.all(color: context.colors.primary, width: 1.5)
                : null,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.small,
        vertical: context.spacing.small,
      ),
      child:
          widget.isEditing
              ? TextField(
                // Changed from TextFormField for simplicity unless validation needed
                controller: _textController,
                focusNode: _focusNode,
                style: context.typography.body1.copyWith(
                  color: context.colors.onSurface,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: "Edit message",
                  hintStyle: TextStyle(
                    color: context.colors.onSurface.withOpacity(0.6),
                  ),
                ),
                // onTap: _moveCursorToEnd, // Removed: Let default tap behavior work
                keyboardType:
                    TextInputType.multiline, // Ensure multiline keyboard
                maxLines: null, // Allow multiple lines
              )
              : MarkdownBody(
                data: widget.message.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  Theme.of(context),
                ).copyWith(
                  p: context.typography.body1.copyWith(
                    color: context.colors.onSurface,
                  ),
                  code: context.typography.code.copyWith(
                    color: context.colors.onSurface,
                    backgroundColor: context.colors.surfaceVariant.withOpacity(
                      0.5,
                    ),
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(context.radius.small),
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: context.colors.surfaceVariant.withOpacity(0.3),
                    border: Border(
                      left: BorderSide(
                        color: context.colors.secondary,
                        width: 4,
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}
