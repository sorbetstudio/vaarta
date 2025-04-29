// lib/services/tool_registry_example.dart
import './tool_registry.dart';
import './llm_client.dart';

/// Example tool implementation
class CalculatorTool implements Tool {
  @override
  final String name = 'calculator';

  @override
  final String description = 'Performs basic arithmetic calculations';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'operation': {
        'type': 'string',
        'enum': ['add', 'subtract', 'multiply', 'divide'],
        'description': 'The arithmetic operation to perform',
      },
      'a': {'type': 'number', 'description': 'First operand'},
      'b': {'type': 'number', 'description': 'Second operand'},
    },
    'required': ['operation', 'a', 'b'],
  };

  @override
  Map<String, dynamic> get outputSchema => {
    'type': 'object',
    'properties': {
      'result': {'type': 'number'},
      'success': {'type': 'boolean'},
    },
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> params) async {
    final op = params['operation'] as String;
    final a = params['a'] as num;
    final b = params['b'] as num;
    num result;

    switch (op) {
      case 'add':
        result = a + b;
        break;
      case 'subtract':
        result = a - b;
        break;
      case 'multiply':
        result = a * b;
        break;
      case 'divide':
        result = a / b;
        break;
      default:
        throw Exception('Invalid operation: $op');
    }

    return {'result': result, 'success': true};
  }
}

/// Example usage
void main() async {
  // Create registry and register tools
  final registry = ToolRegistry();
  registry.registerTool(CalculatorTool());
  registry.registerTool(ToastToolImpl());

  // Create LLM client with registry
  final client = LLMClient(
    config: LLMConfig(apiKey: 'your-api-key', model: 'gpt-4'),
    toolRegistry: registry,
  );

  // Generate tool schemas for LLM
  final schemas = registry.generateToolSchemas();
  print('Available tools:');
  schemas.forEach((s) => print('- ${s['name']}: ${s['description']}'));
}
