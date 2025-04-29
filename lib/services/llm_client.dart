// lib/services/llm_client.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';
import './tool_registry.dart';

final _apiLogger = Logger('LLMClient.API');

void _logRequest(
  String method,
  String url,
  Map<String, String> headers,
  Map<String, dynamic> body, {
  int? statusCode,
  int? responseTimeMs,
}) {
  final sanitizedHeaders = Map.from(headers)..remove('Authorization');
  final sanitizedBody = Map.from(body)
    ..removeWhere((k, v) => k.contains('key') || k.contains('secret'));

  final logMessage = StringBuffer('''
API Request:
$method $url
Headers: $sanitizedHeaders
Body: $sanitizedBody
''');

  if (statusCode != null) {
    logMessage.writeln('Response Status: $statusCode');
  }
  if (responseTimeMs != null) {
    logMessage.writeln('Response Time: ${responseTimeMs}ms');
  }

  if (statusCode == null || statusCode >= 200 && statusCode < 300) {
    _apiLogger.info(logMessage.toString());
  } else {
    _apiLogger.warning(logMessage.toString());
  }
}

class ToastTool {
  final String id;
  final String message;

  ToastTool({required this.id, required this.message});

  factory ToastTool.fromJson(Map<String, dynamic> json) {
    return ToastTool(id: json['id'], message: json['message']);
  }

  void execute() {
    print('[TOAST] $message');
  }
}

final _logger = Logger('LLMClient');

enum LLMProvider { openRouter, anthropic, mistral, gemini }

class LLMMessage {
  final String role;
  final String content;
  final String? toolCallId; // Add toolCallId
  final String? name; // Add name
  final List<Map<String, dynamic>>? toolCalls; // Add toolCalls

  LLMMessage({
    required this.role,
    required this.content,
    this.toolCallId, // Add to constructor
    this.name, // Add to constructor
    this.toolCalls, // Add to constructor
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {'role': role, 'content': content};
    if (toolCallId != null) {
      json['tool_call_id'] = toolCallId;
    }
    if (name != null) {
      json['name'] = name;
    }
    if (toolCalls != null) {
      json['tool_calls'] = toolCalls;
    }
    return json;
  }
}

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
  final ToolRegistry toolRegistry;
  final Map<String, bool> toolEnabledState;

  LLMClient({
    required this.config,
    required this.toolRegistry,
    required this.toolEnabledState,
  });

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

        // Add tools schemas for OpenRouter
        if (config.provider == LLMProvider.openRouter) {
          body['tools'] = toolRegistry.generateToolSchemas();
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

  /// Streams the completion response from the LLM.
  /// Implements the agentic loop for OpenRouter tool calling.
  Stream<String> streamCompletion(List<LLMMessage> messages) async* {
    final url = '$_baseUrl/chat/completions';
    final headers = _getHeaders();
    final initialRequestBody = _buildRequestBody(messages);

    // Ensure streaming is enabled for the initial request
    initialRequestBody['stream'] = true;

    final stopwatch = Stopwatch()..start();
    _logRequest('POST', url, headers, initialRequestBody);

    try {
      final request =
          http.Request('POST', Uri.parse(url))
            ..headers.addAll(headers)
            ..body = jsonEncode(initialRequestBody);

      final response = await http.Client().send(request);
      stopwatch.stop();

      _logRequest(
        'POST',
        url,
        headers,
        initialRequestBody,
        statusCode: response.statusCode,
        responseTimeMs: stopwatch.elapsedMilliseconds,
      );

      if (response.statusCode != 200) {
        _logger.warning(
          'Failed initial response: ${response.statusCode}, body: ${await response.stream.bytesToString()}',
        );
        throw Exception(
          'Failed to get initial response: ${response.statusCode}',
        );
      }

      // Accumulate streamed chunks to reconstruct the full message
      Map<int, Map<String, dynamic>> accumulatedToolCallsMap = {};
      StringBuffer accumulatedContent = StringBuffer();
      Map<String, dynamic>?
      firstResponseMessage; // To store the reconstructed message

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        for (var line in chunk.split('\n')) {
          if (line.isEmpty) continue;
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') continue;

            try {
              final jsonData = jsonDecode(data);
              _logger.finer('jsonData chunk: $jsonData');

              // Accumulate content and tool calls from deltas
              final choice = jsonData['choices'][0];
              if (choice['delta']['content'] != null) {
                accumulatedContent.write(choice['delta']['content']);
              }
              if (choice['delta']['tool_calls'] != null) {
                final toolCallsDelta = choice['delta']['tool_calls'] as List;
                for (final toolCallDelta in toolCallsDelta) {
                  final index = toolCallDelta['index'] as int;
                  if (!accumulatedToolCallsMap.containsKey(index)) {
                    accumulatedToolCallsMap[index] = {};
                  }
                  final accumulatedCall = accumulatedToolCallsMap[index]!;
                  // Explicitly add the tool call type
                  accumulatedCall['type'] = 'function';

                  // Merge delta into accumulated call
                  if (toolCallDelta['id'] != null) {
                    accumulatedCall['id'] = toolCallDelta['id'];
                  }
                  if (toolCallDelta['function'] != null) {
                    if (!accumulatedCall.containsKey('function')) {
                      accumulatedCall['function'] = {};
                    }
                    if (toolCallDelta['function']['name'] != null) {
                      accumulatedCall['function']['name'] =
                          toolCallDelta['function']['name'];
                    }
                    if (toolCallDelta['function']['arguments'] != null) {
                      // Arguments are streamed as chunks, concatenate them
                      accumulatedCall['function']['arguments'] =
                          (accumulatedCall['function']['arguments'] ?? '') +
                          toolCallDelta['function']['arguments'];
                    }
                  }
                }
              }

              // Store the final message structure from the last chunk if available
              if (choice['message'] != null) {
                firstResponseMessage = choice['message'];
              }
            } catch (e) {
              _logger.warning('Error parsing chunk: $e, line: $line');
            }
          }
        }
      }

      // After the first stream is complete, check for tool calls
      final accumulatedToolCalls = accumulatedToolCallsMap.values.toList();

      if (accumulatedToolCalls.isNotEmpty) {
        _logger.info(
          'Tool calls detected in first response: $accumulatedToolCalls',
        );
        // Execute tools and prepare for the second API call
        List<LLMMessage> toolResultMessages = [];
        for (final toolCall in accumulatedToolCalls) {
          final toolName = toolCall['function']['name'];
          final toolArgsString = toolCall['function']['arguments'];
          final toolCallId = toolCall['id'];

          final args = jsonDecode(toolArgsString);
          _logger.info('Attempting to execute tool: $toolName');

          if (toolEnabledState[toolName] == true) {
            _logger.info('Tool $toolName is enabled. Executing...');
            final toolResult = await toolRegistry.executeTool(
              name: toolName,
              params: args,
            );
            _logger.info('Tool execution result for $toolName: $toolResult');
            toolResultMessages.add(
              LLMMessage(
                role: 'tool',
                toolCallId: toolCallId,
                name: toolName,
                content: jsonEncode(toolResult), // Tool result as content
              ),
            );
          } else {
            _logger.warning(
              'Tool $toolName is disabled in settings. Skipping execution.',
            );
            // Add a message indicating the tool was skipped
            toolResultMessages.add(
              LLMMessage(
                role: 'tool',
                toolCallId: toolCallId,
                name: toolName,
                content: jsonEncode({
                  'status': 'skipped',
                  'reason': 'Tool $toolName is disabled in settings.',
                }),
              ),
            );
          }
        }

        // Construct messages for the second API call
        List<LLMMessage> messagesForSecondCall = List.from(messages);
        // Add the first response message (with tool calls and any content)
        // Use the reconstructed message or build one from accumulated data
        messagesForSecondCall.add(
          LLMMessage(
            role: 'assistant',
            content: accumulatedContent.toString(),
            toolCalls: accumulatedToolCalls,
          ),
        );
        // Add tool result messages
        messagesForSecondCall.addAll(toolResultMessages);

        _logger.info(
          'Making second API call with messages: $messagesForSecondCall',
        );

        // Make the second API call
        final secondRequestBody = _buildRequestBody(messagesForSecondCall);
        secondRequestBody['stream'] =
            true; // Ensure streaming for the second call

        final secondRequest =
            http.Request('POST', Uri.parse(url))
              ..headers.addAll(headers)
              ..body = jsonEncode(secondRequestBody);

        final secondResponse = await http.Client().send(secondRequest);

        if (secondResponse.statusCode != 200) {
          _logger.warning(
            'Failed second response: ${secondResponse.statusCode}, body: ${await secondResponse.stream.bytesToString()}',
          );
          throw Exception(
            'Failed to get second response: ${secondResponse.statusCode}',
          );
        }

        // Stream content from the second response
        await for (final contentChunk in _streamResponseContent(
          secondResponse.stream,
        )) {
          yield contentChunk;
        }
      } else {
        _logger.info(
          'No tool calls detected in first response. Yielding accumulated content.',
        );
        // No tool calls, just yield the accumulated content from the first response
        if (accumulatedContent.isNotEmpty) {
          yield accumulatedContent.toString();
        }
      }
    } on Exception catch (e, stackTrace) {
      _logger.severe('Stream completion error: $e', e, stackTrace);
      throw Exception('Stream completion error: $e');
    }
  }

  /// Helper to stream content from an HTTP response stream.
  Stream<String> _streamResponseContent(http.ByteStream byteStream) async* {
    await for (final chunk in byteStream.transform(utf8.decoder)) {
      for (var line in chunk.split('\n')) {
        if (line.isEmpty) continue;
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') continue;

          try {
            final jsonData = jsonDecode(data);
            // Extract content from the chunk - this assumes the second response
            // will primarily contain content after tool execution.
            final content = await _extractContentFromChunk(jsonData);
            if (content.isNotEmpty) {
              yield content;
            }
          } catch (e) {
            _logger.warning(
              'Error parsing streamed content chunk: $e, line: $line',
            );
          }
        }
      }
    }
  }

  Future<String> _extractContentFromChunk(Map<String, dynamic> chunk) async {
    switch (config.provider) {
      case LLMProvider.openRouter:
        // For OpenRouter, this method is now only used to extract content
        // from the *second* API call's stream, after tool execution.
        // The tool_calls from the *first* call are handled by accumulating deltas
        // in streamCompletion.
        return chunk['choices'][0]['delta']['content'] ?? '';
      case LLMProvider.anthropic:
        return chunk['delta']['text'] ?? '';
      default:
        throw UnimplementedError(
          'Provider ${config.provider} not implemented yet',
        );
    }
  }
}
