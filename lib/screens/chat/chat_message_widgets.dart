// lib/screens/chat/chat_message_widgets.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vaarta/models/messages/chat_message.dart';
import 'package:vaarta/models/settings_state.dart';
import 'package:vaarta/providers/messages_notifier.dart';
import 'package:vaarta/services/database/message_repository.dart'; // For updates during edit
import 'package:vaarta/theme/theme_extensions.dart';
import 'package:vaarta/utils/clipboard_utils.dart';
import 'package:vaarta/widgets/chat/user_message_bubble.dart'; // Import the new widget
import 'package:vaarta/widgets/src/assistant_message.dart'; // Correct package path
import 'package:vaarta/widgets/message_components/processing_animation.dart'; // Use package import
import 'chat_stream_manager.dart'; // Import the manager

/// Builds the main list view for displaying chat messages.
Widget buildMessageListView(
  BuildContext context,
  WidgetRef ref, // Need ref for editing messages
  List<ChatMessage> messages,
  SettingsState settings,
  ScrollController scrollController,
  bool isGenerating,
  ChatStreamManager streamManager, // Pass the manager instance
  String chatId, // Needed for provider
  bool isEditingMessages, // Needed for buildChatMessage
  Function(ChatMessage) regenerateCallback, // Needed for buildAssistantMessage
  MessageRepository messageRepository, // Needed for buildUserMessage edits
) {
  return ListView.builder(
    controller: scrollController,
    itemCount: messages.length + (isGenerating ? 1 : 0),
    itemBuilder: (context, index) {
      if (index == messages.length && isGenerating) {
        // Display the streaming/processing indicator at the end
        return Padding(
          padding: EdgeInsets.symmetric(vertical: context.spacing.medium),
          child: Align(
            alignment: Alignment.centerLeft,
            // Always build AssistantMessage when generating.
            child: AssistantMessage(
              key: const ValueKey('streaming_assistant_message'), // Keep key
              messageStream:
                  streamManager
                      .messageStreamController
                      .stream, // Get stream from manager instance
            ),
          ),
        );
      }
      // Display a regular message
      return buildChatMessage(
        context,
        ref,
        messages[index],
        settings,
        isEditingMessages,
        regenerateCallback,
        messageRepository,
        chatId,
        streamManager.streamedResponse, // Pass streamedResponse FROM MANAGER
      );
    },
  );
}

/// Builds a single chat message container, aligning left/right.
Widget buildChatMessage(
  BuildContext context,
  WidgetRef ref, // Pass ref down
  ChatMessage message,
  SettingsState settings,
  bool isEditingMessages,
  Function(ChatMessage) regenerateCallback,
  MessageRepository messageRepository,
  String chatId,
  String streamedResponse, // Add streamedResponse parameter
) {
  final isUserMessage = message.isUser;
  return Padding(
    padding: EdgeInsets.only(top: context.spacing.medium),
    child: Align(
      alignment: Alignment.centerLeft, // Keep left alignment for now
      child:
          isUserMessage
              ? UserMessageBubble(
                // Use the new stateful widget
                // Key management note: Relying on ListView.builder's implicit keying.
                // If stability issues arise with editing/state, consider ValueKey(message.timestamp).
                message: message,
                isEditing: isEditingMessages,
                chatId: chatId,
                messageRepository: messageRepository,
              )
              : buildAssistantMessage(
                // Keep calling the existing function for assistant
                context,
                message,
                settings,
                isEditingMessages,
                regenerateCallback,
                streamedResponse,
              ),
    ),
  );
}

/// Builds an assistant message bubble with actions (regenerate, copy).
Widget buildAssistantMessage(
  BuildContext context,
  ChatMessage message,
  SettingsState settings,
  bool
  isEditingMessages, // Though assistant messages aren't usually editable this way
  Function(ChatMessage) regenerateCallback,
  String
  streamedResponse, // Accept streamedResponse (unused but might force rebuild)
) {
  // We'll ignore isEditingMessages for the assistant message display itself.

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Use the dedicated AssistantMessage widget which handles parsing/rendering
      AssistantMessage(content: message.content),
      // Action buttons row
      Padding(
        padding: EdgeInsets.only(
          top: context.spacing.tiny,
          left: context.spacing.small,
        ), // Adjust padding
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Regenerate Button
            IconButton(
              icon: const Icon(Icons.refresh),
              padding: EdgeInsets.all(context.spacing.small),
              constraints: const BoxConstraints(),
              iconSize: 16,
              color: context.colors.primary,
              tooltip: 'Regenerate',
              // Disable while generating (logic handled in ChatScreen state)
              onPressed: () => regenerateCallback(message),
            ),
            // Copy Button
            IconButton(
              icon: const Icon(Icons.copy),
              padding: EdgeInsets.all(context.spacing.small),
              constraints: const BoxConstraints(),
              iconSize: 16,
              color: context.colors.primary,
              tooltip: 'Copy',
              onPressed:
                  () => copyToClipboard(
                    context: context,
                    text: message.content,
                    useHapticFeedback: settings.useHapticFeedback,
                  ),
            ),
          ],
        ),
      ),
    ],
  );
}

// Removed the old buildUserMessage function
