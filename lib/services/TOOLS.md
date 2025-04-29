# Tool System Documentation

## Overview
The tool system provides extensible capabilities that can be invoked through the LLM interface. Tools allow for integration with external systems, data processing, and specialized operations.

## API Documentation

### Tool Interface Requirements
All tools must implement the `Tool` interface with these required components:

```dart
abstract class Tool {
  String get name;
  String get description;
  JsonSchema get inputSchema;
  JsonSchema get outputSchema;
  
  Future<dynamic> execute(Map<String, dynamic> params);
}
```

### Schema Specifications
Tools must define input and output schemas using JSON Schema:

**Example Input Schema:**
```json
{
  "type": "object",
  "properties": {
    "query": {
      "type": "string",
      "description": "Search query string"
    },
    "maxResults": {
      "type": "integer",
      "minimum": 1,
      "maximum": 100,
      "default": 10
    }
  },
  "required": ["query"]
}
```

**Example Output Schema:**
```json
{
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "title": {"type": "string"},
      "url": {"type": "string"},
      "snippet": {"type": "string"}
    }
  }
}
```

### Error Handling
Tools should throw specific exceptions:

```dart
// Basic execution error
throw ToolExecutionException(
  code: 'INVALID_INPUT',
  message: 'Query parameter is required'
);

// Permission error  
throw ToolPermissionException(
  requiredRole: 'admin',
  attemptedAction: 'delete_user'
);

// Rate limiting
throw ToolRateLimitException(
  retryAfter: Duration(seconds: 30)
);
```

## Usage Examples

### Basic Tool Registration
```dart
// Register a simple tool
registry.registerTool(
  CalculatorTool(),
  description: 'Performs basic arithmetic operations'
);

// Register with custom metadata
registry.registerTool(
  DatabaseQueryTool(),
  category: 'data',
  icon: Icons.storage,
  timeout: Duration(seconds: 10)
);
```

### Tool Execution
```dart
// Basic execution
final result = await registry.executeTool(
  name: 'search',
  params: {'query': 'flutter docs'}
);

// With options
final result = await registry.executeTool(
  name: 'weather',
  params: {'location': 'San Francisco'},
  options: ToolExecutionOptions(
    cacheTtl: Duration(hours: 1),
    timeout: Duration(seconds: 5)
  )
);
```

### Permission Management
```dart
// Role-based permissions
registry.registerTool(
  AdminTool(),
  allowedRoles: ['admin', 'superuser']
);

// Runtime permission check
if (!registry.canExecuteTool(user, 'delete_user')) {
  throw ToolPermissionException(...);
}
```

### Caching Examples
```dart
// Enable caching with TTL
registry.executeTool(
  name: 'exchange_rates',
  params: {'currency': 'USD'},
  options: ToolExecutionOptions(
    cacheTtl: Duration(minutes: 30)
);

// Bypass cache
registry.executeTool(
  name: 'live_stats',
  params: {},
  options: ToolExecutionOptions(useCache: false)
);

// Clear cache
registry.clearToolCache('weather');
```

## Troubleshooting Guide

### Common Errors

| Error Code        | Description                   | Solution                          |
| ----------------- | ----------------------------- | --------------------------------- |
| TOOL_NOT_FOUND    | Tool name doesn't exist       | Verify tool is registered         |
| INVALID_INPUT     | Parameters don't match schema | Check inputSchema requirements    |
| PERMISSION_DENIED | User lacks required role      | Verify user roles                 |
| TIMEOUT           | Tool execution took too long  | Increase timeout or optimize tool |
| RATE_LIMITED      | Too many requests             | Wait or implement backoff         |

### Debugging Tips
1. **Enable verbose logging**:
```dart
ToolRegistry.debugMode = true;
```

2. **Validate schemas**:
```dart
final errors = registry.validateInput('search', params);
if (errors.isNotEmpty) {
  print('Validation errors: $errors');
}
```

3. **Inspect tool analytics**:
```dart
final stats = registry.getToolStats('search');
print('Avg execution time: ${stats.averageExecutionTime}');
```

### Performance Optimization
1. **Cache strategies**:
   - Use appropriate TTL values
   - Implement cache invalidation
   - Consider stale-while-revalidate

2. **Parallel execution**:
```dart
final results = await Future.wait([
  registry.executeTool(name: 'weather', params: {...}),
  registry.executeTool(name: 'news', params: {...})
]);
```

3. **Batch operations**:
```dart
registry.executeBatch([
  ToolRequest(name: 'search', params: {...}),
  ToolRequest(name: 'translate', params: {...})
]);
```

## Available Tools Reference

### Core Tools
- `calculator`: Basic arithmetic operations
- `search`: Content search with regex support
- `fetch`: HTTP requests with caching
- `toast`: UI notifications

### Advanced Tools
- `database`: SQL query execution
- `ai`: ML model inference
- `filesystem`: File operations
- `auth`: User authentication