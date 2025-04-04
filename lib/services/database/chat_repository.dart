import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:vaarta/services/database_helper.dart';

class ChatRepository {
  final DatabaseHelper _dbHelper;

  ChatRepository(this._dbHelper);

  Future<String> createNewChat() async {
    final chatId = const Uuid().v4();
    Database? db = await _dbHelper.database;
    await db!.insert(DatabaseHelper.chatTable, {
      DatabaseHelper.chatColumnChatId: chatId,
      DatabaseHelper.chatColumnChatName: 'New Chat',
      DatabaseHelper.chatColumnLastMessageTimestamp:
          DateTime.now().millisecondsSinceEpoch,
    });
    return chatId;
  }

  Future<List<Map<String, dynamic>>> getAllChatsMetadata() async {
    Database? db = await _dbHelper.database;
    return await db!.query(
      DatabaseHelper.chatTable,
      orderBy: '${DatabaseHelper.chatColumnLastMessageTimestamp} DESC',
    );
  }

  Future<Map<String, dynamic>?> getChatMetadata(String chatId) async {
    Database? db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db!.query(
      DatabaseHelper.chatTable,
      where: '${DatabaseHelper.chatColumnChatId} = ?',
      whereArgs: [chatId],
      limit: 1,
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<void> updateChatName(String chatId, String newName) async {
    Database? db = await _dbHelper.database;
    await db!.update(
      DatabaseHelper.chatTable,
      {DatabaseHelper.chatColumnChatName: newName},
      where: '${DatabaseHelper.chatColumnChatId} = ?',
      whereArgs: [chatId],
    );
  }

  Future<void> deleteChat(String chatId) async {
    Database? db = await _dbHelper.database;
    await db!.delete(
      DatabaseHelper.chatTable,
      where: '${DatabaseHelper.chatColumnChatId} = ?',
      whereArgs: [chatId],
    );
  }

  Future<void> updateLastMessageTimestamp(String chatId) async {
    Database? db = await _dbHelper.database;
    await db!.update(
      DatabaseHelper.chatTable,
      {
        DatabaseHelper.chatColumnLastMessageTimestamp:
            DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DatabaseHelper.chatColumnChatId} = ?',
      whereArgs: [chatId],
    );
  }
}
