// lib/screens/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:vaarta/utils/clipboard_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaarta/widgets/shared/loading_indicator.dart';
import 'package:vaarta/widgets/shared/error_message_widget.dart';
import 'package:go_router/go_router.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // No longer needed here
import 'package:vaarta/router/app_router.dart';
import 'dart:ui';
import '../services/database_helper.dart';
import '../services/database/chat_repository.dart';
import '../services/database/message_repository.dart';
import '../services/llm_client.dart';
// import 'settings_screen.dart'; // Settings screen is accessed via router
import 'package:vaarta/widgets/sk_ui.dart';
import 'package:vaarta/utils/utils.dart';
import 'package:vaarta/models/models.dart';
import 'package:vaarta/providers/messages_notifier.dart';
import 'package:vaarta/providers/settings_provider.dart'; // Added
import 'package:vaarta/providers/llm_client_provider.dart'; // Added
import 'package:vaarta/models/settings_state.dart'; // Added import for SettingsState
import 'package:vaarta/theme/theme_extensions.dart';
import 'package:vaarta/widgets/chat_drawer.dart';
import 'package:vaarta/providers/chat_list_provider.dart'; // Added for refresh
import 'package:logging/logging.dart'; // Added for logging

/// Displays a chat interface for sending and receiving messages with an AI.
class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _logger = Logger('ChatScreen'); // Added Logger
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final dbHelper = DatabaseHelper.instance;
  late ChatRepository _chatRepository;
  late MessageRepository _messageRepository;
  // late LLMClient _llmClient; // Removed: Provided by llmClientProvider

  bool _isGenerating = false;
  String _streamedResponse = "";
  bool _isScrolling = false;
  bool _isEditingMessages = false;
  bool _isDisposed = false; // Track if widget is disposed

  // Stream controller for RichMessageView
  late StreamController<String> _messageStreamController;
  StreamSubscription<String>? _streamSubscription;

  // Preferences are now managed by SettingsNotifier via settingsProvider
  // String _apiKey = '';
  // String _selectedModel = "cognitivecomputations/dolphin3.0-mistral-24b:free";
  // bool _useHapticFeedback = true;
  // bool _showReasoning = true;
  // String _systemPromptSetting = '';
  // double _temperature = 0.7;
  // int _maxTokens = 1000;
  // double _topP = 0.9;

  final TextEditingController _systemPromptController = TextEditingController();
  // Default system prompt is now defined in SettingsState
  // final String defaultSystemPrompt =
  //     '''You are Vaarta AI, a helpful assistant...''';

  @override
  void initState() {
    super.initState();
    _chatRepository = ChatRepository(dbHelper);
    _messageRepository = MessageRepository(dbHelper);
    _messageStreamController = StreamController<String>.broadcast();
    _loadMessages();
    // _loadSettings(); // Removed: Settings are loaded by the provider
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Update the _openChatList method to open the drawer
  void _openChatList() {
    _scaffoldKey.currentState?.openDrawer();
  }

  // Add this method to handle creating a new chat
  void _startNewChat() async {
    AppRouter.navigateToNewChat(context);
  }

  // Removed _loadSettings and _initializeLLMClient
  // Settings are loaded via settingsProvider
  // LLMClient is created via llmClientProvider based on settingsProvider state

  /// Loads chat messages from the database.
  Future<void> _loadMessages() async {
    final messages = await _messageRepository.getMessages(widget.chatId);
    if (!mounted || _isDisposed) return;

    ref
        .read(messagesNotifierProvider(widget.chatId).notifier)
        .setMessages(messages);

    _snapToBottom();
  }

  /// Navigates to the settings screen and reloads settings on return.
  void _openSettings() {
    context.push(AppRouter.settings);
  }

  /// Smoothly scrolls to the bottom of the message list.
  void _smoothScrollToBottom() {
    if (_isScrolling || !_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed) return;
      try {
        _isScrolling = true;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 16),
          curve: Curves.linear,
        );
      } finally {
        _isScrolling = false;
      }
    });
  }

  /// Instantly scrolls to the bottom of the message list.
  void _snapToBottom() {
    if (_isScrolling || !_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed) return;
      try {
        _isScrolling = true;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } finally {
        _isScrolling = false;
      }
    });
  }

  /// Sends a user message and streams the AI response.
  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final settings = ref.read(settingsProvider); // Read current settings
    if (settings.apiKey.isEmpty) {
      _logger.warning("API Key missing. Cannot send message.");
      // Optionally show a SnackBar or Dialog to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'API Key is missing. Please configure it in Settings.',
            style: context.typography.body2.copyWith(
              color: context.colors.onError,
            ),
          ),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    final userMessage = ChatMessage(
      chatId: widget.chatId,
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Fixed: Close StreamController outside of setState
    await _messageStreamController.close();
    _messageStreamController = StreamController<String>.broadcast();

    ref
        .read(messagesNotifierProvider(widget.chatId).notifier)
        .addMessage(userMessage);

    if (!mounted || _isDisposed) return;

    setState(() {
      _isGenerating = true;
      _streamedResponse = "";
      _textController.clear();
    });
    _logger.info(
      "Inserting user message (1st call): ${userMessage.content}",
    ); // Added log
    await _messageRepository.insertMessage(userMessage);
    // Removed duplicate insertMessage call here
    _snapToBottom();

    try {
      // Get LLMClient instance from the provider
      // Use read here as we need the client instance for this specific action
      final llmClient = ref.read(llmClientProvider);

      final llmMessages = [
        LLMMessage(
          role: 'system',
          content: settings.effectiveSystemPrompt, // Use settings provider
        ),
        ...ref
            .watch(
              messagesNotifierProvider(widget.chatId),
            ) // Keep watching message list
            .map(
              (msg) => LLMMessage(
                role: msg.isUser ? 'user' : 'assistant',
                content: msg.content,
              ),
            ),
      ];

      _streamSubscription = llmClient // Use provider's client instance
          .streamCompletion(llmMessages)
          .listen(
            (chunk) {
              if (!mounted || _isDisposed) return;
              setState(() {
                _streamedResponse += chunk;
                if (settings.useHapticFeedback) {
                  HapticFeedback.lightImpact(); // Use settings provider
                }
                // Add the chunk to the stream controller
                _messageStreamController.add(chunk);
              });
              _smoothScrollToBottom();
            },
            onDone: () async {
              // Make onDone async
              if (!mounted || _isDisposed) return;

              final aiMessage = ChatMessage(
                chatId: widget.chatId,
                content: _streamedResponse,
                isUser: false,
                timestamp: DateTime.now(),
              );

              // Add AI message to state first
              ref
                  .read(messagesNotifierProvider(widget.chatId).notifier)
                  .addMessage(aiMessage);

              // Update generating state
              // Do this before DB operations which might take time
              if (mounted && !_isDisposed) {
                setState(() {
                  _isGenerating = false;
                  _streamSubscription = null;
                });
              }

              // Save AI message to DB
              await _messageRepository.insertMessage(
                aiMessage,
              ); // await DB insert

              // --- Auto-title generation logic ---
              try {
                final chatMetadata = await _chatRepository.getChatMetadata(
                  widget.chatId,
                );
                if (chatMetadata != null &&
                    chatMetadata[DatabaseHelper.chatColumnChatName] ==
                        'New Chat') {
                  // Check if it's the *first* AI response by seeing if there are exactly 2 messages (user + this AI)
                  final currentMessages = ref.read(
                    messagesNotifierProvider(widget.chatId),
                  );
                  if (currentMessages.length == 2) {
                    _logger.info(
                      "Chat '${widget.chatId}' is 'New Chat' and has 2 messages. Triggering title generation.",
                    );
                    _generateAndSetInitialChatTitle(); // Call placeholder
                  } else {
                    _logger.info(
                      "Chat '${widget.chatId}' is 'New Chat' but has ${currentMessages.length} messages. Not generating title.",
                    );
                  }
                } else {
                  _logger.info(
                    "Chat '${widget.chatId}' name is not 'New Chat' or metadata is null. Not generating title.",
                  );
                }
              } catch (e) {
                _logger.severe(
                  'Error checking/triggering chat title generation: $e',
                );
                // Optionally show an error to the user
              }
              // --- End Auto-title logic ---

              if (mounted && !_isDisposed) {
                _snapToBottom(); // Snap to bottom after everything
              }
            },
            onError: (error) {
              if (!mounted || _isDisposed) return;

              final errorMessage = ChatMessage(
                chatId: widget.chatId,
                content: 'Error: $error',
                isUser: false,
                timestamp: DateTime.now(),
              );
              ref
                  .read(messagesNotifierProvider(widget.chatId).notifier)
                  .addMessage(errorMessage);
              setState(() {
                _isGenerating = false;
                _streamSubscription = null;
              });
              _messageRepository.insertMessage(errorMessage);
              _snapToBottom();
            },
            cancelOnError: true,
          );
    } catch (e) {
      if (!mounted || _isDisposed) return;

      final errorMessage = ChatMessage(
        chatId: widget.chatId,
        content: 'Error: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );
      ref
          .read(messagesNotifierProvider(widget.chatId).notifier)
          .addMessage(errorMessage);
      setState(() {
        _isGenerating = false;
        _streamSubscription = null;
      });
      _messageRepository.insertMessage(errorMessage);
      _snapToBottom();
    }
  }

  /// Generates and sets the initial chat title based on the first two messages.
  Future<void> _generateAndSetInitialChatTitle() async {
    _logger.info(
      "Attempting to generate initial title for chat ${widget.chatId}",
    );

    try {
      // 1. Retrieve first user and AI message
      final messages = ref.read(messagesNotifierProvider(widget.chatId));
      if (messages.length < 2) {
        _logger.warning("Cannot generate title: Less than 2 messages found.");
        return;
      }
      final userMessage = messages[0]; // Assuming first is user
      final aiMessage = messages[1]; // Assuming second is AI

      if (!userMessage.isUser || aiMessage.isUser) {
        _logger.warning(
          "Cannot generate title: First two messages are not User then AI.",
        );
        return;
      }

      // 2. Create title generation prompt
      final titlePrompt = """
Generate a very short, concise title (max 5 words, ideally 2-3) for the following conversation snippet. Only output the title itself, nothing else.

User: ${userMessage.content}
Assistant: ${aiMessage.content}

Title: """;

      final titleMessages = [LLMMessage(role: 'user', content: titlePrompt)];

      // 3. Get LLM client (use a config with low maxTokens)
      final settings = ref.read(settingsProvider);
      final titleLlmConfig = LLMConfig(
        apiKey: settings.apiKey,
        model:
            settings
                .selectedModel, // Use the same model for consistency for now
        provider: LLMProvider.openRouter,
        maxTokens: 20, // Limit tokens for title generation
        temperature: 0.5, // Lower temperature for more predictable title
        openRouterConfig: OpenRouterConfig(
          maxTokens: 20,
          temperature: 0.5,
          // We don't need reasoning for title gen
        ),
        // stream: true, // Incorrect placement: stream is part of OpenRouterConfig (defaults to true)
      );
      final titleLlmClient = LLMClient(config: titleLlmConfig);

      // 4. Call LLM and handle stream for title
      _logger.info("Calling LLM for title generation...");
      final titleBuffer = StringBuffer();
      StreamSubscription? titleStreamSub;
      final completer = Completer<String>();

      titleStreamSub = titleLlmClient
          .streamCompletion(titleMessages)
          .listen(
            (chunk) {
              titleBuffer.write(chunk);
              // Optional: Check if title seems complete (e.g., newline)
              final currentTitle = titleBuffer.toString().trim();
              if (currentTitle.contains('\n') || currentTitle.length > 30) {
                // Stop early if newline or long
                if (!completer.isCompleted) {
                  final finalTitle =
                      currentTitle.split('\n').first.trim(); // Take first line
                  completer.complete(finalTitle);
                  titleStreamSub?.cancel();
                }
              }
            },
            onDone: () {
              if (!completer.isCompleted) {
                completer.complete(titleBuffer.toString().trim());
              }
              _logger.info("LLM stream for title finished.");
            },
            onError: (error) {
              if (!completer.isCompleted) {
                completer.completeError(error);
              }
              _logger.severe("Error during title generation stream: $error");
            },
            cancelOnError: true,
          );

      // Wait for title generation with a timeout
      String generatedTitle = await completer.future.timeout(
        const Duration(seconds: 15), // 15 second timeout for title gen
        onTimeout: () {
          _logger.warning("Title generation timed out.");
          titleStreamSub?.cancel();
          return titleBuffer.toString().trim().isNotEmpty
              ? titleBuffer
                  .toString()
                  .trim()
                  .split('\n')
                  .first
                  .trim() // Use partial if available
              : "Chat"; // Fallback title
        },
      );

      // Clean up title (remove quotes, trim again)
      generatedTitle = generatedTitle.replaceAll(RegExp(r'^"|"$'), '').trim();
      if (generatedTitle.isEmpty) {
        generatedTitle = "Chat"; // Ensure title is not empty
      }

      _logger.info("Generated title: '$generatedTitle'");

      // 5. Update database
      await _chatRepository.updateChatName(widget.chatId, generatedTitle);
      _logger.info("Updated chat name in DB for ${widget.chatId}");

      // 6. Refresh ChatDrawer (invalidate provider)
      ref.invalidate(chatListProvider);
      _logger.info("Invalidated chatListProvider to refresh drawer.");
    } catch (e, stackTrace) {
      _logger.severe(
        'Error generating/setting initial chat title: $e\n$stackTrace',
      );
      // Optionally show error to user, but maybe fail silently for title gen
    }
  }

  /// Stops the stream generation and saves the partial response.
  void _stopStream() {
    _streamSubscription?.cancel();

    if (!mounted || _isDisposed) return;

    // Fixed: Save the partial response instead of discarding it
    if (_streamedResponse.isNotEmpty) {
      final aiMessage = ChatMessage(
        chatId: widget.chatId,
        content: _streamedResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );
      ref
          .read(messagesNotifierProvider(widget.chatId).notifier)
          .addMessage(aiMessage);

      setState(() {
        _isGenerating = false;
        _streamSubscription = null;
      });
      _messageRepository.insertMessage(aiMessage);
      // Removed duplicate insertMessage call here
    } else {
      setState(() {
        _isGenerating = false;
        _streamSubscription = null;
      });
    }

    _snapToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesNotifierProvider(widget.chatId));
    final settingsState = ref.watch(settingsProvider); // Watch settings state

    // Handle settings loading/error states
    if (settingsState.isLoading) {
      return Scaffold(
        appBar: _buildAppBar(context, settingsState),
        body: const Center(child: LoadingIndicator(key: null)),
      );
    }

    if (settingsState.errorMessage != null) {
      return Scaffold(
        appBar: _buildAppBar(context, settingsState),
        body: ErrorMessageWidget(
          key: null,
          message: 'Error loading settings',
          details: settingsState.errorMessage,
        ),
      );
    }

    // Handle missing API key after loading
    if (settingsState.apiKey.isEmpty) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: ChatDrawer(
          currentChatId: widget.chatId,
          onNewChat: _startNewChat,
        ),
        appBar: _buildAppBar(context, settingsState),
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
                  icon: Icon(Icons.settings),
                  label: Text('Go to Settings'),
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

    // Normal build when settings are loaded and API key is present
    return Scaffold(
      key: _scaffoldKey,
      drawer: ChatDrawer(
        currentChatId: widget.chatId,
        onNewChat: _startNewChat,
      ),
      appBar: _buildAppBar(context, settingsState), // Pass settings state
      body: Center(
        child: Container(
          width: 752.0,
          padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacing.medium,
                  ),
                  child: _buildMessageListView(
                    context,
                    messages,
                    settingsState,
                  ), // Pass settings state
                ),
              ),
              _buildInputArea(context, settingsState), // Pass settings state
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  /// Builds the app bar with navigation and editing options.
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    SettingsState settings,
  ) {
    // Added settings param
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AppBar(
        backgroundColor: context.colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Vaarta', style: context.typography.h4),
        leading: IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: _openChatList,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: _editSystemPrompt,
          ),
          IconButton(
            icon: Icon(_isEditingMessages ? Icons.visibility : Icons.edit),
            onPressed:
                () => setState(() => _isEditingMessages = !_isEditingMessages),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
    );
  }

  /// Opens a dialog to edit the system prompt.
  void _editSystemPrompt() {
    // Initialize controller with current setting from provider
    _systemPromptController.text = ref.read(settingsProvider).systemPrompt;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit System Prompt', style: context.typography.h6),
            content: TextField(
              controller: _systemPromptController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: "Enter system prompt",
                hintStyle: TextStyle(
                  color: context.colors.onSurface.withValues(alpha: 0.6),
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
                  // Update setting via provider
                  ref
                      .read(settingsProvider.notifier)
                      .updateSystemPrompt(newPrompt);
                  // if (mounted && !_isDisposed) {
                  //   setState(() => _systemPromptSetting = newPrompt); // Removed setState
                  // }
                  // final prefs = await SharedPreferences.getInstance(); // Removed direct pref usage
                  // await prefs.setString('systemPrompt', newPrompt);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
    );
  }

  /// Builds the list view for displaying chat messages.
  Widget _buildMessageListView(
    BuildContext context,
    List<ChatMessage> messages,
    SettingsState settings, // Added settings param
  ) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: messages.length + (_isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && _isGenerating) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: context.spacing.medium),
            child: Align(
              alignment: Alignment.centerLeft,
              child:
                  _streamedResponse.isEmpty
                      ? ProcessingAnimation(color: context.colors.primary)
                      : AssistantMessage(
                        messageStream: _messageStreamController.stream,
                      ),
            ),
          );
        }
        return _buildChatMessage(
          context,
          messages[index],
          settings,
        ); // Pass settings
      },
    );
  }

  /// Builds a single chat message based on its sender.
  Widget _buildChatMessage(
    BuildContext context,
    ChatMessage message,
    SettingsState settings,
  ) {
    // Added settings param
    final isUserMessage = message.isUser;
    return Padding(
      padding: EdgeInsets.only(top: context.spacing.medium),
      child: Align(
        alignment:
            Alignment.centerLeft, // isUserMessage ? Alignment.centerRight :
        child: Container(
          child:
              isUserMessage
                  ? _buildUserMessage(context, message)
                  : _buildAssistantMessage(
                    context,
                    message,
                    settings,
                  ), // Pass settings
        ),
      ),
    );
  }

  /// Builds a user message with editing capability.
  Widget _buildUserMessage(BuildContext context, ChatMessage message) {
    final messageController = TextEditingController(text: message.content);
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(context.radius.medium),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.small,
        vertical: context.spacing.small,
      ),
      child:
          _isEditingMessages
              ? TextFormField(
                controller: messageController,
                style: context.typography.body1.copyWith(
                  color: context.colors.onSurface,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: "Enter message",
                  hintStyle: TextStyle(
                    color: context.colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                onChanged: (value) {
                  final index = ref
                      .watch(messagesNotifierProvider(widget.chatId))
                      .indexWhere((m) => m.timestamp == message.timestamp);
                  if (index != -1) {
                    final updatedMessage = message.copyWith(content: value);
                    ref
                        .read(messagesNotifierProvider(widget.chatId).notifier)
                        .updateMessage(updatedMessage);
                    _messageRepository.updateMessage(updatedMessage);
                  }
                },
                maxLines: null,
              )
              : MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  Theme.of(context),
                ).copyWith(
                  p: context.typography.body1.copyWith(
                    color: context.colors.onSurface,
                  ),
                  code: context.typography.code.copyWith(
                    // backgroundColor: context.colors.surfaceVariant,
                    color: context.colors.onSurface,
                    // fontFamily: 'monospace',
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(context.radius.small),
                  ),
                  blockquoteDecoration: BoxDecoration(
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

  /// Builds an assistant message with editing capability.
  Widget _buildAssistantMessage(
    BuildContext context,
    ChatMessage message,
    SettingsState settings,
  ) {
    // Added settings param
    final messageController = TextEditingController(text: message.content);

    return Container(
      child:
          _isEditingMessages
              ? Container(
                decoration: BoxDecoration(
                  color: context.colors.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(context.radius.large),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.large,
                  vertical: context.spacing.medium,
                ),
                child: TextFormField(
                  controller: messageController,
                  style: context.typography.body1,
                  decoration: InputDecoration.collapsed(
                    hintText: "Enter message",
                    hintStyle: TextStyle(
                      color: context.colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  onChanged: (value) {
                    final index = ref
                        .watch(messagesNotifierProvider(widget.chatId))
                        .indexWhere((m) => m.timestamp == message.timestamp);
                    if (index != -1) {
                      final updatedMessage = message.copyWith(content: value);
                      ref
                          .read(
                            messagesNotifierProvider(widget.chatId).notifier,
                          )
                          .updateMessage(updatedMessage);
                      _messageRepository.updateMessage(updatedMessage);
                    }
                  },
                  maxLines: null,
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AssistantMessage(content: message.content),
                  // SizedBox(height: context.spacing.small),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Regenerate Button
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        padding: EdgeInsets.all(context.spacing.small),
                        constraints: BoxConstraints(),
                        iconSize: 16,
                        color: context.colors.primary,
                        tooltip: 'Regenerate',
                        onPressed:
                            _isGenerating
                                ? null
                                : () => _regenerateMessage(message),
                      ),
                      // Copy Button
                      IconButton(
                        icon: const Icon(Icons.copy),
                        padding: EdgeInsets.all(context.spacing.small),
                        constraints: BoxConstraints(),
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
                ],
              ),
    );
  }

  /// Regenerates a specific AI message by re-sending the last user message.
  void _regenerateMessage(ChatMessage originalMessage) {
    // Find the last user message before this AI message
    final lastUserMessageIndex = ref
        .watch(messagesNotifierProvider(widget.chatId))
        .lastIndexWhere((msg) => msg.isUser);

    // If there's no previous user message, do nothing
    if (lastUserMessageIndex == -1) return;

    final lastUserMessage =
        ref.watch(
          messagesNotifierProvider(widget.chatId),
        )[lastUserMessageIndex];

    // Remove the last AI message (the one being regenerated)
    ref
        .read(messagesNotifierProvider(widget.chatId).notifier)
        .removeMessage(originalMessage);

    // Send the last user message again to regenerate the response
    _sendMessage(lastUserMessage.content);
  }

  /// Builds the input area for sending messages.
  Widget _buildInputArea(BuildContext context, SettingsState settings) {
    // Added settings param
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(context.spacing.small),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.white10 : Colors.black12,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(
                  color: context.colors.onSurface.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: context.colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.radius.large),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.radius.large),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.radius.large),
                  borderSide: BorderSide.none,
                ),
                // contentPadding: EdgeInsets.symmetric(
                //   horizontal: context.spacing.large,
                //   vertical: context.spacing.medium,
                // ),
                hoverColor: Colors.transparent,
              ),
              style: context.typography.body1,
              onSubmitted: _isGenerating ? null : _sendMessage,
              enabled: !_isGenerating,
              maxLines: null,
              textInputAction: TextInputAction.send,
            ),
            SizedBox(height: context.spacing.small),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Plus button to open options
                IconButton(
                  onPressed: _showOptions,
                  icon: Icon(Icons.add),
                  color: context.colors.primary,
                ),
                Row(
                  children: [
                    // Camera button
                    IconButton(
                      onPressed: _handleCamera,
                      icon: Icon(Icons.camera_alt_outlined),
                      color: context.colors.primary,
                    ),
                    // Photo button
                    IconButton(
                      onPressed: _handlePhotos,
                      icon: Icon(Icons.photo_outlined),
                      color: context.colors.primary,
                    ),
                    // Send button
                    IconButton(
                      onPressed:
                          _isGenerating
                              ? _stopStream
                              // Disable send if API key is missing (already handled by build, but for safety)
                              : settings.apiKey.isEmpty
                              ? null
                              : () => _sendMessage(_textController.text),
                      icon: Icon(
                        _isGenerating ? Icons.stop : Icons.send,
                        color:
                            settings.apiKey.isEmpty
                                ? context.colors.onSurface.withValues(
                                  alpha: 0.4,
                                ) // Dim if disabled
                                : context.colors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Function to show options dialog when plus icon is tapped
  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? context.colors.surfaceVariant
                    : context.colors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(context.radius.medium),
              topRight: Radius.circular(context.radius.medium),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: context.spacing.large),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () {
                        // Handle camera
                        Navigator.pop(context);
                      },
                    ),
                    _buildOptionButton(
                      icon: Icons.photo_outlined,
                      label: 'Photos',
                      onTap: () {
                        // Handle photos
                        Navigator.pop(context);
                      },
                    ),
                    _buildOptionButton(
                      icon: Icons.upload_file_outlined,
                      label: 'Files',
                      onTap: () {
                        // Handle files
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),

              // Divider and other options
              Divider(height: 1),
              _buildSettingsOption(
                icon: Icons.brush_outlined,
                label: 'Choose style',
                trailing: Row(
                  children: [
                    Text(
                      'Normal',
                      style: TextStyle(color: context.colors.secondary),
                    ),
                    Icon(Icons.chevron_right, color: context.colors.secondary),
                  ],
                ),
              ),

              _buildSettingsOption(
                icon: Icons.timer_outlined,
                label: 'Use extended thinking',
                trailing: Row(
                  children: [
                    Text(
                      'PRO',
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: context.spacing.medium),
                    Container(
                      width: 40,
                      height: 24,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(
                          context.radius.medium,
                        ),
                      ),
                      padding: EdgeInsets.all(2),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1),
              _buildSettingsOption(
                icon: Icons.settings,
                label: 'Manage tools',
                trailing: Row(
                  children: [
                    Text(
                      '2 enabled',
                      style: TextStyle(color: context.colors.secondary),
                    ),
                    Icon(Icons.chevron_right, color: context.colors.secondary),
                  ],
                ),
              ),
              SizedBox(height: context.spacing.large),
            ],
          ),
        );
      },
    );
  }

  // Helper method to build option buttons
  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(context.radius.medium),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: context.colors.primary),
            SizedBox(height: context.spacing.small),
            Text(label, style: context.typography.body2),
          ],
        ),
      ),
    );
  }

  // Helper method to build settings options
  Widget _buildSettingsOption({
    required IconData icon,
    required String label,
    required Widget trailing,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.large,
        vertical: context.spacing.medium,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: context.colors.onSurface.withValues(alpha: 0.7),
          ),
          SizedBox(width: context.spacing.medium),
          Text(label, style: context.typography.body1),
          Spacer(),
          trailing,
        ],
      ),
    );
  }

  void _handleCamera() {
    // Implement camera functionality
  }

  void _handlePhotos() {
    // Implement photo selection
  }

  // cleanup
  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _systemPromptController.dispose();
    _streamSubscription?.cancel();
    _messageStreamController.close();
    super.dispose();
  }
}
