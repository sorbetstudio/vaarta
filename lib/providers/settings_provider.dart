// lib/providers/settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaarta/models/settings_state.dart';
import 'package:logging/logging.dart';

final _logger = Logger('SettingsNotifier');

/// Notifier for managing application settings.
///
/// Loads settings from SharedPreferences on initialization and provides
/// methods to update and persist individual settings.
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    loadSettings();
  }

  /// Loads settings from SharedPreferences.
  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      state = state.copyWith(
        apiKey: prefs.getString('apiKey') ?? '',
        selectedModel: prefs.getString('selectedModel') ?? state.selectedModel,
        useHapticFeedback:
            prefs.getBool('hapticFeedback') ?? state.useHapticFeedback,
        showReasoning: prefs.getBool('showReasoning') ?? state.showReasoning,
        systemPrompt:
            prefs.getString('systemPrompt') ?? '', // Keep empty if not set
        temperature: prefs.getDouble('temperature') ?? state.temperature,
        maxTokens: prefs.getInt('maxTokens') ?? state.maxTokens,
        topP: prefs.getDouble('topP') ?? state.topP,
        isLoading: false,
      );
      _logger.info('Settings loaded successfully.');
      _logger.info('API Key loaded: ${state.apiKey.isNotEmpty ? "Yes" : "No"}');
      _logger.info('Model: ${state.selectedModel}');
      _logger.info('System Prompt: ${state.systemPrompt}');
    } catch (e) {
      _logger.severe('Failed to load settings: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load settings: $e',
      );
    }
  }

  // --- Update methods for individual settings ---

  Future<void> updateApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiKey', apiKey);
    state = state.copyWith(apiKey: apiKey);
    _logger.info('API Key updated.');
  }

  Future<void> updateSelectedModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedModel', model);
    state = state.copyWith(selectedModel: model);
    _logger.info('Selected model updated: $model');
  }

  Future<void> updateTemperature(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('temperature', value);
    state = state.copyWith(temperature: value);
    _logger.info('Temperature updated: $value');
  }

  Future<void> updateMaxTokens(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxTokens', value);
    state = state.copyWith(maxTokens: value);
    _logger.info('Max tokens updated: $value');
  }

  Future<void> updateTopP(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('topP', value);
    state = state.copyWith(topP: value);
    _logger.info('Top P updated: $value');
  }

  Future<void> updateUseHapticFeedback(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hapticFeedback', value);
    state = state.copyWith(useHapticFeedback: value);
    _logger.info('Haptic feedback updated: $value');
  }

  Future<void> updateShowReasoning(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showReasoning', value);
    state = state.copyWith(showReasoning: value);
    _logger.info('Show reasoning updated: $value');
  }

  Future<void> updateSystemPrompt(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('systemPrompt', prompt);
    state = state.copyWith(systemPrompt: prompt);
    _logger.info('System prompt updated.');
  }
}

/// Provider for accessing the SettingsNotifier.
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier();
  },
);
