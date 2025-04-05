// lib/screens/chat/chat_stream_manager.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:flutter/material.dart'; // Import for ScrollController, VoidCallback
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:vaarta/models/messages/chat_message.dart';
import 'package:vaarta/models/settings_state.dart';
import 'package:vaarta/providers/llm_client_provider.dart';
import 'package:vaarta/providers/messages_notifier.dart';
import 'package:vaarta/providers/settings_provider.dart';
import 'package:vaarta/services/database/message_repository.dart';
import 'package:vaarta/services/llm_client.dart';
// TODO: Import ChatRepository and ChatTitleService when needed for title generation
// import 'package:vaarta/services/database/chat_repository.dart';
// import 'package:vaarta/services/chat/chat_title_service.dart'; // Assuming future service

/// Manages the state and logic for sending messages, handling LLM streams,
/// and regenerating responses within a chat.
class ChatStreamManager {
  final WidgetRef _ref;
  final String _chatId;
  final MessageRepository _messageRepository;
  final ScrollController _scrollController; // Add ScrollController field
  final VoidCallback _scrollCallback; // Add callback field
  // TODO: final ChatRepository _chatRepository;
  final Logger _logger = Logger('ChatStreamManager');

  bool _isGenerating = false;
  String _streamedResponse = "";
  StreamSubscription<String>? _streamSubscription;
  // Keep the controller accessible for the message list widget
  StreamController<String> messageStreamController =
      StreamController<String>.broadcast();

  bool get isGenerating => _isGenerating;
  String get streamedResponse => _streamedResponse; // Add getter

  ChatStreamManager({
    required WidgetRef ref,
    required String chatId,
    required MessageRepository messageRepository,
    required ScrollController scrollController, // Add constructor parameter
    required VoidCallback scrollCallback, // Add constructor parameter
    // TODO: required ChatRepository chatRepository,
  }) : _ref = ref,
       _chatId = chatId,
       _messageRepository = messageRepository,
       _scrollController = scrollController, // Initialize field
       _scrollCallback = scrollCallback; // Initialize field
  // TODO: _chatRepository = chatRepository;

  /// Sends a user message and streams the AI response.
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || _isGenerating)
      return; // Prevent sending while generating

    final settings = _ref.read(settingsProvider);
    if (settings.apiKey.isEmpty) {
      _logger.warning("API Key missing. Cannot send message.");
      // Error should be handled/displayed by the UI calling this method
      throw Exception('API Key is missing. Please configure it in Settings.');
    }

    // DO NOT close or replace the controller here.
    // The existing controller will be reused.
    // We only need to cancel the previous listener (_streamSubscription).

    final userMessage = ChatMessage(
      chatId: _chatId,
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Update state immediately
    _isGenerating = true;
    _streamedResponse = "";
    // Notify listeners if this were a ChangeNotifier
    _ref
        .read(messagesNotifierProvider(_chatId).notifier)
        .addMessage(userMessage);
    // UI should react to the provider state change

    _logger.info("Inserting user message: ${userMessage.content}");
    await _messageRepository.insertMessage(userMessage);
    // TODO: Consider if scroll needs to be triggered from here or UI

    try {
      final llmClient = _ref.read(llmClientProvider);
      // Read messages *after* adding the user message
      final currentMessages = _ref.read(messagesNotifierProvider(_chatId));

      // Ensure system prompt is included if needed by the model/logic
      final llmMessages = [
        LLMMessage(role: 'system', content: settings.effectiveSystemPrompt),
        ...currentMessages.map(
          (msg) => LLMMessage(
            role: msg.isUser ? 'user' : 'assistant',
            content: msg.content,
          ),
        ),
      ];

      await _streamSubscription?.cancel(); // Cancel any previous listener
      _streamSubscription = llmClient
          .streamCompletion(llmMessages)
          .listen(
            (chunk) {
              if (!_isGenerating) return; // Check if stopped prematurely
              _streamedResponse += chunk;
              if (settings.useHapticFeedback) {
                HapticFeedback.lightImpact();
              }
              if (!messageStreamController.isClosed) {
                messageStreamController.add(chunk);
              }
              _scrollCallback(); // Call scroll callback on each chunk
            },
            onDone: () async {
              if (!_isGenerating) return; // Check if stopped prematurely

              final aiMessage = ChatMessage(
                chatId: _chatId,
                content: _streamedResponse,
                isUser: false,
                timestamp: DateTime.now(),
              );

              // Add message *before* setting isGenerating to false
              _ref
                  .read(messagesNotifierProvider(_chatId).notifier)
                  .addMessage(aiMessage);
              await _messageRepository.insertMessage(aiMessage); // Save to DB

              _isGenerating = false; // Update state *after* adding message
              _streamSubscription = null;
              // Notify UI (implicit via provider update)

              // TODO: Trigger title generation if needed
              // await _triggerTitleGenerationIfNeeded();
              // TODO: Trigger scroll (likely from UI watching isGenerating)
            },
            onError: (error) async {
              // Make onError async
              if (!_isGenerating) return; // Check if stopped prematurely
              _logger.severe("Error during LLM stream: $error");
              final errorMessage = ChatMessage(
                chatId: _chatId,
                content: 'Error: $error',
                isUser: false,
                timestamp: DateTime.now(),
              );
              _ref
                  .read(messagesNotifierProvider(_chatId).notifier)
                  .addMessage(errorMessage);
              await _messageRepository.insertMessage(
                errorMessage,
              ); // Save error message

              _isGenerating = false; // Update state
              _streamSubscription = null;
              // Notify UI (implicit via provider update)
              // TODO: Trigger scroll
            },
            cancelOnError: true,
          );
    } catch (e) {
      _logger.severe("Error sending message: $e");
      final errorMessage = ChatMessage(
        chatId: _chatId,
        content: 'Error: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _ref
          .read(messagesNotifierProvider(_chatId).notifier)
          .addMessage(errorMessage);
      await _messageRepository.insertMessage(
        errorMessage,
      ); // Save error message

      _isGenerating = false; // Update state
      _streamSubscription = null;
      // Notify UI (implicit via provider update)
      // TODO: Trigger scroll
      // Rethrow or handle more gracefully?
      throw Exception(
        "Failed to send message: $e",
      ); // Rethrow allows UI to catch
    }
  }

  /// Stops the stream generation and saves the partial response.
  Future<void> stopStream() async {
    if (!_isGenerating) return;

    _logger.info("Stopping stream for chat $_chatId");
    await _streamSubscription?.cancel();
    _streamSubscription = null; // Clear subscription

    final partialResponse = _streamedResponse; // Capture before resetting state
    _isGenerating = false;
    _streamedResponse = ""; // Clear streamed response
    // Notify UI (e.g., via StateNotifier update or setState in caller)

    // Save the partial response if available
    if (partialResponse.isNotEmpty) {
      final aiMessage = ChatMessage(
        chatId: _chatId,
        content: partialResponse, // Use captured partial response
        isUser: false,
        timestamp: DateTime.now(),
      );
      // Add message *after* setting isGenerating to false
      _ref
          .read(messagesNotifierProvider(_chatId).notifier)
          .addMessage(aiMessage);
      await _messageRepository.insertMessage(aiMessage);
    }

    // Ensure stream controller is closed if no longer needed
    // Closing it here might be premature if the UI element listening to it
    // still exists and expects it (e.g., AssistantMessage).
    // Consider closing it when the manager itself is disposed.
    // if (!messageStreamController.isClosed) {
    //    await messageStreamController.close();
    // }

    // TODO: Trigger scroll?
  }

  /// Regenerates a specific AI message by resending history up to the preceding user message.
  Future<void> regenerateMessage(ChatMessage originalAiMessage) async {
    if (_isGenerating) return; // Don't regenerate while already generating

    _logger.info(
      "Regenerating message for chat $_chatId (Timestamp: ${originalAiMessage.timestamp})",
    );
    // Read messages directly, no need to watch here
    final allMessages = _ref.read(messagesNotifierProvider(_chatId));
    final originalMessageIndex = allMessages.indexWhere(
      (m) => m.timestamp == originalAiMessage.timestamp,
    );

    if (originalMessageIndex < 0) {
      _logger.warning("Cannot regenerate: Original message not found.");
      return;
    }
    if (originalMessageIndex == 0) {
      _logger.warning(
        "Cannot regenerate: Original message is the first message.",
      );
      return; // Cannot regenerate the first message
    }

    // Get all messages *before* the one being regenerated
    final messagesToResend = allMessages.sublist(0, originalMessageIndex);

    // Find the last message in the history *before* the target AI message
    final lastMessageToSend = messagesToResend.last;

    if (!lastMessageToSend.isUser) {
      _logger.warning(
        "Cannot regenerate: The message before the target AI message was not a user message.",
      );
      // This scenario shouldn't typically happen in a user/assistant flow
      return;
    }

    // Remove the original AI message and any subsequent messages (if any) from state and DB
    _logger.fine("Removing messages from index $originalMessageIndex onwards.");
    // Replace removeMessagesFrom with setting the state to the sublist
    final messagesBeforeOriginal = allMessages.sublist(0, originalMessageIndex);
    _ref
        .read(messagesNotifierProvider(_chatId).notifier)
        .setMessages(messagesBeforeOriginal);
    await _messageRepository.deleteMessagesFrom(
      _chatId,
      originalAiMessage.timestamp,
    ); // Pass chatId and timestamp

    // Instead of calling sendMessage, directly call the LLM with the truncated history
    _logger.info("Starting LLM call for regeneration.");
    _isGenerating = true;
    _streamedResponse = "";
    // Notify UI state change if necessary (e.g., if manager is a ChangeNotifier)
    // If ChatScreen uses setState, it needs to be called there after regenerateMessage is invoked.

    // Close and recreate stream controller for regeneration
    if (!messageStreamController.isClosed) {
      await messageStreamController.close();
    }
    messageStreamController = StreamController<String>.broadcast();

    try {
      final settings = _ref.read(settingsProvider);
      final llmClient = _ref.read(llmClientProvider);
      // IMPORTANT: Use messagesBeforeOriginal (the history *before* the deleted message)
      final llmMessages = [
        LLMMessage(role: 'system', content: settings.effectiveSystemPrompt),
        ...messagesBeforeOriginal.map(
          (msg) => LLMMessage(
            role: msg.isUser ? 'user' : 'assistant',
            content: msg.content,
          ),
        ),
      ];

      await _streamSubscription?.cancel(); // Cancel any previous listener
      _streamSubscription = llmClient
          .streamCompletion(llmMessages)
          .listen(
            (chunk) {
              // Same listener logic as in sendMessage
              if (!_isGenerating) return;
              _streamedResponse += chunk;
              if (settings.useHapticFeedback) {
                HapticFeedback.lightImpact();
              }
              if (!messageStreamController.isClosed) {
                messageStreamController.add(chunk);
              }
              _scrollCallback(); // Call scroll callback on each chunk
            },
            onDone: () async {
              // Same onDone logic as in sendMessage
              if (!_isGenerating) return;
              final aiMessage = ChatMessage(
                chatId: _chatId,
                content: _streamedResponse,
                isUser: false,
                timestamp: DateTime.now(),
              );
              _ref
                  .read(messagesNotifierProvider(_chatId).notifier)
                  .addMessage(aiMessage);
              await _messageRepository.insertMessage(aiMessage);
              _isGenerating =
                  false; // Update state *after* processing is complete
              _streamSubscription = null;
              // TODO: Title generation? Scroll? (Should be handled by ChatScreen)
            },
            onError: (error) async {
              // Same onError logic as in sendMessage
              if (!_isGenerating) return;
              _logger.severe("Error during LLM stream (regenerate): $error");
              final errorMessage = ChatMessage(
                chatId: _chatId,
                content:
                    'Error regenerating: $error', // Modify error message slightly
                isUser: false,
                timestamp: DateTime.now(),
              );
              _ref
                  .read(messagesNotifierProvider(_chatId).notifier)
                  .addMessage(errorMessage);
              await _messageRepository.insertMessage(errorMessage);
              _isGenerating = false; // Reset state on error
              _streamSubscription = null;
            },
            cancelOnError: true,
          );
    } catch (e) {
      // Catch errors specific to regeneration setup/LLM call
      _logger.severe("Error setting up/calling LLM for regeneration: $e");
      final errorMessage = ChatMessage(
        chatId: _chatId,
        content: 'Error setting up regeneration: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );
      // Ensure state is cleaned up even if LLM call fails immediately
      _isGenerating = false;
      _streamSubscription = null;
      _ref
          .read(messagesNotifierProvider(_chatId).notifier)
          .addMessage(errorMessage);
      await _messageRepository.insertMessage(
        errorMessage,
      ); // Attempt to save error
      throw Exception(
        "Failed to regenerate message: $e",
      ); // Rethrow so ChatScreen can handle
    }
  }

  // TODO: Implement _triggerTitleGenerationIfNeeded using ChatTitleService

  /// Cleans up resources like stream subscriptions and controllers.
  void dispose() {
    _logger.fine("Disposing ChatStreamManager for chat $_chatId");
    _streamSubscription?.cancel();
    if (!messageStreamController.isClosed) {
      messageStreamController.close();
    }
  }
}

// Optional: Create a provider for the manager if needed across widgets,
// otherwise instantiate it directly in the ChatScreen state.
// final chatStreamManagerProvider = Provider.family<ChatStreamManager, String>((ref, chatId) {
//   final messageRepo = MessageRepository(DatabaseHelper.instance); // Assuming direct access for simplicity
//   // final chatRepo = ChatRepository(DatabaseHelper.instance);
//   return ChatStreamManager(
//       ref: ref,
//       chatId: chatId,
//       messageRepository: messageRepo,
//       // chatRepository: chatRepo,
//   );
// });
