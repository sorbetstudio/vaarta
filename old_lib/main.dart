import 'package:flutter/material.dart';
// import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'dart:ui';
import 'chat_list_screen.dart';
import 'settings_screen.dart';
import 'llm_client.dart';

void main() {
  runApp(const MyApp());
  WakelockPlus.enable();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('darkMode') ?? true;
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vaarta',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          surface: Colors.black, //that good amoled stuff
        ),
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
        ),
      ),
      home: FutureBuilder<String>(
        future: _getInitialChatId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            return ChatScreen(chatId: snapshot.data ?? 'default_chat');
          }
        },
      ),
    );
  }

  Future<String> _getInitialChatId() async {
    final dbHelper = DatabaseHelper.instance;
    final chats = await dbHelper.getAllChatsMetadata();
    if (chats.isEmpty) {
      return await dbHelper.createNewChat();
    } else {
      return chats.first[DatabaseHelper.chatColumnChatId];
    }
  }
}

// Message model to store chat history
class ChatMessage {
  final String chatId;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.chatId,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

class ThinkingBoxMarkdownWidget extends StatefulWidget {
  final String markdownContent;
  final MarkdownStyleSheet styleSheet;

  const ThinkingBoxMarkdownWidget({
    Key? key,
    required this.markdownContent,
    required this.styleSheet,
  }) : super(key: key);

  @override
  State<ThinkingBoxMarkdownWidget> createState() =>
      _ThinkingBoxMarkdownWidgetState();
}

class _ThinkingBoxMarkdownWidgetState extends State<ThinkingBoxMarkdownWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _expanded = false;
  bool _hasThinkingContent = false;
  String _thinkingContent = '';
  String _processedMarkdown = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _processContent();
  }

  void _processContent() {
    final content = widget.markdownContent;
    // Regular expression to match the special tags and capture content
    final thinkRegex = RegExp(r'<think>([\s\S]*?)<\/think>', multiLine: true);

    if (thinkRegex.hasMatch(content)) {
      _hasThinkingContent = true;
      _thinkingContent = thinkRegex
          .allMatches(content)
          .map((match) => match.group(1) ?? '')
          .join('\n\n');

      _processedMarkdown = content.replaceAll(thinkRegex, '').trim();
    } else {
      _hasThinkingContent = false;
      _processedMarkdown = content;
    }
  }

  @override
  void didUpdateWidget(ThinkingBoxMarkdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markdownContent != widget.markdownContent) {
      _processContent();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thinking box - now appears above the main content
        if (_hasThinkingContent) ...[
          InkWell(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
                if (_expanded) {
                  _controller.forward();
                } else {
                  _controller.reverse();
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                  width: 1,
                ),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.psychology,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Thinking Process',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        RotationTransition(
                          turns: Tween(
                            begin: 0.0,
                            end: 0.5,
                          ).animate(_animation),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRect(
                    child: SizeTransition(
                      sizeFactor: _animation,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: MarkdownBody(
                          data: _thinkingContent,
                          styleSheet: widget.styleSheet,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Main content after thinking box
        MarkdownBody(data: _processedMarkdown, styleSheet: widget.styleSheet),
      ],
    );
  }
}

class ThinkingAnimation extends StatefulWidget {
  final Color color;
  final String thinkingText;

  const ThinkingAnimation({
    super.key,
    required this.color,
    this.thinkingText = "Thinking...",
  });

  @override
  State<ThinkingAnimation> createState() => _ThinkingAnimationState();
}

class _ThinkingAnimationState extends State<ThinkingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _dotController;
  late AnimationController _textController;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

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
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.color.withOpacity(0.3), width: 1),
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
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
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
              widget.thinkingText,
              style: TextStyle(
                color: widget.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _bounceCurve(double value) {
    if (value < 0.5) {
      return 4 * value * value * value;
    } else {
      final f = ((2 * value) - 2);
      return 0.5 * f * f * f + 1;
    }
  }
}

class ThinkingBubble extends StatefulWidget {
  final String content;
  final ThemeData theme;

  const ThinkingBubble({Key? key, required this.content, required this.theme})
    : super(key: key);

  @override
  State<ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.primaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
                if (_isExpanded) {
                  _expandController.forward();
                } else {
                  _expandController.reverse();
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    color: widget.theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thinking Process',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  RotationTransition(
                    turns: Tween(
                      begin: 0.0,
                      end: 0.5,
                    ).animate(_expandAnimation),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: widget.theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          ClipRect(
            child: SizeTransition(
              sizeFactor: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: MarkdownBody(
                  data: widget.content,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: widget.theme.colorScheme.onSurface.withOpacity(
                        0.9,
                      ),
                      fontSize: 14,
                    ),
                    code: TextStyle(
                      backgroundColor:
                          widget.theme.brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                      color: widget.theme.colorScheme.onSurface,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color:
                          widget.theme.brightness == Brightness.dark
                              ? Colors.grey.shade900
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StreamingMessage extends StatelessWidget {
  final String content;
  final ThemeData theme;
  final bool isDark;

  const StreamingMessage({
    Key? key,
    required this.content,
    required this.theme,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract thinking content
    final thinkRegex = RegExp(r'<think>([\s\S]*?)<\/think>', multiLine: true);
    String thinkingContent = '';
    String outputContent = content;

    if (thinkRegex.hasMatch(content)) {
      thinkingContent = thinkRegex
          .allMatches(content)
          .map((match) => match.group(1) ?? '')
          .join('\n\n');

      outputContent = content.replaceAll(thinkRegex, '').trim();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thinking bubble
        if (thinkingContent.isNotEmpty)
          ThinkingBubble(content: thinkingContent, theme: theme),

        // Output content
        Container(
          decoration: BoxDecoration(
            color:
                isDark
                    ? theme.colorScheme.surface
                    : theme.colorScheme.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: MarkdownBody(
            data: outputContent,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 16,
              ),
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
        ),
      ],
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isGenerating = false;
  String _currentStreamMessage = '';
  final dbHelper = DatabaseHelper.instance;
  String _apiKey = '';
  String _selectedModel = "cognitivecomputations/dolphin3.0-mistral-24b:free";
  bool _useHapticFeedback = true;
  bool _showReasoning = true;

  // OpenRouter specific settings
  double _temperature = 0.7;
  int _maxTokens = 1000;
  double _topP = 0.9;
  final String systemPrompt =
      '''You are Vaarta AI, a helpful assistant. Your responses should be concise, avoiding unnecessary details. Your personality is lovable, warm, and inviting. ''';
  final String _reasoningPrompt =
      '''You are a deep thinking AI, you may use extremely long chains of thought to deeply consider the problem and deliberate with yourself via systematic reasoning processes to help come to a correct solution prior to answering. You should enclose your thoughts and internal monologue inside <think> </think> tags, and then provide your solution or response to the problem. Your name is Vaarta.''';

  late LLMClient _llmClient;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('apiKey') ?? '';
      _selectedModel =
          prefs.getString('selectedModel') ??
          "cognitivecomputations/dolphin3.0-mistral-24b:free";
      _useHapticFeedback = prefs.getBool('hapticFeedback') ?? true;
      _showReasoning = prefs.getBool('showReasoning') ?? true;

      // Load OpenRouter specific settings
      _temperature = prefs.getDouble('temperature') ?? 0.7;
      _maxTokens = prefs.getInt('maxTokens') ?? 4096;
      _topP = prefs.getDouble('topP') ?? 0.9;
    });

    _initializeLLMClient();
  }

  void _initializeLLMClient() {
    // Create OpenRouter configuration
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
      ),
    );
  }

  _loadMessages() async {
    List<ChatMessage> messagesFromDb = await dbHelper.getMessages(
      widget.chatId,
    );
    setState(() {
      _messages = messagesFromDb;
    });
    snapToBottom();
  }

  void _openSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const SettingsScreen()))
        .then((_) => _loadSettings());
  }

  bool _isScrolling = false;

  void smoothScrollToBottom() {
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

  void snapToBottom() {
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
      _textController.clear();
    });

    dbHelper.insertMessage(userMessage);

    try {
      // Create messages list with system message at the beginning
      final List<LLMMessage> messages = [
        LLMMessage(
          role: 'system',
          content: _showReasoning ? _reasoningPrompt : systemPrompt,
        ),
      ];

      // Add conversation history
      messages.addAll(
        _messages.map(
          (msg) => LLMMessage(
            role: msg.isUser ? 'user' : 'assistant',
            content: msg.content,
          ),
        ),
      );

      String fullResponse = '';

      await for (final chunk in _llmClient.streamCompletion(messages)) {
        setState(() {
          fullResponse += chunk;
          _currentStreamMessage = fullResponse;
          if (_useHapticFeedback) {
            HapticFeedback.lightImpact();
          }
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          snapToBottom();
        });
      }
      print(fullResponse);

      final aiMessage = ChatMessage(
        chatId: widget.chatId,
        content: fullResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
        _currentStreamMessage = '';
        _isGenerating = false;
      });
      dbHelper.insertMessage(aiMessage);
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
      dbHelper.insertMessage(errorMessage);
    }
    snapToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: AppBar(
              backgroundColor:
                  isDark
                      ? Colors.black.withOpacity(0.7)
                      : Colors.white.withOpacity(0.7),
              elevation: 0,
              title: const Text('Chat'),
              leading: IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: _openChatList,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: _openSettings,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length + (_isGenerating ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isGenerating) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child:
                          _currentStreamMessage.isEmpty
                              ? Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ThinkingAnimation(
                                  color: theme.colorScheme.primary,
                                ),
                              )
                              : StreamingMessage(
                                content: _currentStreamMessage,
                                theme: theme,
                                isDark: isDark,
                              ),
                    ),
                  );
                }
                return _buildChatMessage(_messages[index], theme, isDark);
              },
            ),
          ),
          _buildInputArea(theme, isDark),
        ],
      ),
    );
  }

  void _openChatList() {
    Navigator.of(context).push(SlideRightRoute(page: const ChatListScreen()));
  }

  Widget _buildChatMessage(ChatMessage message, ThemeData theme, bool isDark) {
    final bool isUserMessage = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child:
              isUserMessage
                  ? Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Colors.white, fontSize: 16),
                        code: TextStyle(
                          backgroundColor:
                              isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                          color: theme.colorScheme.onSurface,
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color:
                              isDark
                                  ? Colors.grey.shade900
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: theme.dividerColor,
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  : StreamingMessage(
                    content: message.content,
                    theme: theme,
                    isDark: isDark,
                  ),
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
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
                  fillColor:
                      isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
              onPressed:
                  _isGenerating
                      ? null
                      : () => _sendMessage(_textController.text),
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
    super.dispose();
  }
}

// For smoother custom transitions
class SlideRightRoute extends PageRouteBuilder {
  final Widget page;

  SlideRightRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      );
}
