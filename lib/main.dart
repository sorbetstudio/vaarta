// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaarta/providers/theme_notifier.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'services/database_helper.dart';
import 'screens/chat_screen.dart';

// Main entry point of the application
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  // Set up the app with Provider for state management
  runApp(
    ProviderScope(child: const MyApp(),),
  );
  // Prevent the screen from sleeping during app usage
  WakelockPlus.enable();
}

// Manages the app's theme state using Provider

// Root widget of the Vaarta application
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    // final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      title: 'Vaarta',
      debugShowCheckedModeBanner: false,
      themeMode: ref.watch(themeNotifierProvider),
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      home: FutureBuilder<String>(
        future: _getInitialChatId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return ChatScreen(chatId: snapshot.data ?? 'default_chat');
        },
      ),
    );
  }

  // Defines the light theme configuration
  ThemeData _lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF0F0F0),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF007BFF),
        secondary: Color(0xFF6C757D),
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
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: Color(0xFF007BFF),
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

  // Defines the dark theme configuration
  ThemeData _darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Colors.blue,
        secondary: Colors.blueAccent,
        surface: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
    );
  }

  // Retrieves or creates an initial chat ID from the database
  Future<String> _getInitialChatId() async {
    final dbHelper = DatabaseHelper.instance;
    final chats = await dbHelper.getAllChatsMetadata();
    if (chats.isEmpty) {
      return await dbHelper.createNewChat();
    }
    return chats.first[DatabaseHelper.chatColumnChatId];
  }
}

