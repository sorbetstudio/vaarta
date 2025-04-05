// lib/screens/chat/chat_input_area.dart
import 'package:flutter/material.dart';
import 'package:vaarta/models/settings_state.dart';
import 'package:vaarta/theme/theme_extensions.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController textController;
  final bool isGenerating;
  final SettingsState settings;
  final Function(String) onSendMessage;
  final VoidCallback onStopStream;

  const ChatInputArea({
    super.key,
    required this.textController,
    required this.isGenerating,
    required this.settings,
    required this.onSendMessage,
    required this.onStopStream,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(context.spacing.small),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.white10 : Colors.black12,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25), // Consider using theme radius
          topRight: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(
                  color: context.colors.onSurface.withOpacity(0.6),
                ),
                filled: true,
                fillColor: context.colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.radius.large),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.radius.large),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.radius.large),
                  borderSide: BorderSide.none,
                ),
                hoverColor: Colors.transparent,
              ),
              style: context.typography.body1,
              onSubmitted: isGenerating ? null : onSendMessage,
              enabled: !isGenerating,
              maxLines: null,
              textInputAction: TextInputAction.send,
            ),
            SizedBox(height: context.spacing.small),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Plus button to open options
                IconButton(
                  onPressed: () => _showOptions(context), // Pass context
                  icon: const Icon(Icons.add),
                  color: context.colors.primary,
                ),
                Row(
                  children: [
                    // Camera button
                    IconButton(
                      onPressed: _handleCamera,
                      icon: const Icon(Icons.camera_alt_outlined),
                      color: context.colors.primary,
                    ),
                    // Photo button
                    IconButton(
                      onPressed: _handlePhotos,
                      icon: const Icon(Icons.photo_outlined),
                      color: context.colors.primary,
                    ),
                    // Send/Stop button
                    IconButton(
                      onPressed:
                          isGenerating
                              ? onStopStream
                              : settings.apiKey.isEmpty
                              ? null // Disable if API key missing
                              : () => onSendMessage(textController.text),
                      icon: Icon(
                        isGenerating ? Icons.stop : Icons.send,
                        color:
                            settings.apiKey.isEmpty
                                ? context.colors.onSurface.withOpacity(
                                  0.4,
                                ) // Dim if disabled
                                : context.colors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper methods moved from ChatScreen ---

  void _showOptions(BuildContext context) {
    // Added context parameter
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? context.colors.surfaceVariant
                    : context.colors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(context.radius.medium),
              topRight: Radius.circular(context.radius.medium),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: context.spacing.large),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionButton(
                      context: context, // Pass context
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () {
                        _handleCamera(); // Call internal method
                        Navigator.pop(context);
                      },
                    ),
                    _buildOptionButton(
                      context: context, // Pass context
                      icon: Icons.photo_outlined,
                      label: 'Photos',
                      onTap: () {
                        _handlePhotos(); // Call internal method
                        Navigator.pop(context);
                      },
                    ),
                    _buildOptionButton(
                      context: context, // Pass context
                      icon: Icons.upload_file_outlined,
                      label: 'Files',
                      onTap: () {
                        // TODO: Handle files
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _buildSettingsOption(
                context: context, // Pass context
                icon: Icons.brush_outlined,
                label: 'Choose style',
                trailing: Row(
                  mainAxisSize:
                      MainAxisSize.min, // Prevent Row from taking full width
                  children: [
                    Text(
                      'Normal', // Placeholder
                      style: TextStyle(color: context.colors.secondary),
                    ),
                    Icon(Icons.chevron_right, color: context.colors.secondary),
                  ],
                ),
              ),
              _buildSettingsOption(
                context: context, // Pass context
                icon: Icons.timer_outlined,
                label: 'Use extended thinking',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PRO',
                      style: TextStyle(
                        color: Colors.purple, // Keep hardcoded for now
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: context.spacing.medium),
                    // Basic Toggle Placeholder (replace with actual toggle if needed)
                    Container(
                      width: 40,
                      height: 24,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(
                          context.radius.medium,
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Align(
                        alignment:
                            Alignment.centerLeft, // Placeholder alignment
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _buildSettingsOption(
                context: context, // Pass context
                icon: Icons.settings,
                label: 'Manage tools',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '2 enabled', // Placeholder
                      style: TextStyle(color: context.colors.secondary),
                    ),
                    Icon(Icons.chevron_right, color: context.colors.secondary),
                  ],
                ),
              ),
              SizedBox(height: context.spacing.large),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required BuildContext context, // Added context
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(context.radius.medium),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: context.colors.primary),
            SizedBox(height: context.spacing.small),
            Text(label, style: context.typography.body2),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption({
    required BuildContext context, // Added context
    required IconData icon,
    required String label,
    required Widget trailing,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.large,
        vertical: context.spacing.medium,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: context.colors.onSurface.withOpacity(0.7),
          ),
          SizedBox(width: context.spacing.medium),
          Text(label, style: context.typography.body1),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }

  void _handleCamera() {
    // Implement camera functionality or leave as placeholder
    print("Camera button tapped");
  }

  void _handlePhotos() {
    // Implement photo selection or leave as placeholder
    print("Photos button tapped");
  }
}
