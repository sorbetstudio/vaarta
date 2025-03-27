// lib/screens/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vaarta/router/app_router.dart';
import '../services/database_helper.dart';
import 'package:vaarta/screens/chat_screen.dart';
import 'package:vaarta/theme/theme_extensions.dart';
import 'package:vaarta/theme/icons/app_icons.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _chatList = [];
  final dbHelper = DatabaseHelper.instance;
  Set<String> _selectedChats = {};
  bool _isMultiSelectMode = false;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  _loadChats() async {
    final chats = await dbHelper.getAllChatsMetadata();
    setState(() {
      _chatList = chats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _isMultiSelectMode ? 'Select Chats' : 'Chats',
        style: context.typography.h6.copyWith(color: context.colors.onSurface),
      ),
      backgroundColor: context.colors.surface,
      elevation: 0,
      actions: [
        if (_isMultiSelectMode) ...[
          IconButton(
            icon: Icon(Icons.delete, color: context.colors.error),
            onPressed: _deleteSelectedChats,
            tooltip: 'Delete Selected',
          ),
          IconButton(
            icon: Icon(Icons.close, color: context.colors.onSurface),
            onPressed: () {
              setState(() {
                _isMultiSelectMode = false;
                _selectedChats.clear();
              });
            },
            tooltip: 'Cancel Selection',
          ),
        ] else
          IconButton(
            icon: Icon(Icons.add, color: context.colors.onSurface),
            onPressed: _startNewChat,
            tooltip: 'New Chat',
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_chatList.isEmpty) {
      return Center(
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
              style: context.typography.h5.copyWith(
                color: context.colors.onBackground.withOpacity(0.6),
              ),
            ),
            SizedBox(height: context.spacing.small),
            ElevatedButton.icon(
              onPressed: _startNewChat,
              icon: const Icon(Icons.add),
              label: const Text('Start a new chat'),
              style: ElevatedButton.styleFrom(
                foregroundColor: context.colors.onPrimary,
                backgroundColor: context.colors.primary,
                elevation: 4,
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.large,
                  vertical: context.spacing.small,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.radius.medium),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        itemCount: _chatList.length,
        padding: EdgeInsets.all(context.spacing.small),
        itemBuilder: (context, index) {
          final chatMetadata = _chatList[index];
          return _buildChatItem(chatMetadata);
        },
      );
    }
  }

  Widget _buildChatItem(Map<String, dynamic> chatMetadata) {
    final chatId = chatMetadata[DatabaseHelper.chatColumnChatId];
    final isSelected = _selectedChats.contains(chatId);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.extraSmall),
      child: Card(
        elevation: 2,
        shadowColor: context.colors.onBackground.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.radius.medium),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.spacing.medium,
            vertical: context.spacing.small,
          ),
          leading: _buildChatAvatar(),
          title: Text(
            chatMetadata[DatabaseHelper.chatColumnChatName] ?? 'Chat',
            style: context.typography.body1.copyWith(
              fontWeight: FontWeight.w500,
              color: context.colors.onSurface,
            ),
          ),
          subtitle: Text(
            _formatTimestamp(
              DateTime.fromMillisecondsSinceEpoch(
                chatMetadata[DatabaseHelper.chatColumnLastMessageTimestamp] ??
                    0,
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
              _openChat(chatId);
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
                  ? isSelected
                      ? Icon(Icons.check_circle, color: context.colors.primary)
                      : Icon(
                        Icons.radio_button_unchecked,
                        color: context.colors.onSurface.withOpacity(0.3),
                      )
                  : Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: context.colors.onSurface.withOpacity(0.5),
                  ),
        ),
      ),
    );
  }

  Widget _buildChatAvatar() {
    return Container(
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
        boxShadow: context.shadows.small,
      ),
      padding: EdgeInsets.all(context.spacing.small),
      child: Icon(Icons.chat, color: context.colors.onPrimary, size: 20),
    );
  }

  Widget _buildFloatingActionButton() {
    if (_chatList.isNotEmpty) {
      return FloatingActionButton(
        onPressed: _startNewChat,
        tooltip: 'New Chat',
        elevation: 4,
        backgroundColor: context.colors.primary,
        child: Icon(Icons.add, color: context.colors.onPrimary),
      );
    }
    return const SizedBox.shrink();
  }

  void _startNewChat() async {
    AppRouter.navigateToNewChat(context);
  }

  void _openChat(String chatId) {
    context.go(AppRouter.chatPath(chatId));
  }

  void _deleteSelectedChats() async {
    // Show a confirmation dialog using the theme
    bool confirm =
        await showDialog(
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
                    child: Text(
                      'Cancel',
                      style: context.typography.button.copyWith(
                        color: context.colors.secondary,
                      ),
                    ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.radius.medium),
                ),
                backgroundColor: context.colors.surface,
              ),
        ) ??
        false;

    if (confirm) {
      for (final chatId in _selectedChats) {
        await dbHelper.deleteChat(chatId);
      }
      setState(() {
        _selectedChats.clear();
        _isMultiSelectMode = false;
      });
      _loadChats();
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
