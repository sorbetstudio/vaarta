import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/database_helper.dart';
// import 'dart:ui';
// import 'package:vaarta/screens/chat_list_screen.dart'; // Explicit import path
// import 'package:vaarta/screens/settings_screen.dart'; // Explicit import path
import 'package:vaarta/screens/chat_screen.dart'; // Explicit import path
// import 'services/llm_client.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:flutter_markdown/flutter_markdown.dart';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
  WakelockPlus.enable();
}

// AppState class to manage the theme
class AppState with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default theme

  ThemeMode get themeMode => _themeMode;

  Future<void> initializeTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('darkMode') ?? false;
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Notify listeners after initialization
  }

  void toggleTheme() {
    _themeMode =
        (_themeMode == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Notify listeners about the theme change
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Remove ThemeMode and _loadSettings from here, as it is moved to AppState.

  @override
  void initState() {
    super.initState();
    // Initialize theme in AppState
    Provider.of<AppState>(context, listen: false).initializeTheme();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vaarta',
      debugShowCheckedModeBanner: false,
      themeMode: Provider.of<AppState>(context)
          .themeMode, // Use themeMode from AppState
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
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

  ThemeData _lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF0F0F0), // Light background
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF007BFF), // Example primary color
        secondary: Color(0xFF6C757D), // Example secondary color
      ),
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: const Color(0xFF007BFF),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Colors.blue,
        secondary: Colors.blueAccent,
        surface: Colors.black, //that good amoled stuff
      ),
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.light,
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

  ChatMessage copyWith({
    String? chatId,
    String? content,
    bool? isUser,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      chatId: chatId ?? this.chatId,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
    );
  }
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
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
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
        color: widget.theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.theme.colorScheme.primary.withValues(alpha: 0.3),
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
                      color: widget.theme.colorScheme.onSurface.withValues(alpha:
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
                    : theme.colorScheme.surface.withValues(alpha: 0.7),
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