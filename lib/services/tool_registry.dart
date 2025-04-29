// lib/services/tool_registry.dart
import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:math_expressions/math_expressions.dart';

/// Custom exception for tool execution errors.
///
/// Contains detailed information about tool failures including:
/// - Tool name that failed
/// - Error message
/// - Original exception
/// - Stack trace
///
/// Example:
/// ```dart
/// try {
///   await registry.executeTool(name: 'calculator', params: {...});
/// } on ToolExecutionException catch (e) {
///   print('Tool ${e.toolName} failed: ${e.message}');
/// }
/// ```
class ToolExecutionException implements Exception {
  final String toolName;
  final String message;
  final dynamic originalError;
  final StackTrace stackTrace;

  ToolExecutionException({
    required this.toolName,
    required this.message,
    required this.originalError,
    required this.stackTrace,
  });

  @override
  String toString() {
    return 'ToolExecutionException(tool: $toolName, message: $message, error: $originalError)';
  }
}

/// Standard interface that all tools must implement.
///
/// Tools are self-contained operations that can be executed by the system.
/// Each tool must define:
/// - A unique name
/// - Description of its functionality
/// - Input/output schemas
/// - Execution logic
///
/// Example implementation:
/// ```dart
/// class ExampleTool implements Tool {
///   @override
///   final String name = 'example';
///
///   @override
///   final String description = 'Example tool description';
///
///   @override
///   Map<String, dynamic> get inputSchema => {...};
///
///   @override
///   Map<String, dynamic> get outputSchema => {...};
///
///   @override
///   Future<Map<String, dynamic>> execute(Map<String, dynamic> params) async {...}
/// }
/// ```
abstract class Tool {
  /// Unique name of the tool
  String get name;

  /// Description of what the tool does
  String get description;

  /// JSON Schema for input parameters
  Map<String, dynamic> get inputSchema;

  /// JSON Schema for output
  Map<String, dynamic> get outputSchema;

  /// Execute the tool with given parameters
  Future<Map<String, dynamic>> execute(Map<String, dynamic> params);
}

/// Tool for searching files and content within the workspace.
///
/// Features:
/// - Recursive file searching
/// - Pattern matching
/// - Case sensitivity control
///
/// Example usage:
/// ```dart
/// final result = await registry.executeTool(
///   name: 'search',
///   params: {
///     'query': 'TODO',
///     'path': './lib',
///     'filePattern': '*.dart'
///   }
/// );
/// ```
class SearchTool implements Tool {
  @override
  final String name = 'search';

  @override
  final String description = 'Searches files and content matching the query';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'query': {'type': 'string', 'description': 'Search query'},
      'path': {'type': 'string', 'description': 'Base path to search from'},
      'filePattern': {
        'type': 'string',
        'description': 'File pattern to match (e.g. *.dart)',
      },
      'caseSensitive': {
        'type': 'boolean',
        'description': 'Whether search should be case sensitive',
      },
    },
    'required': ['query'],
  };

  @override
  Map<String, dynamic> get outputSchema => {
    'type': 'object',
    'properties': {
      'matches': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'file': {'type': 'string'},
            'line': {'type': 'number'},
            'content': {'type': 'string'},
          },
        },
      },
      'count': {'type': 'number'},
    },
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> params) async {
    // Implementation would use dart:io to search files
    // This is a simplified example
    return {
      'matches': [],
      'count': 0,
      '_note': 'Actual implementation would search files',
    };
  }
}

/// Tool for making HTTP requests to external APIs/services.
///
/// Supports:
/// - All standard HTTP methods (GET, POST, PUT, etc.)
/// - Custom headers
/// - Request bodies
///
/// Example usage:
/// ```dart
/// final result = await registry.executeTool(
///   name: 'fetch',
///   params: {
///     'url': 'https://api.example.com/data',
///     'method': 'GET',
///     'headers': {'Authorization': 'Bearer token'}
///   }
/// );
/// ```
class FetchTool implements Tool {
  @override
  final String name = 'fetch';

  @override
  final String description = 'Makes HTTP requests to fetch data from URLs';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'url': {'type': 'string', 'description': 'URL to fetch'},
      'method': {
        'type': 'string',
        'enum': ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
        'default': 'GET',
      },
      'headers': {
        'type': 'object',
        'additionalProperties': {'type': 'string'},
      },
      'body': {'type': 'string', 'description': 'Request body'},
    },
    'required': ['url'],
  };

  @override
  Map<String, dynamic> get outputSchema => {
    'type': 'object',
    'properties': {
      'status': {'type': 'number'},
      'headers': {
        'type': 'object',
        'additionalProperties': {'type': 'string'},
      },
      'body': {'type': 'string'},
    },
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> params) async {
    // Implementation would use package:http
    // This is a simplified example
    return {
      'status': 200,
      'headers': {},
      'body': '',
      '_note': 'Actual implementation would make HTTP request',
    };
  }
}

/// Tool for performing basic arithmetic calculations.
///
/// Supported operations:
/// - Addition (+)
/// - Subtraction (-)
/// - Multiplication (*)
/// - Division (/)
///
/// Example usage:
/// ```dart
/// final result = await registry.executeTool(
///   name: 'calculator',
///   params: {
///     'operation': 'add',
///     'a': 5,
///     'b': 3
///   }
/// );
/// print(result['result']); // 8
/// ```
class CalculatorTool implements Tool {
  @override
  final String name = 'calculator';

  @override
  final String description = 'Performs basic arithmetic calculations';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'expression': {
        'type': 'string',
        'description': 'Mathematical expression to evaluate',
      },
    },
    'required': ['expression'],
  };

  @override
  Map<String, dynamic> get outputSchema => {
    'type': 'object',
    'properties': {
      'result': {'type': 'number'},
    },
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> params) async {
    try {
      final expressionString = params['expression'] as String;

      // Parse the expression
      Parser p = Parser();
      Expression exp = p.parse(expressionString);

      // Evaluate the expression
      ContextModel cm = ContextModel();
      // Use evaluate with a type parameter to handle both int and double results
      dynamic evaluationResult = exp.evaluate(EvaluationType.REAL, cm);

      // Ensure the result is a number (num includes both int and double in Dart)
      if (evaluationResult is num) {
        return {'result': evaluationResult};
      } else {
        throw Exception('Expression evaluation did not return a number.');
      }
    } catch (e, stackTrace) {
      throw ToolExecutionException(
        toolName: name,
        message: 'Calculation failed: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Central registry for managing and executing tools.
///
/// Features:
/// - Tool registration and lookup
/// - Usage analytics tracking
/// - Role-based permissions
/// - Result caching
///
/// Example usage:
/// ```dart
/// final registry = ToolRegistry();
/// registry.registerTool(CalculatorTool(), allowedRoles: ['admin']);
///
/// // Execute with permissions and caching
/// final result = await registry.executeTool(
///   name: 'calculator',
///   params: {'operation': 'add', 'a': 2, 'b': 2},
///   role: 'admin',
///   useCache: true
/// );
/// ```
class ToolRegistry {
  final _tools = <String, Tool>{};
  final _logger = Logger('ToolRegistry');
  final _analytics = <String, int>{};
  final _permissions = <String, List<String>>{};
  final _cache = <String, Map<String, dynamic>>{};

  /// Register a new tool with the registry
  /// Register a new tool with optional role restrictions.
  ///
  /// [tool]: The tool implementation to register
  /// [allowedRoles]: List of role names that can use this tool (null = no restrictions)
  void registerTool(Tool tool, {List<String>? allowedRoles}) {
    if (_tools.containsKey(tool.name)) {
      _logger.warning('Tool ${tool.name} already registered - overwriting');
    }
    _tools[tool.name] = tool;
    if (allowedRoles != null) {
      _permissions[tool.name] = allowedRoles;
    }
    _analytics[tool.name] = 0; // Initialize usage counter
  }

  /// Get a tool by name
  Tool? getTool(String name) => _tools[name];

  /// Get all registered tools
  List<Tool> getAllTools() => _tools.values.toList();

  /// Generate OpenAPI schema for all tools
  List<Map<String, dynamic>> generateToolSchemas() {
    return _tools.values.map((tool) {
      return {
        'type': 'function',
        'function': {
          'name': tool.name,
          'description': tool.description,
          'parameters': tool.inputSchema,
        },
      };
    }).toList();
  }

  /// Execute a tool by name with given parameters
  /// Execute a tool with given parameters and options.
  ///
  /// [name]: Name of the tool to execute
  /// [params]: Input parameters for the tool
  /// [role]: Optional role for permission checking
  /// [useCache]: Whether to use cached results if available
  ///
  /// Returns: Tool execution result
  /// Throws: ToolExecutionException on failure
  Future<Map<String, dynamic>> executeTool({
    required String name,
    required Map<String, dynamic> params,
    String? role,
    bool useCache = true,
  }) async {
    final tool = getTool(name);
    if (tool == null) {
      throw Exception('Tool $name not found');
    }

    // Check permissions
    if (role != null && _permissions.containsKey(name)) {
      if (!_permissions[name]!.contains(role)) {
        throw Exception(
          'User with role $role not authorized to use tool $name',
        );
      }
    }

    // Check cache
    final cacheKey = '$name-${jsonEncode(params)}';
    if (useCache && _cache.containsKey(cacheKey)) {
      _logger.info('Returning cached result for $name');
      return _cache[cacheKey]!;
    }

    try {
      // Track usage
      _analytics[name] = (_analytics[name] ?? 0) + 1;

      final result = await tool.execute(params);

      // Cache result
      _cache[cacheKey] = result;

      return result;
    } catch (e, stackTrace) {
      _logger.severe('Error executing tool $name', e, stackTrace);
      throw ToolExecutionException(
        toolName: name,
        message: 'Failed to execute tool: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get analytics data showing tool usage counts.
  ///
  /// Returns: Map of tool names to usage counts
  Map<String, int> getAnalytics() => Map.from(_analytics);

  /// Clear all cached tool results.
  void clearCache() => _cache.clear();

  /// Get list of tools available to a specific role.
  ///
  /// [role]: The role to check
  /// Returns: List of tool names accessible by the role
  List<String> getToolsForRole(String? role) {
    if (role == null) return _tools.keys.toList();
    return _tools.keys.where((name) {
      return !_permissions.containsKey(name) ||
          _permissions[name]!.contains(role);
    }).toList();
  }
}

/// Tool for displaying toast notifications to the user.
///
/// This is a UI-focused tool that shows brief messages.
///
/// Example usage:
/// ```dart
/// await registry.executeTool(
///   name: 'show_toast',
///   params: {'message': 'Operation completed successfully!'}
/// );
/// ```
class ToastToolImpl implements Tool {
  @override
  final String name = 'show_toast';

  @override
  final String description = 'Displays a toast notification to the user';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'message': {
        'type': 'string',
        'description': 'The message to display in the toast',
      },
    },
    'required': ['message'],
  };

  @override
  Map<String, dynamic> get outputSchema => {
    'type': 'object',
    'properties': {
      'success': {'type': 'boolean'},
      'timestamp': {'type': 'string', 'format': 'date-time'},
    },
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> params) async {
    try {
      final message = params['message'] as String;
      print('[TOAST] $message');
      return {'success': true, 'timestamp': DateTime.now().toIso8601String()};
    } catch (e, stackTrace) {
      throw ToolExecutionException(
        toolName: name,
        message: 'Failed to show toast: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
