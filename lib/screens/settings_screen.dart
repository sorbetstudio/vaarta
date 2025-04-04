// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaarta/providers/theme_notifier.dart';
import 'package:vaarta/theme/theme_config.dart';
import 'package:vaarta/theme/theme_extensions.dart';
import 'package:vaarta/widgets/shared/section_header.dart';
import '../services/database_helper.dart';
import '../services/database/message_repository.dart';

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
    final messageRepo = MessageRepository(DatabaseHelper.instance);
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
      await messageRepo.clearAllMessages();
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
    final currentTheme = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _animation,
        child: ListView(
          padding: EdgeInsets.all(context.spacing.small),
          children: [
            _buildSectionHeader(context, 'Appearance'),
            _buildThemeSelectorTile(context, currentTheme),

            _buildDivider(context),

            _buildSectionHeader(context, 'AI Model'),
            _buildModelSelector(context),
            _buildTemperatureSlider(context),
            _buildMaxTokensSlider(context),

            _buildDivider(context),

            _buildSectionHeader(context, 'AI Model'),
            _buildReasoningModeTile(context),

            _buildDivider(context),

            _buildSectionHeader(context, 'Behavior'),
            _buildHapticFeedbackTile(context),

            _buildDivider(context),

            _buildSectionHeader(context, 'API Settings'),
            _buildApiKeyInput(context),

            _buildDivider(context),

            _buildSectionHeader(context, 'Data'),
            _buildClearChatHistoryTile(context),

            _buildDivider(context),

            _buildSectionHeader(context, 'Advanced'),
            _buildSystemPromptInput(context),

            _buildDivider(context),

            _buildSectionHeader(context, 'About'),
            _buildAboutSection(context),
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

  Widget _buildThemeSelectorTile(
    BuildContext context,
    AsyncValue<AppTheme> currentTheme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.medium,
        vertical: context.spacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Theme Mode", style: context.typography.body1),
          const SizedBox(height: 8),
          Card(
            color: context.colors.surfaceVariant,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.radius.medium),
            ),
            child: Column(
              children:
                  AppTheme.values.map((theme) {
                    final isSelected = currentTheme.valueOrNull == theme;
                    return ListTile(
                      leading: Icon(
                        theme.icon,
                        color:
                            isSelected
                                ? context.colors.primary
                                : context.colors.onSurface.withAlpha(150),
                      ),
                      title: Text(
                        theme.label,
                        style: context.typography.body1.copyWith(
                          color: context.colors.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing:
                          isSelected
                              ? Icon(
                                Icons.check_circle,
                                color: context.colors.primary,
                              )
                              : null,
                      onTap: () {
                        ref
                            .read(themeNotifierProvider.notifier)
                            .setTheme(theme);
                      },
                      tileColor:
                          isSelected
                              ? context.colors.primary.withAlpha(25)
                              : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.radius.small,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasoningModeTile(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.medium,
        vertical: context.spacing.small,
      ),
      child: SwitchListTile(
        title: Text('Reasoning Mode', style: context.typography.body1),
        secondary: Icon(Icons.psychology, color: context.colors.primary),
        value: _showReasoning,
        onChanged: (value) async {
          setState(() => _showReasoning = value);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('showReasoning', _showReasoning);
        },
        activeColor: context.colors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radius.medium),
        ),
      ),
    );
  }

  Widget _buildHapticFeedbackTile(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.medium,
        vertical: context.spacing.small,
      ),
      child: SwitchListTile(
        title: Text('Haptic Feedback', style: context.typography.body1),
        secondary: Icon(Icons.vibration, color: context.colors.primary),
        value: _hapticFeedback,
        onChanged: (value) async {
          setState(() => _hapticFeedback = value);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hapticFeedback', _hapticFeedback);
        },
        activeColor: context.colors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radius.medium),
        ),
      ),
    );
  }

  Widget _buildModelSelector(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.medium,
        vertical: context.spacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Select AI Model", style: context.typography.body1),
          SizedBox(height: context.spacing.small),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.radius.medium),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedModel,
                  isExpanded: true,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: context.colors.primary,
                  ),
                  items:
                      models.entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(
                                entry.value,
                                style: context.typography.body1,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (newValue) async {
                    if (newValue != null) {
                      setState(() => _selectedModel = newValue);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('selectedModel', _selectedModel);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
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

  Widget _buildTemperatureSlider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.medium,
        vertical: context.spacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Temperature", style: context.typography.body1),
          Slider(
            value: _temperature,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            label: _temperature.toStringAsFixed(1),
            activeColor: context.colors.primary,
            inactiveColor: context.colors.surfaceVariant,
            onChanged: (value) async {
              setState(() => _temperature = value);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('temperature', _temperature);
            },
          ),
          Text(
            "Controls randomness: 0.0 is deterministic, 2.0 is max randomness.",
            style: context.typography.caption.copyWith(
              color: context.colors.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaxTokensSlider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.medium,
        vertical: context.spacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Max Tokens", style: context.typography.body1),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _maxTokens.toDouble(),
                  min: 50.0,
                  max: 4096,
                  divisions: 809,
                  label: _maxTokens.toString(),
                  activeColor: context.colors.primary,
                  inactiveColor: context.colors.surfaceVariant,
                  onChanged: (value) async {
                    setState(() {
                      _maxTokens = value.toInt();
                      _maxTokensController.text = _maxTokens.toString();
                    });
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('maxTokens', _maxTokens);
                  },
                ),
              ),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _maxTokensController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) async {
                    final parsedValue = int.tryParse(value) ?? 50;
                    final clampedValue = parsedValue.clamp(50, 4096);
                    setState(() => _maxTokens = clampedValue);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('maxTokens', _maxTokens);
                  },
                ),
              ),
            ],
          ),
          Text(
            "Maximum number of tokens in the AI response.",
            style: context.typography.caption.copyWith(
              color: context.colors.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyInput(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.medium,
        vertical: context.spacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("API Key", style: context.typography.body1),
          SizedBox(height: context.spacing.small),
          TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              hintText: "Enter your API key",
              filled: true,
              fillColor: context.colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.radius.medium),
                borderSide: BorderSide(color: context.colors.outline),
              ),
              prefixIcon: Icon(Icons.key, color: context.colors.primary),
            ),
            obscureText: true,
            onChanged: (value) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('apiKey', value);
            },
          ),
          SizedBox(height: context.spacing.small),
          Text(
            "Your API key is stored only on this device",
            style: context.typography.caption.copyWith(
              color: context.colors.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
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
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('systemPrompt', value);
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
