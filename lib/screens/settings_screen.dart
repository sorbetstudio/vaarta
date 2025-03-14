import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaarta/providers/theme_notifier.dart';
import '../services/database_helper.dart';
import 'package:vaarta/widgets/sk_ui.dart'; // Import reusable widgets

/// Displays a settings screen for configuring app preferences.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _darkMode = true;
  String _selectedModel = "cognitivecomputations/dolphin3.0-mistral-24b:free";
  bool _hapticFeedback = true;
  bool _showReasoning = true;
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();
  final TextEditingController _maxTokensController = TextEditingController();

  double _temperature = 0.7;
  int _maxTokens = 256;

  /// Available AI models with their display names.
  final Map<String, String> models = {
    "cognitivecomputations/dolphin3.0-mistral-24b:free": "Dolphin Mistral 24B",
    "cognitivecomputations/dolphin3.0-r1-mistral-24b:free": "Dolphin Mistral R1 24B",
    "openai/gpt-4o-mini": "GPT 4o Mini",
    "deepseek/deepseek-r1": "Deepseek R1",
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

  /// Loads saved settings from SharedPreferences.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? true;
      final storedModel = prefs.getString('selectedModel') ?? _selectedModel;
      _selectedModel = models.containsKey(storedModel) ? storedModel : models.keys.first;
      _showReasoning = prefs.getBool('showReasoning') ?? true;
      _hapticFeedback = prefs.getBool('hapticFeedback') ?? true;
      _apiKeyController.text = prefs.getString('apiKey') ?? '';
      _systemPromptController.text = prefs.getString('systemPrompt') ?? '';
      _temperature = prefs.getDouble('temperature') ?? 0.7;
      _maxTokens = prefs.getInt('maxTokens') ?? 256;
      _maxTokensController.text = _maxTokens.toString();
    });
  }

  /// Prompts the user to confirm clearing chat history and performs the action if confirmed.
  Future<void> _clearChatHistory() async {
    final dbHelper = DatabaseHelper.instance;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Chat History?"),
        content: const Text("Are you sure you want to clear all chat history? This action cannot be undone."),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text("Clear", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ??
        false;

    if (confirmed) {
      await dbHelper.clearAllMessages();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat history cleared'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          elevation: 10,
        ),
      );
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _animation,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const SectionHeader('Appearance'),
            _buildDarkModeTile(theme),
            const Divider(height: 2, thickness: 0),
            const SectionHeader('AI Model'),
            _buildModelSelector(theme, isDark),
            _buildTemperatureSlider(theme, isDark),
            _buildMaxTokensSlider(theme, isDark),
            const Divider(height: 2, thickness: 0),
            const SectionHeader('Reasoning Mode'),
            _buildReasoningModeTile(theme),
            const Divider(height: 2, thickness: 0),
            const SectionHeader('Behavior'),
            _buildHapticFeedbackTile(theme),
            const Divider(height: 2, thickness: 0),
            const SectionHeader('API Settings'),
            _buildApiKeyInput(theme, isDark),
            const Divider(height: 2, thickness: 0),
            const SectionHeader('Data'),
            _buildClearChatHistoryTile(theme),
            const Divider(height: 2, thickness: 0),
            const SectionHeader('Advanced'),
            _buildSystemPromptInput(theme, isDark),
            const Divider(height: 2, thickness: 0),
            const SectionHeader('About'),
            _buildAboutSection(theme),
          ],
        ),
      ),
    );
  }

  /// Builds the app bar with a fixed black background and white text.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Settings',
        style: TextStyle(fontFamily: 'Arial', fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: Colors.black,
      elevation: 0,
    );
  }

  /// Builds the dark mode toggle tile.
  Widget _buildDarkModeTile(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(_darkMode ? Icons.dark_mode : Icons.light_mode, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          const Expanded(child: Text('Dark Mode')),
          SkeuomorphicToggle(
            value: _darkMode,
            onChanged: (value) async {
              setState(() => _darkMode = value);
              ref.read(themeNotifierProvider.notifier).toggleTheme();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('darkMode', _darkMode);
            },
          ),
        ],
      ),
    );
  }

  /// Builds the reasoning mode toggle tile.
  Widget _buildReasoningModeTile(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.psychology, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          const Expanded(child: Text('Reasoning Mode')),
          SkeuomorphicToggle(
            value: _showReasoning,
            onChanged: (value) async {
              setState(() => _showReasoning = value);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('showReasoning', _showReasoning);
            },
          ),
        ],
      ),
    );
  }

  /// Builds the haptic feedback toggle tile.
  Widget _buildHapticFeedbackTile(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.vibration, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          const Expanded(child: Text('Haptic Feedback')),
          SkeuomorphicToggle(
            value: _hapticFeedback,
            onChanged: (value) async {
              setState(() => _hapticFeedback = value);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hapticFeedback', _hapticFeedback);
            },
          ),
        ],
      ),
    );
  }

  /// Builds the AI model selector dropdown.
  Widget _buildModelSelector(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Select AI Model", style: TextStyle(color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          SkeuomorphicDropdown<String>(
            value: _selectedModel,
            items: models.entries
                .map((entry) => DropdownMenuItem<String>(value: entry.key, child: Text(entry.value)))
                .toList(),
            onChanged: (newValue) async {
              if (newValue != null) {
                setState(() => _selectedModel = newValue);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('selectedModel', _selectedModel);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Builds the temperature slider for controlling AI randomness.
  Widget _buildTemperatureSlider(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Temperature", style: TextStyle(color: theme.colorScheme.onSurface)),
          Slider(
            value: _temperature,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            label: _temperature.toStringAsFixed(1),
            activeColor: theme.colorScheme.primary,
            inactiveColor: theme.colorScheme.secondaryContainer,
            onChanged: (value) async {
              setState(() => _temperature = value);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('temperature', _temperature);
            },
          ),
          Text(
            "Controls randomness: 0.0 is deterministic, 2.0 is max randomness.",
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Builds the max tokens slider with a text field for precise input.
  Widget _buildMaxTokensSlider(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Max Tokens", style: TextStyle(color: theme.colorScheme.onSurface)),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _maxTokens.toDouble(),
                  min: 50.0,
                  max: 4096,
                  divisions: 809,
                  label: _maxTokens.toString(),
                  activeColor: theme.colorScheme.primary,
                  inactiveColor: theme.colorScheme.secondaryContainer,
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
                width: 60,
                child: SkeuomorphicTextField(
                  controller: _maxTokensController,
                  hintText: "Tokens",
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
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Builds the API key input field.
  Widget _buildApiKeyInput(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("API Key", style: TextStyle(color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          SkeuomorphicTextField(
            controller: _apiKeyController,
            hintText: "Enter your API key",
            obscureText: true,
            onChanged: (value) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('apiKey', value);
            },
          ),
          const SizedBox(height: 8),
          Text(
            "Your API key is stored only on this device",
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Builds the clear chat history tile with a confirmation dialog trigger.
  Widget _buildClearChatHistoryTile(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
        title: Text("Clear Chat History", style: TextStyle(color: theme.colorScheme.error)),
        subtitle: Text("Delete all chat messages permanently",
            style: TextStyle(color: theme.colorScheme.onSurface)),
        onTap: _clearChatHistory,
      ),
    );
  }

  /// Builds the system prompt input field for customizing AI behavior.
  Widget _buildSystemPromptInput(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("System Prompt", style: TextStyle(color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          SkeuomorphicTextField(
            controller: _systemPromptController,
            hintText: "Enter your custom system prompt",
            maxLines: 3,
            onChanged: (value) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('systemPrompt', value);
            },
          ),
          const SizedBox(height: 8),
          Text(
            "Customize the AI's personality and behavior.",
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Builds the about section with app information.
  Widget _buildAboutSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: const Text("Vaarta v1.0.0"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Yet another chat app.",
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 4),
            Text("© 2025 Sorbet Studio LLP",
                style:
                TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
          ],
        ),
        leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
      ),
    );
  }
}