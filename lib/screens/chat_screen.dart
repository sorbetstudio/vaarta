import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../services/database_helper.dart';
import '../services/llm_client.dart';
import 'chat_list_screen.dart';
import 'settings_screen.dart';
import 'package:vaarta/widgets/sk_ui.dart';
import 'package:vaarta/utils/utils.dart';
import 'package:vaarta/models/models.dart';

/// Displays a chat interface for sending and receiving messages with an AI.
class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final dbHelper = DatabaseHelper.instance;
  late LLMClient _llmClient;

  List<ChatMessage> _messages = [];
  bool _isGenerating = false;
  String _streamedResponse = "";
  bool _isScrolling = false;
  bool _isEditingMessages = false;

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
      _systemPromptController.text = _systemPromptSetting.isNotEmpty ? _systemPromptSetting : defaultSystemPrompt;
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
    final messagesFromDb = await dbHelper.getMessages(widget.chatId);
    setState(() => _messages = messagesFromDb);
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

    setState(() {
      _messages.add(userMessage);
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
          content: _systemPromptSetting.isNotEmpty ? _systemPromptSetting : defaultSystemPrompt,
        ),
        ..._messages.map((msg) => LLMMessage(role: msg.isUser ? 'user' : 'assistant', content: msg.content)),
      ];

      await for (final chunk in _llmClient.streamCompletion(messages)) {
        if (!mounted) return;
        setState(() {
          _streamedResponse += chunk;
          if (_useHapticFeedback) HapticFeedback.lightImpact();
        });
        _smoothScrollToBottom();
      }

      final aiMessage = ChatMessage(
        chatId: widget.chatId,
        content: _streamedResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(aiMessage);
        _isGenerating = false;
      });
      await dbHelper.insertMessage(aiMessage);
      _snapToBottom();
    } catch (e) {
      final errorMessage = ChatMessage(
        chatId: widget.chatId,
        content: 'Error: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(errorMessage);
        _isGenerating = false;
      });
      await dbHelper.insertMessage(errorMessage);
      _snapToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          Expanded(child: _buildMessageListView(theme)),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  /// Builds the app bar with navigation and editing options.
  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AppBar(
            backgroundColor: isDark ? Colors.black.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.7),
            elevation: 0,
            title: const Text('Chat'),
            leading: IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: _openChatList),
            actions: [
              IconButton(icon: const Icon(Icons.edit_note), onPressed: _editSystemPrompt),
              IconButton(
                icon: Icon(_isEditingMessages ? Icons.visibility : Icons.edit),
                onPressed: () => setState(() => _isEditingMessages = !_isEditingMessages),
              ),
              IconButton(icon: const Icon(Icons.settings), onPressed: _openSettings),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens a dialog to edit the system prompt.
  void _editSystemPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit System Prompt'),
        content: TextField(
          controller: _systemPromptController,
          maxLines: null,
          decoration: const InputDecoration(hintText: "Enter system prompt"),
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
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
  Widget _buildMessageListView(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: _messages.length + (_isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isGenerating) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _streamedResponse.isEmpty
                  ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: ThinkingAnimation(color: theme.colorScheme.primary),
              )
                  : StreamingMessage(content: _streamedResponse, theme: theme, isDark: isDark),
            ),
          );
        }
        return _buildChatMessage(_messages[index], theme);
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
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
          child: isUserMessage ? _buildUserMessage(message, theme) : _buildAssistantMessage(message, theme),
        ),
      ),
    );
  }

  /// Builds a user message with editing capability.
  Widget _buildUserMessage(ChatMessage message, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final messageController = TextEditingController(text: message.content);
    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: _isEditingMessages
          ? TextFormField(
        controller: messageController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration.collapsed(
          hintText: "Enter message",
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
        onChanged: (value) {
          final index = _messages.indexWhere((m) => m.timestamp == message.timestamp);
          if (index != -1) {
            _messages[index] = message.copyWith(content: value);
            dbHelper.updateMessage(message.copyWith(content: value));
          }
        },
        maxLines: null,
      )
          : MarkdownBody(
        data: message.content,
        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
          p: const TextStyle(color: Colors.white, fontSize: 16),
          code: TextStyle(
            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            color: theme.colorScheme.onSurface,
            fontFamily: 'monospace',
          ),
          codeblockDecoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(left: BorderSide(color: theme.dividerColor, width: 4)),
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
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: _isEditingMessages
          ? TextFormField(
        controller: messageController,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
        decoration: InputDecoration.collapsed(
          hintText: "Enter message",
          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        onChanged: (value) {
          final index = _messages.indexWhere((m) => m.timestamp == message.timestamp);
          if (index != -1) {
            _messages[index] = message.copyWith(content: value);
            dbHelper.updateMessage(message.copyWith(content: value));
          }
        },
        maxLines: null,
      )
          : MarkdownBody(
        data: message.content,
        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
          p: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
          code: TextStyle(
            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            color: theme.colorScheme.onSurface,
            fontFamily: 'monospace',
          ),
          codeblockDecoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(left: BorderSide(color: theme.dividerColor, width: 4)),
          ),
        ),
      ),
    );
  }

  /// Builds the input area for sending messages.
  Widget _buildInputArea(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : theme.colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  filled: true,
                  fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: _isGenerating ? null : _sendMessage,
                enabled: !_isGenerating,
                maxLines: null,
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              mini: true,
              onPressed: _isGenerating ? null : () => _sendMessage(_textController.text),
              backgroundColor: theme.colorScheme.primary,
              child: Icon(Icons.send, color: theme.colorScheme.onPrimary),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }
}

/// Displays a "Thinking..." animation during AI response generation.
class ThinkingAnimation extends StatefulWidget {
  final Color color;

  const ThinkingAnimation({super.key, required this.color});

  @override
  State<ThinkingAnimation> createState() => _ThinkingAnimationState();
}

class _ThinkingAnimationState extends State<ThinkingAnimation> with TickerProviderStateMixin {
  late AnimationController _dotController;
  late AnimationController _textController;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _textOpacity = Tween<double>(begin: 0.6, end: 1.0).animate(_textController);
  }

  @override
  void dispose() {
    _dotController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _dotController,
            builder: (context, child) {
              return Row(
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final progress = (_dotController.value + delay) % 1.0;
                  final size = 4.0 + 4.0 * _bounceCurve(progress);
                  return Container(
                    width: 8,
                    height: 20,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 8),
          FadeTransition(
            opacity: _textOpacity,
            child: Text(
              'Thinking...',
              style: TextStyle(color: widget.color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  double _bounceCurve(double value) {
    if (value < 0.5) return 4 * value * value * value;
    final f = (2 * value) - 2;
    return 0.5 * f * f * f + 1;
  }
}