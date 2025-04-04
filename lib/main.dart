// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaarta/providers/theme_notifier.dart';
import 'package:vaarta/router/app_router.dart';
import 'package:vaarta/theme/app_theme.dart';
import 'package:vaarta/theme/theme_config.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:logging/logging.dart'; // Import logging package

void main() async {
  // --- Logging Setup ---
  Logger.root.level = Level.ALL; // Log all levels for debugging
  Logger.root.onRecord.listen((record) {
    print(
      '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    );
    if (record.error != null) {
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('StackTrace: ${record.stackTrace}');
    }
  });
  final _log = Logger('main'); // Optional: Logger for main function itself
  _log.info("Logging initialized.");
  // --- End Logging Setup ---

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const ProviderScope(child: MyApp()));
  WakelockPlus.enable();
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeNotifierProvider);
    final themeMode = ref.watch(themeModeProvider);

    return themeAsync.when(
      loading: () => _buildLoadingApp(context),
      error: (err, stack) => _buildErrorApp(context, err),
      data:
          (appTheme) => MaterialApp.router(
            title: 'Vaarta',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: AppThemeData.getThemeData(AppTheme.light, context),
            darkTheme: AppThemeData.getThemeData(AppTheme.dark, context),
            routerConfig: AppRouter.router,
          ),
    );
  }

  Widget _buildLoadingApp(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
      theme: AppThemeData.getThemeData(AppTheme.light, context),
      darkTheme: AppThemeData.getThemeData(AppTheme.dark, context),
    );
  }

  Widget _buildErrorApp(BuildContext context, Object err) {
    return MaterialApp(
      home: Scaffold(body: Center(child: Text('Error loading theme: $err'))),
      theme: AppThemeData.getThemeData(AppTheme.light, context),
      darkTheme: AppThemeData.getThemeData(AppTheme.dark, context),
    );
  }
}
