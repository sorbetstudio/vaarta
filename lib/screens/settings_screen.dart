import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart'; // Import provider
import '../services/database_helper.dart';
import '../main.dart'; // Import main.dart to access AppState
import 'package:flutter/services.dart';


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
  final TextEditingController _systemPromptController = TextEditingController(); // Add system prompt controller
    final TextEditingController _maxTokensController =
      TextEditingController(); // Add maxTokens controller

  double _temperature = 0.7; // Default temperature value
  int _maxTokens = 256; // Default max tokens value


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
      _systemPromptController.text = prefs.getString('systemPrompt') ?? ''; // Load system prompt
      _temperature = prefs.getDouble('temperature') ?? 0.7; // Load temperature, default 0.7
      _maxTokens = prefs.getInt('maxTokens') ?? 256; // Load maxTokens, default 256
      _maxTokensController.text = '$_maxTokens';
    });
  }


  Future<void> _clearChatHistory() async {
    final dbHelper = DatabaseHelper.instance;
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Clear Chat History?"),
          content: const Text(
              "Are you sure you want to clear all chat history? This action cannot be undone."),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(false); // Dismiss dialog, return false
              },
            ),
            TextButton(
              child: const Text("Clear", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true); // Dismiss dialog, return true
              },
            ),
          ],
        );
      },
    ) ?? false; // Default to false if dialog is dismissed without selection

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
    _systemPromptController.dispose(); // Dispose system prompt controller
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
            SectionHeader('Appearance', theme),
            _buildDarkModeTile(theme),
            const Divider(height: 2, thickness: 0),
            SectionHeader('AI Model', theme),
            _buildModelSelector(theme, isDark),
            _buildTemperatureSlider(theme, isDark),
            _buildMaxTokensSlider(theme, isDark),
            const Divider(height: 2, thickness: 0),
            SectionHeader('Reasoning Mode', theme),
            _buildReasoningModeTile(theme),
            const Divider( height: 2, thickness: 0),
            SectionHeader('Behavior', theme),
            _buildHapticFeedbackTile(theme),
            const Divider(height: 2, thickness: 0),
            SectionHeader('API Settings', theme),
            _buildApiKeyInput(theme, isDark),
            const Divider(height: 2, thickness: 0),
            SectionHeader('Data', theme),
            _buildClearChatHistoryTile(theme),
            const Divider(height: 2, thickness: 0),
            SectionHeader('Advanced', theme),
            _buildSystemPromptInput(theme, isDark),
            const Divider(height: 2, thickness: 0),
            SectionHeader('About', theme),
            _buildAboutSection(theme),
          ],
        ),
      ),
    );
  }

   PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Settings',
        style: TextStyle(
          fontFamily: 'Arial',
          fontWeight: FontWeight.bold,
          color: Colors.white, // White text color
        ),
      ),
      backgroundColor: Colors.black, // Black background color
      elevation: 0,
      // I don't need actions any more
      // actions: [
      //   IconButton(
      //     icon: const Icon(Icons.save),
      //     onPressed: () {
      //       _saveSettings();
      //       Navigator.of(context).pop();
      //     },
      //     tooltip: 'Save settings',
      //     color: Colors.white, // White icon color
      //   ),
      // ],
    );
  }



 Widget _buildDarkModeTile(ThemeData theme) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),// Added Vertical padding
    child: Row(
      children: [
        Icon(
          _darkMode ? Icons.dark_mode : Icons.light_mode,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 16),
        const Expanded(child: Text('Dark Mode')),
        SkeuomorphicToggle(
          value: _darkMode,
          onChanged: (value) async {
            setState(() {
              _darkMode = value;
            });
            // Access the AppState using Provider and update the themeMode.
            // This is the important change.
            Provider.of<AppState>(context, listen: false).toggleTheme();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('darkMode', _darkMode);

          },
        ),
      ],
    ),
  );
}

  Widget _buildReasoningModeTile(ThemeData theme) {
   return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),// Added Vertical padding
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 16),
          const Expanded(child: Text('Reasoning Mode')),
          SkeuomorphicToggle(
            value: _showReasoning,
            onChanged: (value) async {
              setState(() {
                _showReasoning = value;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('showReasoning', _showReasoning);

            },
          ),
        ],
      ),
    );
  }

    Widget _buildHapticFeedbackTile(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Added Vertical padding
      child: Row(
        children: [
          Icon(
            Icons.vibration,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 16),
          const Expanded(child: Text('Haptic Feedback')),
          SkeuomorphicToggle(
            value: _hapticFeedback,
            onChanged: (value) async {
              setState(() {
                _hapticFeedback = value;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hapticFeedback', _hapticFeedback);
            },
          ),
        ],
      ),
    );
  }

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
           items: models.entries.map((entry) {
             return DropdownMenuItem<String>(
               value: entry.key,
               child: Text(entry.value),
             );
           }).toList(),
           onChanged: (String? newValue) async {
             if (newValue != null) {
               setState(() {
                 _selectedModel = newValue;
               });
               final prefs = await SharedPreferences.getInstance();
               await prefs.setString('selectedModel', _selectedModel);
             }
           },
         ),
       ],
     ),
   );
 }

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
           max: 2.0, // Changed to 2.0
           divisions: 20, // Increased divisions for finer control
           label: _temperature.toStringAsFixed(1),
           activeColor: theme.colorScheme.primary,
           inactiveColor: theme.colorScheme.secondaryContainer,
           onChanged: (value) async {
             setState(() {
               _temperature = value;
             });
             final prefs = await SharedPreferences.getInstance();
             await prefs.setDouble('temperature', _temperature);

           },
         ),
         Text(
           "Controls randomness: 0.0 is deterministic, 2.0 is max randomness.",
           style: TextStyle(
             color: theme.colorScheme.onSurface.withOpacity(0.6),
             fontSize: 12,
           ),
         ),
       ],
     ),
   );
 }


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
                       _maxTokensController.text =
                        '$_maxTokens'; // Update text field when slider changes
                    });
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('maxTokens', _maxTokens); // Save immediately
                  },
                ),
              ),
              SizedBox(
                width: 60,
                child: TextField(
                    controller: _maxTokensController, // Use controller
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                    hintText: "Tokens",
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                    ),
                    onChanged: (value) async {
                    int? parsedValue = int.tryParse(value);
                      if (parsedValue != null) {
                        if (parsedValue < 50) {
                          parsedValue = 50;
                        } else if (parsedValue > 4096) {
                          parsedValue = 4096;
                        }
                        setState(() {
                          _maxTokens = parsedValue!;
                        });
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('maxTokens', _maxTokens); // Save immediately

                      }
                    },
                ),
              ),
            ],
          ),
          Text(
            "Maximum number of tokens in the AI response.",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
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
          Text("API Key", style: TextStyle(color: theme.colorScheme.onSurface),),
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
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearChatHistoryTile(ThemeData theme) {
   return Padding(  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
      leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
      title: Text("Clear Chat History", style: TextStyle(color: Colors.red)), // remove the const
      subtitle: Text("Delete all chat messages permanently", style: TextStyle(color: theme.colorScheme.onSurface),), //Added
      onTap: _clearChatHistory,
     ),
   );
  }

  Widget _buildSystemPromptInput(ThemeData theme, bool isDark) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("System Prompt", style: TextStyle(color: theme.colorScheme.onSurface),),
        const SizedBox(height: 8),
        SkeuomorphicTextField(
          controller: _systemPromptController,
          hintText: "Enter your custom system prompt",
          obscureText: false,
          maxLines: 3, // Allow multiple lines for system prompt,
          onChanged: (value) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('systemPrompt', value);
          },
        ),
        const SizedBox(height: 8),
        Text(
          "Customize the AI's personality and behavior.",
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}


  Widget _buildAboutSection(ThemeData theme) {
   return Padding(
     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),// Added Vertical padding
     child: Container(
      // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Add consistent padding
          child: ListTile(
        title: const Text("Vaarta v1.0.0"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "Yet another chat app.",
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "© 2025 Sorbet Studio LLP",
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
      ),
     ),
   );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const SectionHeader(this.title, this.theme, {super.key});

  @override
  Widget build(BuildContext context) {
   return Padding(
     padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), // Added vertical padding of 16
     child: Text(
       title,
       style: TextStyle(
         fontSize: 18,
         fontWeight: FontWeight.bold,
         color: theme.colorScheme.primary,
       ),
     ),
   );
  }
}


class SkeuomorphicToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;

  const SkeuomorphicToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 60.0,
    this.height = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark ? const Color(0xFF444444) : Colors.grey.shade300;
    final thumbColor = isDark ? const Color(0xFFDDDDDD) : Colors.grey.shade100; // Lighter thumb for dark mode
        final shadowColor = isDark ? Colors.black87 : Colors.grey.shade400;


    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          color: value ? Colors.blue.shade300 : trackColor,
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade400, // Darker border for dark mode
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: AnimatedAlign(
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Container(
              width: height - 4,
              height: height - 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: thumbColor,
                border: Border.all(
                  color:  isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SkeuomorphicDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const SkeuomorphicDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF444444) : Colors.grey.shade200;
    final textColor = isDark ? Colors.grey[200] : Colors.grey[700];
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade400;
    final shadowColor = isDark ? Colors.black87 : Colors.grey.shade400;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
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
        dropdownColor: backgroundColor, // Set dropdown menu background color
        items: items,
        onChanged: onChanged,
        style: TextStyle( // Set text style
          color: textColor,
          fontFamily: 'Arial',
        ),
      ),
    );
  }
}

class SkeuomorphicTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final int? maxLines; // Add maxLines parameter
    final ValueChanged<String>? onChanged; // Add the onChanged parameter


  const SkeuomorphicTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.maxLines = 1, // Default maxLines to 1
    this.onChanged, // Include it in the constructor

  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF444444) : Colors.grey.shade200;
    final textColor = isDark ? Colors.grey[200] : Colors.grey[700];
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade400;
    final shadowColor = isDark ? Colors.black87 : Colors.grey.shade400;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor, // Inset shadow
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ]
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        maxLines: maxLines, // Set maxLines from parameter
        style: TextStyle(color: textColor, fontFamily: 'Arial'), // Set text style,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: textColor != null ? textColor.withOpacity(0.6) : Colors.grey.withOpacity(0.6)), // Lighter hint text with null check
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none, // Remove extra border
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}