// lib/services/llm_client.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:vaarta/models/models.dart';


final _logger = Logger('LLMClient');

enum LLMProvider { openRouter, anthropic, mistral, gemini }

class OpenRouterConfig {
  final double? temperature;
  final int? maxTokens;
  final double? topP;
  final double? topK;
  final double? presencePenalty;
  final double? frequencyPenalty;
  final Map<String, dynamic>? logitBias;
  final String? stop;
  final List<String>? stopSequences;
  final Map<String, dynamic>? responseFormat;
  final Map<String, dynamic>? tools;
  final String? toolChoice;
  final bool? transformationsConfigJsonResponse;
  final Map<String, dynamic>? reasoning;
  final Map<String, dynamic>? routes;
  final bool? promptTruncation;
  final Map<String, dynamic>? functions;
  final String? functionCall;
  final bool? stream; // Add stream config
  final String? httpReferer;
  final String? xTitle;

  OpenRouterConfig({
    this.temperature,
    this.maxTokens,
    this.topP,
    this.topK,
    this.presencePenalty,
    this.frequencyPenalty,
    this.logitBias,
    this.stop,
    this.stopSequences,
    this.responseFormat,
    this.tools,
    this.toolChoice,
    this.transformationsConfigJsonResponse,
    this.reasoning,
    this.routes,
    this.promptTruncation,
    this.functions,
    this.functionCall,
    this.stream = true, // Default stream to true
    this.httpReferer,
    this.xTitle,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (temperature != null) json['temperature'] = temperature;
    if (maxTokens != null) json['max_tokens'] = maxTokens;
    if (topP != null) json['top_p'] = topP;
    if (topK != null) json['top_k'] = topK;
    if (presencePenalty != null) json['presence_penalty'] = presencePenalty;
    if (frequencyPenalty != null) json['frequency_penalty'] = frequencyPenalty;
    if (logitBias != null) json['logit_bias'] = logitBias;
    if (stop != null) json['stop'] = stop;
    if (stopSequences != null) json['stop_sequences'] = stopSequences;
    if (responseFormat != null) json['response_format'] = responseFormat;
    if (tools != null) json['tools'] = tools;
    if (toolChoice != null) {
      json['tool_choice'] = toolChoice;
    }
    if (transformationsConfigJsonResponse != null) {
      json['transformations.config.json_response'] =
          transformationsConfigJsonResponse;
    }
    if (reasoning != null) json['reasoning'] = reasoning;
    if (routes != null) json['routes'] = routes;
    if (promptTruncation != null) json['prompt_truncation'] = promptTruncation;
    if (functions != null) json['functions'] = functions;
    if (functionCall != null) json['function_call'] = functionCall;
    if (stream != null) json['stream'] = stream; // Include stream in json

    return json;
  }
}

class LLMConfig {
  final String apiKey;
  final String model;
  final LLMProvider? provider;
  final Map<String, dynamic>? extraParams;
  final OpenRouterConfig? openRouterConfig;
  final double? temperature; // Add temperature
  final int? maxTokens; // Add maxTokens


  LLMConfig({
    required this.apiKey,
    required this.model,
    this.provider,
    this.extraParams,
    this.openRouterConfig,
    this.temperature, // Add to constructor
    this.maxTokens, // Add to constructor
  });
}

class LLMResponse {
  final String content;
  final Map<String, dynamic>? metadata;

  LLMResponse({required this.content, this.metadata});
}

typedef ChunkCallback = void Function(String chunk);

class LLMClient {
  final LLMConfig config;

  LLMClient({required this.config});

  String get _baseUrl {
    switch (config.provider) {
      case LLMProvider.openRouter:
        return 'https://openrouter.ai/api/v1';
      case LLMProvider.anthropic:
        return 'https://api.anthropic.com/v1';
      case LLMProvider.mistral:
        return 'https://api.mistral.ai/v1';
      case LLMProvider.gemini:
        return 'https://generativelanguage.googleapis.com/v1';
      case null:
      // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Map<String, String> _getHeaders() {
    final baseHeaders = {'Content-Type': 'application/json'};
    final provider = config.provider;
    final apiKey = config.apiKey;
    _logger.info('LLM Provider: $provider');
    _logger.info('API Key (first 4 chars): ${apiKey.substring(0, 4)}');


    switch (config.provider) {
      case LLMProvider.openRouter:
        final headers = {
          ...baseHeaders,
          'Authorization': 'Bearer ${config.apiKey}',
          'HTTP-Referer':
          config.openRouterConfig?.httpReferer ??
              'https://github.com/yourusername/yourapp',
        };

        if (config.openRouterConfig?.xTitle != null) {
          headers['X-Title'] = config.openRouterConfig!.xTitle!;
        }

        return headers;
      case LLMProvider.anthropic:
        return {
          ...baseHeaders,
          'x-api-key': config.apiKey,
          'anthropic-version': '2023-06-01',
        };
      case LLMProvider.mistral:
        return {...baseHeaders, 'Authorization': 'Bearer ${config.apiKey}'};
      case LLMProvider.gemini:
        return {...baseHeaders, 'x-goog-api-key': config.apiKey};
      case null:
      // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Map<String, Object> _buildRequestBody(List<LLMMessage> messages) {
    switch (config.provider) {
      case LLMProvider.openRouter:
        final Map<String, Object> body = {
          'model': config.model,
          'messages': messages.map((m) => m.toJson()).toList(),
          'stream': true,
        };

        // Add all OpenRouter configuration parameters
        if (config.openRouterConfig != null) {
          final configJson = config.openRouterConfig!.toJson();
          for (final entry in configJson.entries) {
            body[entry.key] = entry.value as Object;
          }
        }

        // Add temperature and max_tokens if available in LLMConfig
        if (config.temperature != null) {
          body['temperature'] = config.temperature!;
        }
        if (config.maxTokens != null) {
          body['max_tokens'] = config.maxTokens!;
        }


        // Add any extra parameters
        if (config.extraParams != null) {
          for (final entry in config.extraParams!.entries) {
            body[entry.key] = entry.value as Object;
          }
        }

        return body;
      case LLMProvider.anthropic:
        final Map<String, Object> result = {
          'model': config.model,
          'messages': messages.map((m) => m.toJson()).toList(),
          'stream': true,
        };

        if (config.extraParams != null) {
          for (final entry in config.extraParams!.entries) {
            result[entry.key] = entry.value as Object;
          }
        }

        return result;
    // Add other providers' request body formats
      default:
        throw UnimplementedError(
          'Provider ${config.provider} not implemented yet',
        );
    }
  }

  Stream<String> streamCompletion(List<LLMMessage> messages) async* {
    final url = '$_baseUrl/chat/completions';
    final headers = _getHeaders();
    final body = _buildRequestBody(messages);

    _logger.info('Request URL: $url');
    _logger.info('Request headers: $headers');
    _logger.info('Request body: $body');


    try {
      final request =
      http.Request('POST', Uri.parse(url))
        ..headers.addAll(headers)
        ..body = jsonEncode(body);

      final response = await http.Client().send(request);

      _logger.info('Response status code: ${response.statusCode}');


      if (response.statusCode != 200) {
        _logger.warning('Failed response: ${response.statusCode}, body: ${await response.stream.bytesToString()}');
        throw Exception('Failed to get response: ${response.statusCode}');
      }

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        for (var line in chunk.split('\n')) {
          if (line.isEmpty) continue;
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') continue;

            try {
              final jsonData = jsonDecode(data);
              _logger.finer('jsonData chunk: $jsonData'); // Log jsonData chunk
              final content = _extractContentFromChunk(jsonData);
              if (content.isNotEmpty) {
                yield content;
              }
            } catch (e) {
              _logger.warning('Error parsing chunk: $e, line: $line');
            }
          }
        }
      }
    } catch (e) {
      _logger.severe('Stream completion error: $e');
      throw Exception('Stream completion error: $e');
    }
  }

  String _extractContentFromChunk(Map<String, dynamic> chunk) {
    switch (config.provider) {
      case LLMProvider.openRouter:
        return chunk['choices'][0]['delta']['content'] ?? '';
      case LLMProvider.anthropic:
        return chunk['delta']['text'] ?? '';
    // Add other providers' chunk parsing logic
      default:
        throw UnimplementedError(
          'Provider ${config.provider} not implemented yet',
        );
    }
  }
}