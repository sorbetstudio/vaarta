// lib/screens/settings/settings_model_config.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vaarta/theme/theme_extensions.dart';

class SettingsModelConfig extends StatefulWidget {
  final String selectedModel;
  final double temperature;
  final int maxTokens;
  final Map<String, String> models;
  final ValueChanged<String?> onModelChanged;
  final ValueChanged<double> onTemperatureChanged;
  final ValueChanged<int> onMaxTokensChanged;

  const SettingsModelConfig({
    super.key,
    required this.selectedModel,
    required this.temperature,
    required this.maxTokens,
    required this.models,
    required this.onModelChanged,
    required this.onTemperatureChanged,
    required this.onMaxTokensChanged,
  });

  @override
  State<SettingsModelConfig> createState() => _SettingsModelConfigState();
}

class _SettingsModelConfigState extends State<SettingsModelConfig> {
  late TextEditingController _maxTokensController;

  @override
  void initState() {
    super.initState();
    _maxTokensController = TextEditingController(
      text: widget.maxTokens.toString(),
    );
  }

  @override
  void didUpdateWidget(SettingsModelConfig oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.maxTokens != oldWidget.maxTokens) {
      // Update text field only if the value actually changed programmatically
      final currentFieldValue = int.tryParse(_maxTokensController.text);
      if (currentFieldValue != widget.maxTokens) {
        _maxTokensController.text = widget.maxTokens.toString();
        // Move cursor to end
        _maxTokensController.selection = TextSelection.fromPosition(
          TextPosition(offset: _maxTokensController.text.length),
        );
      }
    }
    if (widget.selectedModel != oldWidget.selectedModel) {
      // Ensure the dropdown reflects the external state change
      // (No explicit action needed here as DropdownButton value handles it)
    }
    if (widget.temperature != oldWidget.temperature) {
      // Ensure the slider reflects the external state change
      // (No explicit action needed here as Slider value handles it)
    }
  }

  @override
  void dispose() {
    _maxTokensController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildModelSelector(context),
        _buildTemperatureSlider(context),
        _buildMaxTokensSlider(context),
      ],
    );
  }

  Widget _buildModelSelector(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.medium,
        vertical: context.spacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Select AI Model", style: context.typography.body1),
          SizedBox(height: context.spacing.small),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.radius.medium),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.selectedModel,
                  isExpanded: true,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: context.colors.primary,
                  ),
                  items:
                      widget.models.entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(
                                entry.value,
                                style: context.typography.body1,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: widget.onModelChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureSlider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.medium,
        vertical: context.spacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Temperature", style: context.typography.body1),
          Slider(
            value: widget.temperature,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            label: widget.temperature.toStringAsFixed(1),
            activeColor: context.colors.primary,
            inactiveColor: context.colors.surfaceVariant,
            onChanged: widget.onTemperatureChanged,
          ),
          Text(
            "Controls randomness: 0.0 is deterministic, 2.0 is max randomness.",
            style: context.typography.caption.copyWith(
              color: context.colors.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaxTokensSlider(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.medium,
        vertical: context.spacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Max Tokens", style: context.typography.body1),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: widget.maxTokens.toDouble().clamp(
                    50.0,
                    4096.0,
                  ), // Ensure value stays within bounds
                  min: 50.0,
                  max: 4096,
                  // divisions: 809, // divisions = (max - min) / step. (4096-50)/5 = 809.2. Let's use 4046 for smoother steps? (4096-50 = 4046)
                  divisions: (4096 - 50), // One division per integer step
                  label: widget.maxTokens.toString(),
                  activeColor: context.colors.primary,
                  inactiveColor: context.colors.surfaceVariant,
                  onChanged: (value) {
                    final intValue = value.round();
                    // Update the text field immediately while sliding
                    _maxTokensController.text = intValue.toString();
                    _maxTokensController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _maxTokensController.text.length),
                    );
                    widget.onMaxTokensChanged(intValue); // Call the callback
                  },
                ),
              ),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _maxTokensController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    final parsedValue = int.tryParse(value) ?? 50;
                    final clampedValue = parsedValue.clamp(50, 4096);
                    // Only call the callback if the clamped value is different
                    // to avoid loops if the user types something outside the range
                    // which gets clamped back.
                    if (clampedValue != widget.maxTokens) {
                      widget.onMaxTokensChanged(clampedValue);
                    }
                    // Ensure the text field shows the clamped value if input was out of bounds
                    if (parsedValue != clampedValue) {
                      _maxTokensController.text = clampedValue.toString();
                      _maxTokensController
                          .selection = TextSelection.fromPosition(
                        TextPosition(offset: _maxTokensController.text.length),
                      );
                    }
                  },
                  // Optional: Update state on submission too
                  onSubmitted: (value) {
                    final parsedValue = int.tryParse(value) ?? 50;
                    final clampedValue = parsedValue.clamp(50, 4096);
                    widget.onMaxTokensChanged(clampedValue);
                    _maxTokensController.text = clampedValue.toString();
                    _maxTokensController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _maxTokensController.text.length),
                    );
                  },
                ),
              ),
            ],
          ),
          Text(
            "Maximum number of tokens in the AI response.",
            style: context.typography.caption.copyWith(
              color: context.colors.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }
}
