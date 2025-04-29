# Tool System Documentation

## Overview
The tool system provides extensible capabilities that can be invoked through the LLM interface. 

## Key Components

### Tool Interface
All tools implement the `Tool` interface which requires:
- `name`: Unique identifier
- `description`: Human-readable explanation
- `inputSchema`: JSON Schema for parameters  
- `outputSchema`: JSON Schema for results
- `execute()`: Implementation logic

### Tool Registry
The `ToolRegistry` manages:
- Tool registration/lookup
- Usage analytics
- Role-based permissions
- Result caching

## Available Tools

### CalculatorTool
Performs basic arithmetic operations.

**Example:**
```dart
await registry.executeTool(
  name: 'calculator',
  params: {
    'operation': 'add',
    'a': 5,
    'b': 3
  }
);
```

### SearchTool
Searches files and content.

### FetchTool
Makes HTTP requests.

### ToastTool
Displays UI notifications.

## Error Handling
All tools throw `ToolExecutionException` with details about failures.

## Advanced Features

### Permissions
Tools can be restricted to specific roles:
```dart
registry.registerTool(
  AdminTool(),
  allowedRoles: ['admin']
);
```

### Caching
Results are cached by default. Disable with:
```dart
executeTool(..., useCache: false)
```

### Analytics
Track tool usage:
```dart
final analytics = registry.getAnalytics();