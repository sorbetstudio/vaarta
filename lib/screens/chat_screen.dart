// lib/screens/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../services/database_helper.dart';
import '../services/llm_client.dart';
import 'chat_list_screen.dart';
import 'settings_screen.dart';
import 'package:vaarta/widgets/sk_ui.dart';
import 'package:vaarta/utils/utils.dart';
import 'package:vaarta/models/models.dart';
import 'package:vaarta/providers/messages_notifier.dart';

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

  /// Loads saved settings from SharedPreferences and initializes the LLM client.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
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
    _snapToBottom();
  }

  /// Navigates to the settings screen and reloads settings on return.
  void _openSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const SettingsScreen()))
        .then((_) => _loadSettings());
  }

  /// Smoothly scrolls to the bottom of the message list.
  void _smoothScrollToBottom() {
    if (_isScrolling || !_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
              if (!mounted) return;
              setState(() {
                _streamedResponse += chunk;
                if (_useHapticFeedback) HapticFeedback.lightImpact();
                // Add the chunk to the stream controller
                _messageStreamController.add(chunk);
              });
              _smoothScrollToBottom();
            },
            onDone: () {
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
                //_messages.add(errorMessage); // REMOVE THIS
                _isGenerating = false;
                _streamSubscription = null;
              });
              dbHelper.insertMessage(errorMessage);
              _snapToBottom();
            },
            cancelOnError: true,
          );
    } catch (e) {
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
    final theme = Theme.of(context);
    final messages = ref.watch(messagesNotifierProvider(widget.chatId));

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: Center(
        child: Container(
          width: 752.0,
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 12.0),
          child: Column(
            children: [
              Expanded(
                child: _buildMessageListView(theme, messages),
              ), // Pass messages
              _buildInputArea(theme),
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  /// Builds the app bar with navigation and editing options.
  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        color: Colors.transparent,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color:
                  isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.3),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 1,
                title: const Text('Chat'),
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
                    icon: Icon(
                      _isEditingMessages ? Icons.visibility : Icons.edit,
                    ),
                    onPressed:
                        () => setState(
                          () => _isEditingMessages = !_isEditingMessages,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: _openSettings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Opens a dialog to edit the system prompt.
  void _editSystemPrompt() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit System Prompt'),
            content: TextField(
              controller: _systemPromptController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "Enter system prompt",
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Save'),
                onPressed: () async {
                  final newPrompt = _systemPromptController.text;
                  setState(() => _systemPromptSetting = newPrompt);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('systemPrompt', newPrompt);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
    );
  }

  /// Builds the list view for displaying chat messages.
  Widget _buildMessageListView(ThemeData theme, List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      // padding: const EdgeInsets.all(12.0),
      itemCount: messages.length + (_isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && _isGenerating) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child:
                  _streamedResponse.isEmpty
                      ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ProcessingAnimation(
                          color: theme.colorScheme.primary,
                        ),
                      )
                      : AssistantMessage(
                        messageStream: _messageStreamController.stream,
                      ),
            ),
          );
        }
        return _buildChatMessage(messages[index], theme);
      },
    );
  }

  /// Navigates to the chat list screen.
  void _openChatList() {
    Navigator.of(context).push(SlideRightRoute(page: const ChatListScreen()));
  }

  /// Builds a single chat message based on its sender.
  Widget _buildChatMessage(ChatMessage message, ThemeData theme) {
    final isUserMessage = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          // constraints: BoxConstraints(
          //   maxWidth: MediaQuery.of(context).size.width * 0.85,
          // ),
          child:
              isUserMessage
                  ? _buildUserMessage(message, theme)
                  : _buildAssistantMessage(message, theme),
        ),
      ),
    );
  }

  /// Builds a user message with editing capability.
  Widget _buildUserMessage(ChatMessage message, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final messageController = TextEditingController(text: message.content);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child:
          _isEditingMessages
              ? TextFormField(
                controller: messageController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration.collapsed(
                  hintText: "Enter message",
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
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
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: const TextStyle(color: Colors.white, fontSize: 16),
                  code: TextStyle(
                    backgroundColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    color: theme.colorScheme.onSurface,
                    fontFamily: 'monospace',
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: theme.dividerColor, width: 4),
                    ),
                  ),
                ),
              ),
    );
  }

  /// Builds an assistant message with editing capability.
  Widget _buildAssistantMessage(ChatMessage message, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final messageController = TextEditingController(text: message.content);

    return Container(
      // constraints: BoxConstraints(maxWidth:MediaQuery.of(context).size.width * 1),
      child:
          _isEditingMessages
              ? Container(
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? theme.colorScheme.surface
                          : theme.colorScheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: TextFormField(
                  controller: messageController,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: "Enter message",
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                          .updateMessage(
                            updatedMessage,
                          ); // Update using provider
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Regenerate Button
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        color: theme.colorScheme.primary,
                        tooltip: 'Regenerate',
                        onPressed:
                            _isGenerating
                                ? null
                                : () => _regenerateMessage(message),
                      ),
                      // Copy Button
                      IconButton(
                        icon: const Icon(Icons.copy),
                        color: theme.colorScheme.primary,
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
      const SnackBar(content: Text('Message copied to clipboard')),
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
    // You'll need a removeMessage method in your Notifier
    ref
        .read(messagesNotifierProvider(widget.chatId).notifier)
        .removeMessage(originalMessage);

    // Send the last user message again to regenerate the response
    _sendMessage(lastUserMessage.content);
  }

  /// Builds the input area for sending messages.
  Widget _buildInputArea(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16.0),
      // margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.white10 : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        child: Column(  // Changed from Row to Column
          mainAxisSize: MainAxisSize.min, // Fix unbounded height issue
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                filled: true,
                // Uncomment this and modify:
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none, // This removes the underline
                ),
                // Or add this if you want to specifically target the underline:
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide.none, // Remove underline when enabled
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide.none, // Remove underline when focused
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hoverColor: Colors.transparent
              ),
              onSubmitted: _isGenerating ? null : _sendMessage,
              enabled: !_isGenerating,
              maxLines: null,
              textInputAction: TextInputAction.send,
            ),
            SizedBox(height: 8), // Add some spacing between TextField and buttons
            Row(  // Changed from Column to Row
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align buttons to the right
              children: [
                // Plus button to open options
                IconButton(
                  onPressed: _showOptions,
                  icon: Icon(Icons.add),
                  color: theme.colorScheme.primary,
                ),
                Row(
                  children: [
                    // Camera button
                    IconButton(
                      onPressed: _handleCamera,
                      icon: Icon(Icons.camera_alt_outlined),
                      color: theme.colorScheme.primary,
                    ),
                    // Photo button
                    IconButton(
                      onPressed: _handlePhotos,
                      icon: Icon(Icons.photo_outlined),
                      color: theme.colorScheme.primary,
                    ),
                    // Send button
                    IconButton(
                      onPressed: _isGenerating
                          ? _stopStream
                          : () => _sendMessage(_textController.text),
                      icon: Icon(
                        _isGenerating ? Icons.stop : Icons.send,
                        color: theme.colorScheme.primary,
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
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade900
                : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
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
                      style: TextStyle(color: Colors.grey),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
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
                    SizedBox(width: 10),
                    Container(
                      width: 40,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(2),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                      style: TextStyle(color: Colors.grey),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
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
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            SizedBox(height: 8),
            Text(label),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.grey.shade600),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 16),
          ),
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
