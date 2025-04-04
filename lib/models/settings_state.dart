// lib/models/settings_state.dart
import 'package:flutter/foundation.dart';

@immutable
class SettingsState {
  final String apiKey;
  final String selectedModel;
  final bool useHapticFeedback;
  final bool showReasoning;
  final String systemPrompt;
  final double temperature;
  final int maxTokens;
  final double topP;
  final bool isLoading;
  final String? errorMessage;

  const SettingsState({
    this.apiKey = '',
    this.selectedModel =
        "cognitivecomputations/dolphin3.0-mistral-24b:free", // Default from ChatScreen
    this.useHapticFeedback = true,
    this.showReasoning = true,
    this.systemPrompt = '', // Default is handled in ChatScreen logic for now
    this.temperature = 0.7,
    this.maxTokens =
        4096, // Default from ChatScreen (was 1000, but init uses 4096)
    this.topP = 0.9,
    this.isLoading = true,
    this.errorMessage,
  });

  // Default system prompt constant
  static const String defaultSystemPrompt =
      '''You are Vaarta AI, a helpful assistant. Your responses should be concise, avoiding unnecessary details. Your personality is lovable, warm, and inviting.''';

  // Effective system prompt getter
  String get effectiveSystemPrompt =>
      systemPrompt.isEmpty ? defaultSystemPrompt : systemPrompt;

  SettingsState copyWith({
    String? apiKey,
    String? selectedModel,
    bool? useHapticFeedback,
    bool? showReasoning,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    double? topP,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SettingsState(
      apiKey: apiKey ?? this.apiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      useHapticFeedback: useHapticFeedback ?? this.useHapticFeedback,
      showReasoning: showReasoning ?? this.showReasoning,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      topP: topP ?? this.topP,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}
