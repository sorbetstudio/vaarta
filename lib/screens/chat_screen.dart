// lib/screens/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaarta/router/app_router.dart';
import 'dart:ui';
import '../services/database_helper.dart';
import '../services/llm_client.dart';
import 'chat_list_screen.dart';
import 'settings_screen.dart';
import 'package:vaarta/widgets/sk_ui.dart';
import 'package:vaarta/utils/utils.dart';
import 'package:vaarta/models/models.dart';
import 'package:vaarta/providers/messages_notifier.dart';
import 'package:vaarta/theme/theme_extensions.dart';
import 'package:go_router/go_router.dart';
import 'package:vaarta/router/app_router.dart';
import 'package:vaarta/widgets/chat_drawer.dart';

/// Displays a chat interface for sending and receiving messages with an AI.
class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final dbHelper = DatabaseHelper.instance;
  late LLMClient _llmClient;

  bool _isGenerating = false;
  String _streamedResponse = "";
  bool _isScrolling = false;
  bool _isEditingMessages = false;
  bool _isDisposed = false; // Track if widget is disposed

  // Stream controller for RichMessageView
  late StreamController<String> _messageStreamController;
  StreamSubscription<String>? _streamSubscription;

  // Preferences
  String _apiKey = '';
  String _selectedModel = "cognitivecomputations/dolphin3.0-mistral-24b:free";
  bool _useHapticFeedback = true;
  bool _showReasoning = true;
  String _systemPromptSetting = '';
  double _temperature = 0.7;
  int _maxTokens = 1000;
  double _topP = 0.9;

  final TextEditingController _systemPromptController = TextEditingController();
  final String defaultSystemPrompt =
      '''You are Vaarta AI, a helpful assistant. Your responses should be concise, avoiding unnecessary details. Your personality is lovable, warm, and inviting.''';

  @override
  void initState() {
    super.initState();
    _messageStreamController = StreamController<String>.broadcast();
    _loadMessages();
    _loadSettings();
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

  /// Loads saved settings from SharedPreferences and initializes the LLM client.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || _isDisposed) return; // Check if still mounted

    setState(() {
      _apiKey = prefs.getString('apiKey') ?? '';
      _selectedModel = prefs.getString('selectedModel') ?? _selectedModel;
      _useHapticFeedback = prefs.getBool('hapticFeedback') ?? true;
      _showReasoning = prefs.getBool('showReasoning') ?? true;
      _systemPromptSetting = prefs.getString('systemPrompt') ?? '';
      _temperature = prefs.getDouble('temperature') ?? 0.7;
      _maxTokens = prefs.getInt('maxTokens') ?? 4096;
      _topP = prefs.getDouble('topP') ?? 0.9;
      _systemPromptController.text =
          _systemPromptSetting.isNotEmpty
              ? _systemPromptSetting
              : defaultSystemPrompt;
    });
    _initializeLLMClient();
  }

  /// Configures the LLM client with current settings.
  void _initializeLLMClient() {
    final openRouterConfig = OpenRouterConfig(
      temperature: _temperature,
      maxTokens: _maxTokens,
      topP: _topP,
      presencePenalty: 0.0,
      frequencyPenalty: 0.0,
      reasoning: _showReasoning ? {"exclude": false, "max_tokens": 400} : null,
    );
    _llmClient = LLMClient(
      config: LLMConfig(
        apiKey: _apiKey,
        model: _selectedModel,
        provider: LLMProvider.openRouter,
        openRouterConfig: openRouterConfig,
        temperature: _temperature,
        maxTokens: _maxTokens,
      ),
    );
  }

  /// Loads chat messages from the database.
  Future<void> _loadMessages() async {
    final messages = await dbHelper.getMessages(widget.chatId);
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

    await dbHelper.insertMessage(userMessage);
    _snapToBottom();

    try {
      final messages = [
        LLMMessage(
          role: 'system',
          content:
              _systemPromptSetting.isNotEmpty
                  ? _systemPromptSetting
                  : defaultSystemPrompt,
        ),
        ...ref
            .watch(messagesNotifierProvider(widget.chatId))
            .map(
              (msg) => LLMMessage(
                role: msg.isUser ? 'user' : 'assistant',
                content: msg.content,
              ),
            ),
      ];

      _streamSubscription = _llmClient
          .streamCompletion(messages)
          .listen(
            (chunk) {
              if (!mounted || _isDisposed) return;
              setState(() {
                _streamedResponse += chunk;
                if (_useHapticFeedback) HapticFeedback.lightImpact();
                // Add the chunk to the stream controller
                _messageStreamController.add(chunk);
              });
              _smoothScrollToBottom();
            },
            onDone: () {
              if (!mounted || _isDisposed) return;

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
              dbHelper.insertMessage(aiMessage);
              _snapToBottom();
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
              dbHelper.insertMessage(errorMessage);
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
      dbHelper.insertMessage(errorMessage);
      _snapToBottom();
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

      dbHelper.insertMessage(aiMessage);
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

    return Scaffold(
      key: _scaffoldKey,
      drawer: ChatDrawer(
        currentChatId: widget.chatId,
        onNewChat: _startNewChat,
      ),
      appBar: _buildAppBar(context),
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
                  child: _buildMessageListView(context, messages),
                ),
              ),
              _buildInputArea(context),
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  /// Builds the app bar with navigation and editing options.
  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
                  if (mounted && !_isDisposed) {
                    setState(() => _systemPromptSetting = newPrompt);
                  }
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('systemPrompt', newPrompt);
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
        return _buildChatMessage(context, messages[index]);
      },
    );
  }

  /// Builds a single chat message based on its sender.
  Widget _buildChatMessage(BuildContext context, ChatMessage message) {
    final isUserMessage = message.isUser;
    return Padding(
      padding: EdgeInsets.only(top: context.spacing.medium),
      child: Align(
        alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          child:
              isUserMessage
                  ? _buildUserMessage(context, message)
                  : _buildAssistantMessage(context, message),
        ),
      ),
    );
  }

  /// Builds a user message with editing capability.
  Widget _buildUserMessage(BuildContext context, ChatMessage message) {
    final messageController = TextEditingController(text: message.content);
    return Container(
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(context.radius.large),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.medium,
        vertical: context.spacing.medium,
      ),
      child:
          _isEditingMessages
              ? TextFormField(
                controller: messageController,
                style: context.typography.body1.copyWith(
                  color: context.colors.onPrimary,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: "Enter message",
                  hintStyle: TextStyle(
                    color: context.colors.onPrimary.withValues(alpha: 0.6),
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
                    dbHelper.updateMessage(updatedMessage);
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
                    color: context.colors.onPrimary,
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
  Widget _buildAssistantMessage(BuildContext context, ChatMessage message) {
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
                      dbHelper.updateMessage(updatedMessage);
                    }
                  },
                  maxLines: null,
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AssistantMessage(content: message.content),
                  SizedBox(height: context.spacing.small),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Regenerate Button
                      IconButton(
                        icon: const Icon(Icons.refresh),
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
                        color: context.colors.primary,
                        tooltip: 'Copy',
                        onPressed:
                            () => _copyMessageToClipboard(message.content),
                      ),
                    ],
                  ),
                ],
              ),
    );
  }

  /// Copies the message content to clipboard
  void _copyMessageToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    if (_useHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Message copied to clipboard',
          style: context.typography.body2,
        ),
        backgroundColor: context.colors.surface,
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
  Widget _buildInputArea(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(context.spacing.medium),
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
                              : () => _sendMessage(_textController.text),
                      icon: Icon(
                        _isGenerating ? Icons.stop : Icons.send,
                        color: context.colors.primary,
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
