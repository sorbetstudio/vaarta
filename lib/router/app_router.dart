// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vaarta/screens/chat_screen.dart';
import 'package:vaarta/screens/settings_screen.dart';
import 'package:vaarta/screens/splash_screen.dart';
import 'package:vaarta/services/database_helper.dart';

class AppRouter {
  // Route names as static constants
  static const String splash = '/';
  static const String chat = '/chat/:id';
  static const String settings = '/settings';

  // Helper methods to generate paths with parameters
  static String chatPath(String id) => '/chat/$id';

  // Initialize the router
  static final GoRouter router = GoRouter(
    initialLocation: splash,
    debugLogDiagnostics: true, // Set to false in production
    routes: _routes,
    redirect: _handleRedirect,
    errorBuilder: (context, state) => _buildErrorScreen(context, state),
  );

  // Define all routes in one place
  static final List<RouteBase> _routes = [
    GoRoute(path: splash, builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: chat,
      builder: (context, state) {
        final chatId = state.pathParameters['id']!;
        return ChatScreen(chatId: chatId);
      },
    ),
    GoRoute(
      path: settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ];

  // Handle initial routing
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    // Don't redirect the splash screen
    if (state.matchedLocation == splash) {
      return null;
    }
    return null;
  }

  // Handle routing errors
  static Widget _buildErrorScreen(BuildContext context, GoRouterState state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation Error')),
      body: Center(child: Text('No route defined for ${state.uri.path}')),
    );
  }

  // Helper method to create a new chat and navigate to it
  static Future<void> navigateToNewChat(BuildContext context) async {
    final dbHelper = DatabaseHelper.instance;
    final newChatId = await dbHelper.createNewChat();
    if (context.mounted) {
      context.go(chatPath(newChatId));
    }
  }

  // Helper to get the last active chat
  static Future<String> getLastActiveChatId() async {
    final dbHelper = DatabaseHelper.instance;
    final chats = await dbHelper.getAllChatsMetadata();

    if (chats.isEmpty) {
      // Create a new chat if none exists
      return await dbHelper.createNewChat();
    }

    // Return the most recently used chat
    return chats.first[DatabaseHelper.chatColumnChatId];
  }
}
