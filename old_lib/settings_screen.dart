import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _darkMode = true;
  String _selectedModel = "cognitivecomputations/dolphin3.0-mistral-24b:free"; // Set default value directly
  bool _hapticFeedback = true;
  bool _showReasoning = true;
  final TextEditingController _apiKeyController = TextEditingController();

  final Map<String, String> models = {
    "cognitivecomputations/dolphin3.0-mistral-24b:free": "Dolphin Mistral 24B",
    "cognitivecomputations/dolphin3.0-r1-mistral-24b:free": "Dolphin Mistral R1 24B",
    "openai/gpt-4o-mini": "GPT 4o Mini",
    "deepseek/deepseek-r1": "Deepseek R1"
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
      _darkMode = prefs.getBool('darkMode') ?? true;

      // Get the stored model or use default if not found
      String storedModel = prefs.getString('selectedModel') ?? "cognitivecomputations/dolphin3.0-mistral-24b:free";

      // Verify the stored model exists in our models map
      if (models.containsKey(storedModel)) {
        _selectedModel = storedModel;
      } else {
        // If not, use the first model in the map
        _selectedModel = models.keys.first;
      }
      _showReasoning = prefs.getBool('showReasoning') ?? true;
      _hapticFeedback = prefs.getBool('hapticFeedback') ?? true;
      _apiKeyController.text = prefs.getString('apiKey') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setString('selectedModel', _selectedModel);
    await prefs.setBool('hapticFeedback', _hapticFeedback);
    await prefs.setBool('showReasoning', _showReasoning);
    await prefs.setString('apiKey', _apiKeyController.text);

    // Check if the widget is still mounted before using BuildContext
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        duration: Duration(seconds: 1),
        // make the snackbar float
        behavior: SnackBarBehavior.floating,
        // make the snackbar persistent
        dismissDirection: DismissDirection.none,
        // make the snackbar dismissable
        elevation: 10,
      ),
    );

  }

  @override
  void dispose() {
    _animationController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              _saveSettings();
              Navigator.of(context).pop();
            },
            tooltip: 'Save settings',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _animation,
        child: ListView(
          children: [
            _buildSectionHeader('Appearance', theme),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: _darkMode,
              onChanged: (value) {
                setState(() {
                  _darkMode = value;
                });
              },
              secondary: Icon(
                _darkMode ? Icons.dark_mode : Icons.light_mode,
                color: theme.colorScheme.primary,
              ),
            ),
            const Divider(),
            _buildSectionHeader('AI Model', theme),
            _buildModelSelector(theme, isDark),
            const Divider(),
            _buildSectionHeader('Reasoning Mode', theme),
            SwitchListTile(
              title: const Text('Reasoning Mode'),
              value: _showReasoning,
              onChanged: (value) {
                setState(() {
                  _showReasoning = value;
                });
              },
              secondary: Icon(
                Icons.psychology,
                color: theme.colorScheme.primary,
              ),
            ),
            const Divider(),
            _buildSectionHeader('Behavior', theme),
            SwitchListTile(
              title: const Text('Haptic Feedback'),
              value: _hapticFeedback,
              onChanged: (value) {
                setState(() {
                  _hapticFeedback = value;
                });
              },
              secondary: Icon(
                Icons.vibration,
                color: theme.colorScheme.primary,
              ),
            ),
            const Divider(),
            _buildSectionHeader('API Settings', theme),
            _buildApiKeyInput(theme, isDark),
            const Divider(),
            _buildSectionHeader('About', theme),
            _buildAboutSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style:TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildModelSelector(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select AI Model"),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedModel,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: models.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                //validator
                if (newValue != null) {
                  setState(() {
                    _selectedModel = newValue;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyInput(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("API Key"),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              hintText: "Enter your API key",
              filled: true,
              fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          Text(
            "Your API key is stored only on this device",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(ThemeData theme) {
    return ListTile(
      title: const Text("Vaarta v1.0.0"),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            "Yet another chat app.",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "© 2025 Sorbet Studio LLP",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
      leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
    );
  }
}