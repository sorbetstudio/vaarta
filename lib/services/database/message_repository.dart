import 'package:sqflite/sqflite.dart';
import 'package:vaarta/models/messages/chat_message.dart';
import 'package:vaarta/services/database_helper.dart';

class MessageRepository {
  final DatabaseHelper _dbHelper;

  MessageRepository(this._dbHelper);

  Future<int> insertMessage(ChatMessage message) async {
    Database? db = await _dbHelper.database;
    int id = await db!.insert(
      DatabaseHelper.messageTable,
      _messageToMap(message),
    );
    return id;
  }

  Future<void> updateMessage(ChatMessage message) async {
    Database? db = await _dbHelper.database;
    await db!.update(
      DatabaseHelper.messageTable,
      _messageToMap(message),
      where:
          '${DatabaseHelper.columnChatId} = ? AND ${DatabaseHelper.columnTimestamp} = ?',
      whereArgs: [message.chatId, message.timestamp.millisecondsSinceEpoch],
    );
  }

  Future<List<ChatMessage>> getMessages(String chatId) async {
    Database? db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db!.query(
      DatabaseHelper.messageTable,
      where: '${DatabaseHelper.columnChatId} = ?',
      whereArgs: [chatId],
      orderBy: '${DatabaseHelper.columnTimestamp} ASC',
    );

    return List.generate(maps.length, (i) {
      return _messageFromMap(maps[i]);
    });
  }

  Future<void> deleteMessagesByChatId(String chatId) async {
    Database? db = await _dbHelper.database;
    await db!.delete(
      DatabaseHelper.messageTable,
      where: '${DatabaseHelper.columnChatId} = ?',
      whereArgs: [chatId],
    );
  }

  Future<void> clearAllMessages() async {
    Database? db = await _dbHelper.database;
    await db!.delete(DatabaseHelper.messageTable);
  }

  /// Deletes all messages for a specific chat with a timestamp greater than or equal to the provided timestamp.
  Future<void> deleteMessagesFrom(String chatId, DateTime timestamp) async {
    Database? db = await _dbHelper.database;
    await db!.delete(
      DatabaseHelper.messageTable,
      where:
          '${DatabaseHelper.columnChatId} = ? AND ${DatabaseHelper.columnTimestamp} >= ?',
      whereArgs: [chatId, timestamp.millisecondsSinceEpoch],
    );
  }

  Map<String, dynamic> _messageToMap(ChatMessage message) {
    return {
      DatabaseHelper.columnChatId: message.chatId,
      DatabaseHelper.columnContent: message.content,
      DatabaseHelper.columnIsUser: message.isUser ? 1 : 0,
      DatabaseHelper.columnTimestamp: message.timestamp.millisecondsSinceEpoch,
    };
  }

  ChatMessage _messageFromMap(Map<String, dynamic> map) {
    return ChatMessage(
      chatId: map[DatabaseHelper.columnChatId],
      content: map[DatabaseHelper.columnContent],
      isUser: map[DatabaseHelper.columnIsUser] == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map[DatabaseHelper.columnTimestamp],
      ),
    );
  }
}
