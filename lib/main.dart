import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'services/database_helper.dart';
import 'screens/chat_screen.dart';

// Main entry point of the application
void main() {
  // Set up the app with Provider for state management
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
  // Prevent the screen from sleeping during app usage
  WakelockPlus.enable();
}

// Manages the app's theme state using Provider
class AppState with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  ThemeMode get themeMode => _themeMode;

  // Loads the saved theme preference from SharedPreferences
  Future<void> initializeTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('darkMode') ?? false;
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Switches between light and dark themes
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

// Root widget of the Vaarta application
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize theme settings on app startup
    Provider.of<AppState>(context, listen: false).initializeTheme();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vaarta',
      debugShowCheckedModeBanner: false,
      themeMode: Provider.of<AppState>(context).themeMode,
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

