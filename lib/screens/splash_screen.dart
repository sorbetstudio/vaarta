// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vaarta/router/app_router.dart';
import 'package:vaarta/services/database_helper.dart';
import 'package:vaarta/theme/theme_extensions.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Add any initialization logic here
    await Future.delayed(const Duration(seconds: 2)); // For demo purposes

    // Check if there are any existing chats
    final dbHelper = DatabaseHelper.instance;
    final chats = await dbHelper.getAllChatsMetadata();

    if (!mounted) return;

    if (chats.isEmpty) {
      // Create a new chat and navigate to it
      AppRouter.navigateToNewChat(context);
    } else {
      // Navigate to chat list
      context.go(AppRouter.chatList);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Icon(
              Icons.chat_bubble_outline,
              size: 120,
              color: context.colors.primary,
            ),
            const SizedBox(height: 32),
            // App name
            Text(
              'Vaarta',
              style: context.typography.h1.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Loading indicator
            CircularProgressIndicator(color: context.colors.primary),
          ],
        ),
      ),
    );
  }
}
