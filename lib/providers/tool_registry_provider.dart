import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaarta/services/tool_registry.dart'; // Adjust import based on actual location

/// Provider for the ToolRegistry instance.
/// This provides access to the registry itself, which holds tool definitions.
final toolRegistryProvider = Provider<ToolRegistry>((ref) {
  // Initialize and register tools here.
  // This can be expanded later to dynamically load tools.
  final registry = ToolRegistry();
  registry.registerTool(SearchTool());
  registry.registerTool(FetchTool());
  registry.registerTool(CalculatorTool());
  registry.registerTool(ToastToolImpl());
  return registry;
});

/// State notifier for managing the enabled state of tools.
/// The state is a Map where keys are tool names and values are boolean (enabled/disabled).
class ToolEnabledStateNotifier extends StateNotifier<Map<String, bool>> {
  ToolEnabledStateNotifier(ToolRegistry registry) : super({}) {
    // Initialize state: all tools are enabled by default.
    final initialEnabledState = <String, bool>{};
    for (final tool in registry.getAllTools()) {
      initialEnabledState[tool.name] = true;
    }
    state = initialEnabledState;
  }

  /// Toggles the enabled state of a specific tool.
  void toggleTool(String toolName, bool isEnabled) {
    state = {...state, toolName: isEnabled};
  }
}

/// StateNotifierProvider for the tool enabled state.
/// Depends on the toolRegistryProvider to get the list of available tools.
final toolEnabledStateProvider =
    StateNotifierProvider<ToolEnabledStateNotifier, Map<String, bool>>((ref) {
      final toolRegistry = ref.watch(toolRegistryProvider);
      return ToolEnabledStateNotifier(toolRegistry);
    });

/// Provider to get a list of all tools along with their current enabled state.
/// Useful for displaying in the settings screen.
final toolListWithEnabledStateProvider = Provider<List<Map<String, dynamic>>>((
  ref,
) {
  final toolRegistry = ref.watch(toolRegistryProvider);
  final toolEnabledState = ref.watch(toolEnabledStateProvider);

  return toolRegistry.getAllTools().map((tool) {
    return {
      'name': tool.name,
      'description': tool.description,
      'isEnabled':
          toolEnabledState[tool.name] ??
          false, // Default to false if somehow not in state
    };
  }).toList();
});
