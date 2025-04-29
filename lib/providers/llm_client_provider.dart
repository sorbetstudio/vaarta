// lib/providers/llm_client_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaarta/models/settings_state.dart';
import 'package:vaarta/services/llm_client.dart';
import 'package:vaarta/services/tool_registry.dart';
import 'package:vaarta/providers/settings_provider.dart';
import 'package:logging/logging.dart';

final _logger = Logger('LLMClientProvider');

/// Provider that creates and provides an instance of [LLMClient].
///
/// It depends on the [settingsProvider] and automatically updates the
/// [LLMClient] instance whenever the settings change.
///
/// Throws an error if the API key is missing in the settings.
final llmClientProvider = Provider<LLMClient>((ref) {
  final settings = ref.watch(settingsProvider);

  _logger.info('Rebuilding LLMClient due to settings change.');
  _logger.info('API Key Present: ${settings.apiKey.isNotEmpty}');
  _logger.info('Model: ${settings.selectedModel}');

  // Ensure API key is available before creating the client
  if (settings.apiKey.isEmpty) {
    _logger.warning('API Key is missing. LLMClient cannot be initialized.');
    // You might want to handle this more gracefully in the UI,
    // perhaps by showing a message or disabling chat functionality.
    throw Exception('API Key is missing. Please configure it in Settings.');
  }

  final openRouterConfig = OpenRouterConfig(
    temperature: settings.temperature,
    maxTokens: settings.maxTokens,
    topP: settings.topP,
    presencePenalty: 0.0, // Default values from original ChatScreen init
    frequencyPenalty: 0.0, // Default values from original ChatScreen init
    reasoning:
        settings.showReasoning ? {"exclude": false, "max_tokens": 400} : null,
    // Add other OpenRouter specific settings from SettingsState if needed
  );

  final llmConfig = LLMConfig(
    apiKey: settings.apiKey,
    model: settings.selectedModel,
    provider: LLMProvider.openRouter, // Assuming OpenRouter for now
    openRouterConfig: openRouterConfig,
    temperature: settings.temperature, // Pass general temp/maxTokens as well
    maxTokens: settings.maxTokens,
  );

  // Create tool registry and register tools
  final toolRegistry =
      ToolRegistry()
        ..registerTool(ToastToolImpl())
        ..registerTool(CalculatorTool())
        ..registerTool(SearchTool())
        ..registerTool(FetchTool());

  return LLMClient(config: llmConfig, toolRegistry: toolRegistry);
});
