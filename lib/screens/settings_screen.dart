// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaarta/providers/settings_provider.dart';
import 'package:vaarta/models/settings_state.dart'; // Import SettingsState
import 'package:vaarta/providers/theme_notifier.dart';
import 'package:vaarta/theme/theme_config.dart';
import 'package:vaarta/theme/theme_extensions.dart';
import '../services/database_helper.dart';
import 'settings/settings_api_key.dart';
import 'settings/settings_model_config.dart';
import 'settings/settings_theme_selector.dart';
import 'package:vaarta/providers/tool_registry_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  String _selectedModel = "cognitivecomputations/dolphin3.0-mistral-24b:free";
  bool _hapticFeedback = true;
  bool _showReasoning = true;
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();
  final TextEditingController _maxTokensController = TextEditingController();

  double _temperature = 0.7;
  int _maxTokens = 256;

  final Map<String, String> models = {
    "cognitivecomputations/dolphin3.0-mistral-24b:free": "Dolphin Mistral 24B",
    "cognitivecomputations/dolphin3.0-r1-mistral-24b:free":
        "Dolphin Mistral R1 24B",
    "openai/gpt-4o-mini": "GPT 4o Mini",
    "deepseek/deepseek-r1": "Deepseek R1",
    "google/gemini-2.5-pro-exp-03-25:free": "Gemini 2.5 Pro",
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final storedModel = prefs.getString('selectedModel') ?? _selectedModel;
      _selectedModel =
          models.containsKey(storedModel) ? storedModel : models.keys.first;
      _showReasoning = prefs.getBool('showReasoning') ?? true;
      _hapticFeedback = prefs.getBool('hapticFeedback') ?? true;
      _apiKeyController.text = prefs.getString('apiKey') ?? '';
      _systemPromptController.text = prefs.getString('systemPrompt') ?? '';
      _temperature = prefs.getDouble('temperature') ?? 0.7;
      _maxTokens = prefs.getInt('maxTokens') ?? 256;
      _maxTokensController.text = _maxTokens.toString();
    });
  }

  Future<void> _clearChatHistory() async {
    final dbHelper = DatabaseHelper.instance;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  "Clear Chat History?",
                  style: context.typography.h5,
                ),
                content: Text(
                  "Are you sure you want to clear all chat history? This action cannot be undone.",
                  style: context.typography.body1,
                ),
                actions: [
                  TextButton(
                    child: Text("Cancel", style: context.typography.button),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    child: Text(
                      "Clear",
                      style: context.typography.button.copyWith(
                        color: context.colors.error,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      await dbHelper.clearAllMessages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chat history cleared',
              style: context.typography.body2.copyWith(
                color: context.colors.onPrimary,
              ),
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: context.colors.primary,
            elevation: 10,
          ),
        );
      }
    }
  }

  // --- Callbacks for extracted widgets ---

  // Use notifier to update settings
  Future<void> _updateSelectedModel(String? newValue) async {
    if (newValue != null) {
      // Call notifier method - no need for setState or direct prefs access
      await ref.read(settingsProvider.notifier).updateSelectedModel(newValue);
      // Local state update might still be needed if the widget reads _selectedModel directly
      // before the provider updates, but let's try without first.
      // setState(() => _selectedModel = newValue);
    }
  }

  // Use notifier to update settings
  Future<void> _updateTemperature(double value) async {
    // Call notifier method
    await ref.read(settingsProvider.notifier).updateTemperature(value);
    // setState(() => _temperature = value);
  }

  // Use notifier to update settings
  Future<void> _updateMaxTokens(int value) async {
    final clampedValue = value.clamp(50, 4096); // Clamp here before sending
    // Call notifier method
    await ref.read(settingsProvider.notifier).updateMaxTokens(clampedValue);

    // Update local controller if necessary (e.g., if user typed invalid number)
    // The SettingsModelConfig widget already handles clamping and updating its
    // internal controller, so we might not need this here IF the provider
    // update triggers a rebuild fast enough. Let's remove it for now.
    // if (_maxTokensController.text != clampedValue.toString()) {
    //    _maxTokensController.text = clampedValue.toString();
    //    _maxTokensController.selection = TextSelection.fromPosition(
    //      TextPosition(offset: _maxTokensController.text.length),
    //    );
    // }
    // setState(() => _maxTokens = clampedValue);
  }

  // Use notifier to update settings
  Future<void> _updateApiKey(String value) async {
    // Call notifier method
    await ref.read(settingsProvider.notifier).updateApiKey(value);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _apiKeyController.dispose();
    _systemPromptController.dispose();
    _maxTokensController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the settings provider to get current values
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _animation,
        child: ListView(
          padding: EdgeInsets.all(context.spacing.small),
          children: [
            _buildSectionHeader(context, 'Appearance'),
            const SettingsThemeSelector(), // Use the new widget
            _buildDivider(context),

            _buildSectionHeader(context, 'AI Model'),
            SettingsModelConfig(
              // Read values from the watched settings provider state
              selectedModel: settings.selectedModel,
              temperature: settings.temperature,
              maxTokens: settings.maxTokens,
              models: models, // Keep local models map for dropdown labels
              onModelChanged: _updateSelectedModel,
              onTemperatureChanged: _updateTemperature,
              onMaxTokensChanged: _updateMaxTokens,
            ),

            _buildDivider(context),

            _buildSectionHeader(context, 'AI Model'),
            _buildReasoningModeTile(context, settings), // Pass settings

            _buildDivider(context),

            _buildSectionHeader(context, 'Behavior'),
            _buildHapticFeedbackTile(context, settings), // Pass settings

            _buildDivider(context),

            _buildSectionHeader(context, 'API Settings'),
            SettingsApiKeyInput(
              // Use the new widget
              controller: _apiKeyController,
              onChanged: _updateApiKey,
            ),

            _buildDivider(context),

            _buildSectionHeader(context, 'Data'),
            _buildClearChatHistoryTile(context),

            _buildDivider(context),

            _buildSectionHeader(context, 'Advanced'),
            _buildSystemPromptInput(context),

            _buildDivider(context),

            _buildSectionHeader(context, 'About'),
            _buildAboutSection(context),

            _buildDivider(context),

            _buildSectionHeader(context, 'Tools'),
            _buildToolSettingsSection(context, ref),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Settings',
        style: context.typography.h5.copyWith(
          color: context.colors.onBackground,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: context.colors.background,
      surfaceTintColor: Colors.transparent,
      shadowColor: context.colors.surface,
      // scrolledUnderElevation: 0,
      elevation: 0,
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: context.spacing.medium),
      child: Divider(
        height: 2,
        thickness: 0,
        color: context.colors.surfaceVariant,
        indent: context.spacing.medium,
        endIndent: context.spacing.medium,
      ),
    );
  }

  // Removed _buildThemeSelectorTile
  // Removed _buildModelSelector
  // Removed _buildTemperatureSlider
  // Removed _buildMaxTokensSlider
  // Removed _buildApiKeyInput

  Widget _buildReasoningModeTile(BuildContext context, SettingsState settings) {
    // Add settings parameter
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.medium,
        vertical: context.spacing.small,
      ),
      child: SwitchListTile(
        title: Text('Reasoning Mode', style: context.typography.body1),
        secondary: Icon(Icons.psychology, color: context.colors.primary),
        // Read value from provider state
        value: settings.showReasoning,
        onChanged: (value) async {
          // Update using notifier
          await ref.read(settingsProvider.notifier).updateShowReasoning(value);
          // No setState needed here
        },
        activeColor: context.colors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radius.medium),
        ),
      ),
    );
  }

  Widget _buildHapticFeedbackTile(
    BuildContext context,
    SettingsState settings,
  ) {
    // Add settings parameter
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.medium,
        vertical: context.spacing.small,
      ),
      child: SwitchListTile(
        title: Text('Haptic Feedback', style: context.typography.body1),
        secondary: Icon(Icons.vibration, color: context.colors.primary),
        // Read value from provider state
        value: settings.useHapticFeedback,
        onChanged: (value) async {
          // Update using notifier
          await ref
              .read(settingsProvider.notifier)
              .updateUseHapticFeedback(value);
          // No setState needed here
        },
        activeColor: context.colors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radius.medium),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String string) {
    return SectionHeader(
      string,
      textStyle: context.typography.h6,
      padding: EdgeInsets.symmetric(horizontal: context.spacing.medium),
    );
  }

  Widget _buildClearChatHistoryTile(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.medium,
        vertical: context.spacing.small,
      ),
      child: Card(
        elevation: 2,
        color: context.colors.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radius.medium),
        ),
        child: ListTile(
          leading: Icon(Icons.delete_forever, color: context.colors.error),
          title: Text(
            "Clear Chat History",
            style: context.typography.body1.copyWith(
              color: context.colors.error,
            ),
          ),
          subtitle: Text(
            "Delete all chat messages permanently",
            style: context.typography.caption.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          onTap: _clearChatHistory,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.radius.medium),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemPromptInput(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.medium,
        vertical: context.spacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("System Prompt", style: context.typography.body1),
          SizedBox(height: context.spacing.small),
          TextField(
            controller: _systemPromptController,
            decoration: InputDecoration(
              hintText: "Enter your custom system prompt",
              filled: true,
              fillColor: context.colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.radius.medium),
                borderSide: BorderSide(color: context.colors.outline),
              ),
            ),
            maxLines: 3,
            onChanged: (value) async {
              // Update using notifier
              await ref
                  .read(settingsProvider.notifier)
                  .updateSystemPrompt(value);
            },
          ),
          SizedBox(height: context.spacing.small),
          Text(
            "Customize the AI's personality and behavior.",
            style: context.typography.caption.copyWith(
              color: context.colors.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.medium,
        vertical: context.spacing.small,
      ),
      child: Card(
        elevation: 2,
        color: context.colors.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radius.medium),
        ),
        child: ListTile(
          title: Text("Vaarta v1.0.0", style: context.typography.body1),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: context.spacing.tiny),
              Text(
                "(of) making it all work.",
                style: context.typography.caption.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              SizedBox(height: context.spacing.tiny),
              Text(
                "© 2025 Sorbet Studio LLP",
                style: context.typography.caption.copyWith(
                  color: context.colors.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
          leading: Icon(Icons.info_outline, color: context.colors.primary),
        ),
      ),
    );
  }
}

Widget _buildToolSettingsSection(BuildContext context, WidgetRef ref) {
  final tools = ref.watch(toolListWithEnabledStateProvider);
  final toolEnabledStateNotifier = ref.read(toolEnabledStateProvider.notifier);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children:
        tools.map((tool) {
          final toolName = tool['name'] as String;
          final toolDescription = tool['description'] as String;
          final isEnabled = tool['isEnabled'] as bool;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.medium,
              vertical: context.spacing.small,
            ),
            child: SwitchListTile(
              title: Text(toolName, style: context.typography.body1),
              subtitle: Text(
                toolDescription,
                style: context.typography.caption,
              ),
              value: isEnabled,
              onChanged: (value) {
                toolEnabledStateNotifier.toggleTool(toolName, value);
              },
              activeColor: context.colors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.radius.medium),
              ),
            ),
          );
        }).toList(),
  );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const SectionHeader(this.title, {super.key, this.textStyle, this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: context.spacing.medium,
            vertical: context.spacing.small,
          ),
      child: Text(
        title,
        style:
            textStyle ??
            context.typography.h6.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
