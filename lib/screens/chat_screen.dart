// lib/screens/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:vaarta/models/messages/chat_message.dart';
import 'package:vaarta/models/settings_state.dart';
import 'package:vaarta/providers/chat_list_provider.dart';
import 'package:vaarta/providers/llm_client_provider.dart'; // Needed for potential error checking before manager init
import 'package:vaarta/providers/messages_notifier.dart';
import 'package:vaarta/providers/settings_provider.dart';
import 'package:vaarta/router/app_router.dart';
import 'package:vaarta/services/database/chat_repository.dart';
import 'package:vaarta/services/database/message_repository.dart';
import 'package:vaarta/services/database_helper.dart';
import 'package:vaarta/theme/theme_extensions.dart';
import 'package:vaarta/widgets/chat_drawer.dart';
import 'package:vaarta/widgets/shared/error_message_widget.dart';
import 'package:vaarta/widgets/shared/loading_indicator.dart';

import 'chat/chat_input_area.dart';
import 'chat/chat_message_widgets.dart';
import 'chat/chat_stream_manager.dart';

/// Displays a chat interface for sending and receiving messages with an AI.
class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _logger = Logger('ChatScreen');
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _systemPromptController = TextEditingController();

  late final DatabaseHelper _dbHelper;
  late final ChatRepository _chatRepository;
  late final MessageRepository _messageRepository;
  late final ChatStreamManager _streamManager;

  bool _isScrolling = false; // Keep local scroll state
  bool _isEditingMessages = false; // Keep local edit mode state
  bool _isDisposed = false; // Track if widget is disposed

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _dbHelper = DatabaseHelper.instance; // Initialize helper
    _chatRepository = ChatRepository(_dbHelper); // Init repo
    _messageRepository = MessageRepository(_dbHelper); // Init repo

    // Initialize ChatStreamManager AFTER repositories are initialized
    // Crucially, ref is available in initState for ConsumerStatefulWidget
    _streamManager = ChatStreamManager(
      ref: ref,
      chatId: widget.chatId,
      messageRepository: _messageRepository,
      // chatRepository: _chatRepository, // TODO: Pass when needed
      scrollController: _scrollController, // Pass ScrollController
      scrollCallback: _smoothScrollToBottom, // Pass scroll function
    );

    _loadMessages();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _textController.dispose();
    _scrollController.dispose();
    _systemPromptController.dispose();
    _streamManager.dispose(); // Dispose the manager
    super.dispose();
  }

  /// Loads initial chat messages.
  Future<void> _loadMessages() async {
    try {
      final messages = await _messageRepository.getMessages(widget.chatId);
      if (!mounted || _isDisposed) return;
      ref
          .read(messagesNotifierProvider(widget.chatId).notifier)
          .setMessages(messages);
      _snapToBottom();
    } catch (e) {
      _logger.severe("Error loading messages: $e");
      // Handle error appropriately, maybe show a message
    }
  }

  // --- Navigation Methods ---

  void _openChatList() => _scaffoldKey.currentState?.openDrawer();
  void _startNewChat() async {
    // Make async
    // Navigate first (this creates the chat in the DB)
    await AppRouter.navigateToNewChat(context);
    // THEN invalidate the provider to make the drawer update
    // Need to ensure context is still valid if navigateToNewChat involves async gaps
    if (mounted) {
      // Check if widget is still in the tree
      ref.invalidate(chatListProvider);
    }
  }

  void _openSettings() => context.push(AppRouter.settings);

  // --- Scrolling Methods ---

  void _smoothScrollToBottom() {
    if (_isScrolling ||
        !_scrollController.hasClients ||
        !mounted ||
        _isDisposed)
      return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed || !_scrollController.hasClients) return;
      try {
        _isScrolling = true;
        _scrollController
            .animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(
                milliseconds: 300,
              ), // Slightly longer duration
              curve: Curves.easeOut, // Smoother curve
            )
            .whenComplete(() => _isScrolling = false);
      } catch (_) {
        // Catch potential errors during animation
        _isScrolling = false;
      }
    });
  }

  void _snapToBottom() {
    if (_isScrolling ||
        !_scrollController.hasClients ||
        !mounted ||
        _isDisposed)
      return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed || !_scrollController.hasClients) return;
      try {
        _isScrolling = true;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } finally {
        _isScrolling = false;
      }
    });
  }

  // --- Handlers that delegate to ChatStreamManager ---

  Future<void> _handleSendMessage(String message) async {
    if (message.trim().isEmpty) return;
    try {
      _textController.clear(); // Clear field immediately
      // Trigger UI update for isGenerating and scroll
      // Removed setState call here
      _snapToBottom();
      await _streamManager.sendMessage(message);
      // Removed setState call here
      _smoothScrollToBottom(); // Scroll smoothly as response comes in
    } catch (e) {
      _logger.warning("Error caught in _handleSendMessage: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceFirst("Exception: ", "")}',
              style: context.typography.body2.copyWith(
                color: context.colors.onError,
              ),
            ),
            backgroundColor: context.colors.error,
          ),
        );
        // Removed setState call here
      }
    }
  }

  void _handleStopStream() async {
    await _streamManager.stopStream();
    // Removed setState call here
  }

  Future<void> _handleRegenerateMessage(ChatMessage message) async {
    try {
      // Removed setState call here
      _snapToBottom(); // Scroll first
      await _streamManager.regenerateMessage(message);
      // Removed setState call here
      _smoothScrollToBottom();
    } catch (e) {
      _logger.warning("Error caught in _handleRegenerateMessage: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error regenerating message: $e')),
        );
        // Removed setState call here
      }
    }
  }

  /// Opens a dialog to edit the system prompt.
  void _editSystemPrompt() {
    final currentSettings = ref.read(settingsProvider);
    _systemPromptController.text = currentSettings.effectiveSystemPrompt;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit System Prompt', style: context.typography.h6),
            content: TextField(
              controller: _systemPromptController,
              maxLines: null, // Allow multiple lines
              minLines: 3, // Start with a decent height
              textInputAction:
                  TextInputAction.newline, // Enable newline insertion
              decoration: InputDecoration(
                hintText: "Enter custom system prompt (optional)",
                hintStyle: TextStyle(
                  color: context.colors.onSurface.withOpacity(0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.radius.small),
                  borderSide: BorderSide(color: context.colors.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.radius.small),
                  borderSide: BorderSide(
                    color: context.colors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Cancel',
                  style: TextStyle(color: context.colors.primary),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text(
                  'Save',
                  style: TextStyle(color: context.colors.primary),
                ),
                onPressed: () async {
                  final newPrompt = _systemPromptController.text;
                  await ref
                      .read(settingsProvider.notifier)
                      .updateSystemPrompt(newPrompt);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesNotifierProvider(widget.chatId));
    final settingsState = ref.watch(settingsProvider);
    final isGenerating = _streamManager.isGenerating; // Read state from manager

    // Handle settings loading/error states first
    if (settingsState.isLoading) {
      return Scaffold(
        appBar: _buildAppBar(context, settingsState),
        body: const Center(child: LoadingIndicator()),
      );
    }
    if (settingsState.errorMessage != null) {
      return Scaffold(
        appBar: _buildAppBar(context, settingsState),
        body: ErrorMessageWidget(
          message: 'Error loading settings',
          details: settingsState.errorMessage,
        ),
      );
    }
    // Handle missing API key *after* ensuring settings are loaded
    // Also check LLM provider status if needed (though settings check is primary)
    try {
      ref.read(llmClientProvider); // Check if provider throws due to key
    } catch (e) {
      // Handle API key error specifically
      return _buildApiKeyErrorScaffold(context, settingsState);
    }
    if (settingsState.apiKey.isEmpty) {
      return _buildApiKeyErrorScaffold(context, settingsState);
    }

    // Normal build when settings are loaded and API key is present
    return Scaffold(
      key: _scaffoldKey,
      drawer: ChatDrawer(
        currentChatId: widget.chatId,
        onNewChat: _startNewChat,
      ),
      appBar: _buildAppBar(context, settingsState),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 752.0,
          ), // Max width constraint
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacing.medium,
                  ),
                  child: buildMessageListView(
                    // Use imported function
                    context,
                    ref,
                    messages,
                    settingsState,
                    _scrollController,
                    isGenerating,
                    // _streamManager.streamedResponse, // No longer needed here directly
                    _streamManager, // Pass the whole manager instance
                    widget.chatId,
                    _isEditingMessages,
                    _handleRegenerateMessage,
                    _messageRepository,
                  ),
                ),
              ),
              ChatInputArea(
                // Use imported widget
                textController: _textController,
                isGenerating: isGenerating,
                settings: settingsState,
                onSendMessage: _handleSendMessage,
                onStopStream: _handleStopStream,
              ),
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  /// Builds the app bar.
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    SettingsState settings,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AppBar(
        backgroundColor: context.colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Vaarta', style: context.typography.h4),
        leading: IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          tooltip: "Chats",
          onPressed: _openChatList,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: "Edit System Prompt",
            onPressed: _editSystemPrompt,
          ),
          IconButton(
            icon: Icon(_isEditingMessages ? Icons.visibility_off : Icons.edit),
            tooltip:
                _isEditingMessages ? "Stop Editing Messages" : "Edit Messages",
            onPressed:
                () => setState(
                  () => _isEditingMessages = !_isEditingMessages,
                ), // Keep setState for local UI toggle
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Settings",
            onPressed: _openSettings,
          ),
        ],
      ),
    );
  }

  /// Builds the Scaffold body shown when API key is missing.
  Widget _buildApiKeyErrorScaffold(
    BuildContext context,
    SettingsState settingsState,
  ) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: ChatDrawer(
        currentChatId: widget.chatId,
        onNewChat: _startNewChat,
      ),
      appBar: _buildAppBar(context, settingsState), // Still show app bar
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'API Key Required',
                style: context.typography.h5,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.medium),
              Text(
                'Please set your OpenRouter API Key in the settings to start chatting.',
                style: context.typography.body1,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.large),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Go to Settings'),
                onPressed: _openSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Removed all old build methods (_buildMessageListView, etc.) and logic methods (_sendMessage, etc.)
}
