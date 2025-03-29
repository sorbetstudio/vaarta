// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vaarta/router/app_router.dart';
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

    if (!mounted) return;

    // Navigate to the last active chat
    final lastChatId = await AppRouter.getLastActiveChatId();
    if (context.mounted) {
      context.go(AppRouter.chatPath(lastChatId));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash screen UI remains the same
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 120,
              color: context.colors.primary,
            ),
            const SizedBox(height: 32),
            Text(
              'Vaarta',
              style: context.typography.h1.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(color: context.colors.primary),
          ],
        ),
      ),
    );
  }
}
