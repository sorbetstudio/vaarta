import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import 'dart:ui';
import 'chat_list_screen.dart';
import 'settings_screen.dart';
import '../services/llm_client.dart';
import '../main.dart'; // Import ChatMessage from main.dart

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
  String _streamedResponse = ""; // Accumulates the *entire* response

  // Preferences
  String _apiKey = '';
  String _selectedModel = "cognitivecomputations/dolphin3.0-mistral-24b:free";
  bool _useHapticFeedback = true;
  bool _showReasoning = true;
  String _systemPromptSetting = '';
  double _temperature = 0.7;
  int _maxTokens = 1000;
  double _topP = 0.9;

  // Add TextEditingController for system prompt
  final TextEditingController _systemPromptController = TextEditingController();

  final String defaultSystemPrompt =
      '''You are Vaarta AI, a helpful assistant. Your responses should be concise, avoiding unnecessary details. Your personality is lovable, warm, and inviting. ''';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadSettings();
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
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('apiKey') ?? '';
      _selectedModel = prefs.getString('selectedModel') ??
          "cognitivecomputations/dolphin3.0-mistral-24b:free";
      _useHapticFeedback = prefs.getBool('hapticFeedback') ?? true;
      _showReasoning = prefs.getBool('showReasoning') ?? true;
      _systemPromptSetting = prefs.getString('systemPrompt') ?? '';
      _temperature = prefs.getDouble('temperature') ?? 0.7;
      _maxTokens = prefs.getInt('maxTokens') ?? 4096;
      _topP = prefs.getDouble('topP') ?? 0.9;

      // Initialize system prompt controller
      _systemPromptController.text = _systemPromptSetting.isNotEmpty
          ? _systemPromptSetting
          : defaultSystemPrompt;
    });
    _initializeLLMClient();
  }

  void _initializeLLMClient() {
    final openRouterConfig = OpenRouterConfig(
      temperature: _temperature,
      maxTokens: _maxTokens,
      topP: _topP,
      presencePenalty: 0.0,
      frequencyPenalty: 0.0,
      reasoning: _showReasoning
          ? {"exclude": false, "max_tokens": 400}
          : null,
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

  Future<void> _loadMessages() async {
    final messagesFromDb = await dbHelper.getMessages(widget.chatId);
    setState(() {
      _messages = messagesFromDb;
    });
    _snapToBottom();
  }

  void _openSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const SettingsScreen()))
        .then((_) => _loadSettings());
  }

  bool _isScrolling = false; // Prevent concurrent scroll animations

  void _smoothScrollToBottom() {
    if (_isScrolling || !_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _isScrolling =
            true; // Set the flag to prevent concurrent animations
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 16), // Short duration
          curve: Curves.linear, // Linear curve for consistent speed
        );
      } finally {
        _isScrolling =
            false; // Reset the flag when the animation completes (or errors)
      }
    });
  }

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
      _streamedResponse = ""; // Reset for each new message
      _textController.clear();
    });

    dbHelper.insertMessage(userMessage);
    snapToBottom();

    try {
      final List<LLMMessage> messages = [
        LLMMessage(
          role: 'system',
          content: _systemPromptSetting.isNotEmpty
              ? _systemPromptSetting
              : defaultSystemPrompt,
        ),
      ];
      messages.addAll(_messages.map((msg) => LLMMessage(
            role: msg.isUser ? 'user' : 'assistant',
            content: msg.content,
          )));

      // Stream processing (accumulate the ENTIRE response)
      await for (final chunk in _llmClient.streamCompletion(messages)) {
        if (!mounted) return;
        setState(() {
          _streamedResponse += chunk; // Accumulate the *entire* chunk
          if (_useHapticFeedback) {
            HapticFeedback.lightImpact();
          }
        });
        _smoothScrollToBottom();
      }

      // After the stream completes, add the AI message to the database
      final aiMessage = ChatMessage(
        chatId: widget.chatId,
        content: _streamedResponse, // Store the *complete* response
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
        _isGenerating = false;
      });
      dbHelper.insertMessage(aiMessage);
      _snapToBottom(); // Snap to bottom after adding the AI message

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

    PreferredSizeWidget _buildAppBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: isDark
                ? Colors.black.withOpacity(0.7)
                : Colors.white.withOpacity(0.7),
            elevation: 0,
            title: const Text('Chat'),
            leading: IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: _openChatList,
            ),
            actions: [
              // Add system prompt edit button
              IconButton(
                icon: const Icon(Icons.edit_note),
                onPressed: _editSystemPrompt,
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _openSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editSystemPrompt() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit System Prompt'),
          content: TextField(
            controller: _systemPromptController,
            maxLines: null, // Allow multiple lines
            decoration: const InputDecoration(hintText: "Enter system prompt"),
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
                setState(() {
                  _systemPromptSetting = newPrompt;
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('systemPrompt', newPrompt);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

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
              child:
                  _streamedResponse.isEmpty // Show ThinkingAnimation ONLY at the start
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child:
                              ThinkingAnimation(color: theme.colorScheme.primary),
                        )
                      : StreamingMessage( // Pass the *entire* streamed response
                          content: _streamedResponse,
                          theme: theme,
                          isDark: isDark,
                        ),
            ),
          );
        }
        // Display existing messages
        return _buildChatMessage(_messages[index], theme);
      },
    );
  }

  void _openChatList() {
    Navigator.of(context).push(SlideRightRoute(page: const ChatListScreen()));
  }

  Widget _buildChatMessage(ChatMessage message, ThemeData theme) {
    final isUserMessage = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child: isUserMessage
              ? _buildUserMessage(message, theme)
              : _buildAssistantMessage(message, theme), // Use for past messages
        ),
      ),
    );
  }

  Widget _buildUserMessage(ChatMessage message, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextFormField(
        initialValue: message.content,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration.collapsed(
          hintText: "Enter message",
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        onChanged: (value) {
          // Update the message in the _messages list
          final index = _messages.indexWhere((m) => m.timestamp == message.timestamp);
          if (index != -1) {
            _messages[index] = ChatMessage(
              chatId: message.chatId,
              content: value,
              isUser: message.isUser,
              timestamp: message.timestamp, // Keep original timestamp
            );

            // Update the message in the database
            dbHelper.updateMessage(
              message.copyWith(content: value),
            ); // Use copyWith
          }
        },
        maxLines: null,
      ),
    );
  }

  Widget _buildAssistantMessage(ChatMessage message, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
      return Container(
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surface
              : theme.colorScheme.surface.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: TextFormField(
          initialValue: message.content,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
          decoration: InputDecoration.collapsed(
            hintText: "Enter message", // This shouldn't really show for AI messages
            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          onChanged: (value) {
            // Update in _messages
            final index = _messages.indexWhere((m) => m.timestamp == message.timestamp);
              if (index != -1) {
                _messages[index] = ChatMessage(
                  chatId: message.chatId,
                  content: value,
                  isUser: message.isUser,
                  timestamp: message.timestamp
                );
                // Update in database
                dbHelper.updateMessage(message.copyWith(content: value));
              }
          },
          maxLines: null,
        ),
      );
  }

  Widget _buildInputArea(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
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
                  fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: _isGenerating ? null : _sendMessage,
                enabled: !_isGenerating,
                maxLines: null, // Allow multiple lines
                textInputAction: TextInputAction.send, // Show send button
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
    _systemPromptController.dispose(); // Dispose the system prompt controller
    super.dispose();
  }
}

// Displays the "Thinking..." animation
class ThinkingAnimation extends StatefulWidget {
  final Color color;
  // final String thinkingText; // Remove thinkingText, going to make this editable

  const ThinkingAnimation({
    super.key,
    required this.color,
    // this.thinkingText = "Thinking...", // Remove default value.
  });

  @override
  State<ThinkingAnimation> createState() => _ThinkingAnimationState();
}

class _ThinkingAnimationState extends State<ThinkingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _dotController;
  late AnimationController _textController;
  late Animation<double> _textOpacity;

  // Add a TextEditingController
  final TextEditingController _thinkingTextController =
      TextEditingController(text: "Thinking...");

  @override
  void initState() {
    super.initState();

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Total animation cycle
    )..repeat();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Fade in/out duration
    )..repeat(reverse: true); // Fade in and out

    _textOpacity = Tween<double>(begin: 0.6, end: 1.0).animate(_textController);
  }

  @override
  void dispose() {
    _dotController.dispose();
    _textController.dispose();
    _thinkingTextController.dispose(); // Dispose the controller
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
        mainAxisSize: MainAxisSize.min, // Wrap content tightly
        children: [
          // Animated dots
          AnimatedBuilder(
            animation: _dotController,
            builder: (context, child) {
              return Row(
                children: List.generate(3, (index) {
                  // Calculate delay for each dot
                  final delay = index * 0.2; // 0.2-second delay between dots
                  // Calculate the progress of each dot, accounting for the delay
                  final progress = (_dotController.value + delay) % 1.0;
                  // Use a bouncing curve for the animation
                  final size = 4.0 + 4.0 * _bounceCurve(progress);

                  return Container(
                    width: 8, // Fixed width for spacing
                    height: 20,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      width: size, // Dynamic size based on animation
                      height: size,
                      decoration: BoxDecoration(
                        color: widget.color, // Use the provided color
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 8),
          // Fading "Thinking..." text
          FadeTransition(
            opacity: _textOpacity,
            child:
              // Use a TextField to allow editing
              SizedBox( // Constrain the width
                width: 100, // Adjust as needed
                child: TextFormField(
                  controller: _thinkingTextController,
                  style: TextStyle(
                    color: widget.color, // Use the provided color
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Thinking...',
                    hintStyle: TextStyle(color: widget.color.withOpacity(0.6))
                  ),
                  onChanged: (value) {
                    // Could save to SharedPreferences if desired.
                  },
                ),
              )
          ),
        ],
      ),
    );
  }

  // Custom bounce curve
  double _bounceCurve(double value) {
    if (value < 0.5) {
      return 4 * value * value * value;
    } else {
      final f = ((2 * value) - 2);
      return 0.5 * f * f * f + 1;
    }
  }
}

// The ThinkingBubble widget (expandable)
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
  bool _isExpanded = false; // Initially collapsed

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Expansion duration
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut, // Smooth expansion/collapse
    );
  }

  @override
  void didUpdateWidget(ThinkingBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Important: Re-expand if content changes AND was previously expanded
    if (oldWidget.content != widget.content && _isExpanded) {
      _expandController.forward(from: 0.0); // Reset and replay animation
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Tap to expand/collapse)
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
                    color: theme.colorScheme.primary,
                    size: 20,
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
                  // Expand/Collapse icon (Rotates with animation)
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_expandAnimation),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content (Expandable Markdown)
          ClipRect(
            child: SizeTransition(
              sizeFactor: _expandAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: MarkdownBody(
                  data: widget.content,
                  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                    p: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.9),
                        fontSize: 14),
                    code: TextStyle(
                      backgroundColor: theme.brightness == Brightness.dark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      color: theme.colorScheme.onSurface,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
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

// The core widget for displaying streamed responses
class StreamingMessage extends StatelessWidget {
  final String content; // Receives the *entire* streamed response
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
    // Extract thinking content and output content using regex
    final thinkRegex = RegExp(r'<think>([\s\S]*?)<\/think>', multiLine: true);
    final thinkingContent =
        thinkRegex.allMatches(content).map((m) => m.group(1) ?? '').join('\n\n');
    final outputContent = content.replaceAll(thinkRegex, '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display ThinkingBubble if there's thinking content
        if (thinkingContent.isNotEmpty)
          ThinkingBubble(content: thinkingContent, theme: theme),

        // Display the output content
        if (outputContent.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: MarkdownBody(
              data: outputContent,
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                p: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
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
                  border:
                      Border(left: BorderSide(color: theme.dividerColor, width: 4)),
                ),
              ),
            ),
          ),
      ],
    );
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
            var tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
        );
}