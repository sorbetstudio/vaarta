import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'main.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _chatList = [];
  final dbHelper = DatabaseHelper.instance;

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _startNewChat,
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: _chatList.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "No chats yet",
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _startNewChat,
              icon: const Icon(Icons.add),
              label: const Text('Start a new chat'),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _chatList.length,
        itemBuilder: (context, index) {
          final chatMetadata = _chatList[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.chat,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(chatMetadata[DatabaseHelper.chatColumnChatName] ?? 'Chat'),
            subtitle: Text(_formatTimestamp(DateTime.fromMillisecondsSinceEpoch(
              chatMetadata[DatabaseHelper.chatColumnLastMessageTimestamp] ?? 0,
            ))),
            onTap: () {
              _openChat(chatMetadata[DatabaseHelper.chatColumnChatId]);
            },
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          );
        },
      ),
      floatingActionButton: _chatList.isEmpty
          ? null
          : FloatingActionButton(
        onPressed: _startNewChat,
        tooltip: 'New Chat',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _startNewChat() async {
    String newChatId = await dbHelper.createNewChat();
    _openChat(newChatId);
  }

  void _openChat(String chatId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatId: chatId),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
