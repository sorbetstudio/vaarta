// lib/widgets/chat_drawer.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vaarta/router/app_router.dart';
import 'package:vaarta/services/database_helper.dart';
import 'package:vaarta/theme/theme_extensions.dart';

class ChatDrawer extends StatefulWidget {
  final String currentChatId;
  final VoidCallback onNewChat;

  const ChatDrawer({
    super.key,
    required this.currentChatId,
    required this.onNewChat,
  });

  @override
  State<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends State<ChatDrawer> {
  List<Map<String, dynamic>> _chatList = [];
  bool _isLoading = true;
  Set<String> _selectedChats = {};
  bool _isMultiSelectMode = false;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    final dbHelper = DatabaseHelper.instance;
    final chats = await dbHelper.getAllChatsMetadata();

    if (mounted) {
      setState(() {
        _chatList = chats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: context.colors.background,
      child: Column(
        children: [
          _buildDrawerHeader(context),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_chatList.isEmpty)
            _buildEmptyState(context)
          else
            Expanded(child: _buildChatList(context)),
          _buildDrawerFooter(context),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(color: context.colors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chats',
                style: context.typography.h5.copyWith(
                  color: context.colors.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isMultiSelectMode)
                IconButton(
                  icon: Icon(Icons.close, color: context.colors.onPrimary),
                  onPressed: () {
                    setState(() {
                      _isMultiSelectMode = false;
                      _selectedChats.clear();
                    });
                  },
                ),
            ],
          ),
          const Spacer(),
          if (_isMultiSelectMode && _selectedChats.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _deleteSelectedChats,
              icon: const Icon(Icons.delete),
              label: Text('Delete (${_selectedChats.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.error,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: context.colors.onBackground.withOpacity(0.4),
            ),
            SizedBox(height: context.spacing.medium),
            Text(
              "No chats yet",
              style: context.typography.body1.copyWith(
                color: context.colors.onBackground.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context) {
    return ListView.builder(
      itemCount: _chatList.length,
      padding: EdgeInsets.all(context.spacing.small),
      itemBuilder: (context, index) {
        final chatMetadata = _chatList[index];
        return _buildChatItem(context, chatMetadata);
      },
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    Map<String, dynamic> chatMetadata,
  ) {
    final chatId = chatMetadata[DatabaseHelper.chatColumnChatId];
    final isSelected = _selectedChats.contains(chatId);
    final isCurrentChat = chatId == widget.currentChatId;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.extraSmall),
      child: ListTile(
        selected: isCurrentChat,
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
        title: Text(
          chatMetadata[DatabaseHelper.chatColumnChatName] ?? 'Chat',
          style: context.typography.body1.copyWith(
            fontWeight: isCurrentChat ? FontWeight.bold : FontWeight.normal,
            color: context.colors.onSurface,
          ),
        ),
        subtitle: Text(
          _formatTimestamp(
            DateTime.fromMillisecondsSinceEpoch(
              chatMetadata[DatabaseHelper.chatColumnLastMessageTimestamp] ?? 0,
            ),
          ),
          style: context.typography.body2.copyWith(
            color: context.colors.onSurface.withOpacity(0.7),
          ),
        ),
        onTap: () {
          if (_isMultiSelectMode) {
            setState(() {
              if (isSelected) {
                _selectedChats.remove(chatId);
              } else {
                _selectedChats.add(chatId);
              }
              if (_selectedChats.isEmpty) {
                _isMultiSelectMode = false;
              }
            });
          } else {
            // Navigate to the chat
            context.go(AppRouter.chatPath(chatId));
            // Close the drawer
            Navigator.pop(context);
          }
        },
        onLongPress: () {
          setState(() {
            _isMultiSelectMode = true;
            _selectedChats.add(chatId);
          });
        },
        trailing:
            _isMultiSelectMode
                ? Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color:
                      isSelected
                          ? context.colors.primary
                          : context.colors.onSurface.withOpacity(0.3),
                )
                : null,
      ),
    );
  }

  Widget _buildDrawerFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.spacing.medium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              widget.onNewChat();
              Navigator.pop(context); // Close drawer
            },
            icon: const Icon(Icons.add),
            label: const Text('New Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: context.colors.primary),
            onPressed: () {
              Navigator.pop(context); // Close drawer
              context.push(AppRouter.settings);
            },
          ),
        ],
      ),
    );
  }

  void _deleteSelectedChats() async {
    final dbHelper = DatabaseHelper.instance;

    // Show confirmation dialog
    bool confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Delete Chats', style: context.typography.h6),
                content: Text(
                  'Are you sure you want to delete ${_selectedChats.length} ${_selectedChats.length == 1 ? "chat" : "chats"}?',
                  style: context.typography.body1,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel', style: context.typography.button),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'Delete',
                      style: context.typography.button.copyWith(
                        color: context.colors.error,
                      ),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    // Handle case when current chat is being deleted
    final currentChatDeleted = _selectedChats.contains(widget.currentChatId);

    // Delete the selected chats
    for (final chatId in _selectedChats) {
      await dbHelper.deleteChat(chatId);
    }

    // Reload the chat list
    _loadChats();

    setState(() {
      _selectedChats.clear();
      _isMultiSelectMode = false;
    });

    // If current chat was deleted, navigate to another chat or create a new one
    if (currentChatDeleted && context.mounted) {
      if (_chatList.isNotEmpty && _chatList.length > _selectedChats.length) {
        // Find the first non-deleted chat
        String nextChatId = '';
        for (final chat in _chatList) {
          final id = chat[DatabaseHelper.chatColumnChatId];
          if (!_selectedChats.contains(id)) {
            nextChatId = id;
            break;
          }
        }

        if (nextChatId.isNotEmpty) {
          context.go(AppRouter.chatPath(nextChatId));
        } else {
          AppRouter.navigateToNewChat(context);
        }
      } else {
        AppRouter.navigateToNewChat(context);
      }

      if (context.mounted) {
        Navigator.pop(context); // Close drawer
      }
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? "day" : "days"} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? "hour" : "hours"} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? "minute" : "minutes"} ago';
    } else {
      return 'Just now';
    }
  }
}
