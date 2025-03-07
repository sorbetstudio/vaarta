import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../main.dart'; // Assuming main.dart is in the parent directory
import 'package:vaarta/screens/chat_screen.dart'; // Explicit import path


class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _chatList = [];
  final dbHelper = DatabaseHelper.instance;
  Set<String> _selectedChats = {}; // Store selected chat IDs
  bool _isMultiSelectMode = false; // Track multi-select mode


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
    Future<void> _deleteChat(String chatId) async {
        await dbHelper.deleteChat(chatId);

        _loadChats();
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
        _isMultiSelectMode ? 'Select Chats' : 'Chats', // Change title based on mode
        style: const TextStyle(
          fontFamily: 'Arial',
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.black,
      elevation: 0,
      actions: [
        if (_isMultiSelectMode) ...[ // Show these actions only in multi-select mode
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteSelectedChats,
            tooltip: 'Delete Selected',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
                setState(() {
                _isMultiSelectMode = false; // Exit multi-select mode
                _selectedChats.clear();    // Clear selections
                });
            },
            tooltip: 'Cancel Selection',
          ),
        ] else
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
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
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "No chats yet",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _startNewChat,
              icon: const Icon(Icons.add),
              label: const Text('Start a new chat'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: const Color(0xFF007BFF), // Example button color
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        itemCount: _chatList.length,
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
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: _buildChatAvatar(),
          title: Text(
            chatMetadata[DatabaseHelper.chatColumnChatName] ?? 'Chat',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(_formatTimestamp(DateTime.fromMillisecondsSinceEpoch(
            chatMetadata[DatabaseHelper.chatColumnLastMessageTimestamp] ?? 0,
          ))),
            onTap: () {
            if (_isMultiSelectMode) {
                setState(() {
                if (isSelected) {
                    _selectedChats.remove(chatId);
                } else {
                    _selectedChats.add(chatId);
                }
                if (_selectedChats.isEmpty) {
                    _isMultiSelectMode = false; // Exit multi-select if no chats selected
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
            trailing: _isMultiSelectMode
              ? isSelected
                  ? Icon(Icons.check_circle, color: Colors.blue) // Show checkmark if selected
                  : Icon(Icons.radio_button_unchecked) // Show unchecked circle if not selected
              : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
          colors: [Colors.grey.shade300, Colors.grey.shade400],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: const Icon(Icons.chat, color: Colors.white),
    );
  }


  Widget _buildFloatingActionButton() {
    if (_chatList.isNotEmpty) {
      return FloatingActionButton(
        onPressed: _startNewChat,
        tooltip: 'New Chat',
        elevation: 4,
        backgroundColor: const Color(0xFF007BFF), // Example FAB color
        child: const Icon(Icons.add, color: Colors.white),
      );
    }
    return const SizedBox.shrink(); // Return an empty widget instead of null
  }

  void _startNewChat() async {
    String newChatId = await dbHelper.createNewChat();
    _openChat(newChatId);
  }

  void _openChat(String chatId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatId: chatId), // Assuming ChatScreen is defined elsewhere
      ),
    );
  }
    void _deleteSelectedChats() async {
    for (final chatId in _selectedChats) {
      await dbHelper.deleteChat(chatId);
    }
    setState(() {
      _selectedChats.clear();
      _isMultiSelectMode = false;
    });
    _loadChats(); // Refresh the chat list
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