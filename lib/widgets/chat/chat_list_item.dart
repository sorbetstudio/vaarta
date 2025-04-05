// lib/widgets/chat/chat_list_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:vaarta/services/database_helper.dart'; // For keys
import 'package:vaarta/theme/theme_extensions.dart';
import 'package:vaarta/utils/date_utils.dart'; // Import date formatting

class ChatListItem extends StatelessWidget {
  final Map<String, dynamic> chatMetadata;
  final bool isSelected;
  final bool isCurrentChat;
  final bool isMultiSelectMode;
  final bool isRenaming;
  final String? spinnerChar; // Nullable if not renaming
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;
  final VoidCallback onManualRename;
  final VoidCallback onAutoRename;

  const ChatListItem({
    super.key,
    required this.chatMetadata,
    required this.isSelected,
    required this.isCurrentChat,
    required this.isMultiSelectMode,
    required this.isRenaming,
    this.spinnerChar,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
    required this.onManualRename,
    required this.onAutoRename,
  });

  @override
  Widget build(BuildContext context) {
    final chatId = chatMetadata[DatabaseHelper.chatColumnChatId];
    final defaultTitle =
        chatMetadata[DatabaseHelper.chatColumnChatName] ?? 'Chat';
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      chatMetadata[DatabaseHelper.chatColumnLastMessageTimestamp] ?? 0,
    );

    final textStyle = context.typography.body1.copyWith(
      fontWeight: isCurrentChat ? FontWeight.bold : FontWeight.normal,
      color: context.colors.onSurface,
    );

    Widget titleWidget;
    if (isRenaming) {
      titleWidget = Text(
        '${spinnerChar ?? '...'} Generating...', // Use spinner or fallback
        style: textStyle.copyWith(
          color: context.colors.onSurface.withOpacity(0.7),
        ),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      titleWidget = Text(
        defaultTitle,
        style: textStyle,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Slidable(
      key: ValueKey(chatId),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.75, // Adjust ratio if needed
        children: [
          SlidableAction(
            onPressed: (context) => onDelete(),
            backgroundColor: context.colors.error,
            foregroundColor: context.colors.onError,
            icon: Icons.delete,
            label: 'Delete',
          ),
          SlidableAction(
            onPressed: (context) => onManualRename(),
            backgroundColor: context.colors.secondary,
            foregroundColor: context.colors.onSecondary,
            icon: Icons.edit,
            label: 'Rename',
          ),
          SlidableAction(
            onPressed: (context) => onAutoRename(),
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.onPrimary,
            icon: Icons.autorenew,
            label: 'Auto',
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.spacing.extraSmall),
        child: ListTile(
          selected:
              isCurrentChat &&
              !isMultiSelectMode, // Only visually select if not multi-selecting
          selectedTileColor: context.colors.primary.withOpacity(0.1),
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.spacing.medium,
            vertical: context.spacing.small,
          ),
          leading: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.colors.primary.withOpacity(0.7),
                  context.colors.primary,
                ],
              ),
              boxShadow: isCurrentChat ? context.shadows.medium : null,
            ),
            padding: EdgeInsets.all(context.spacing.small),
            child: Icon(Icons.chat, color: context.colors.onPrimary, size: 20),
          ),
          title: titleWidget, // Use the title widget built above
          subtitle: Text(
            formatTimestamp(timestamp), // Use imported function
            style: context.typography.body2.copyWith(
              color: context.colors.onSurface.withOpacity(0.7),
            ),
          ),
          onTap: onTap,
          onLongPress: onLongPress,
          trailing:
              isMultiSelectMode
                  ? Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color:
                        isSelected
                            ? context.colors.primary
                            : context.colors.onSurface.withOpacity(0.3),
                  )
                  : null,
        ),
      ),
    );
  }
}
