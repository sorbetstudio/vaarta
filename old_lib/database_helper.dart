import 'dart:io';
// import 'dart:math';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart'; // For generating unique chatIds

import 'main.dart'; // Import your ChatMessage class from main.dart

class DatabaseHelper {
  static const _databaseName = "ChatDatabase.db";
  static const _databaseVersion = 2; // Increment database version to trigger onUpgrade if needed

  // Tables
  static const messageTable = 'chat_messages';
  static const chatTable = 'chats';

  // Message Table Columns (existing)
  static const columnId = 'id';
  static const columnChatId = 'chatId';
  static const columnContent = 'content';
  static const columnIsUser = 'isUser';
  static const columnTimestamp = 'timestamp';

  // Chat Table Columns (NEW)
  static const chatColumnChatId = 'chatId'; // Same as columnChatId in message table, but primary key for chat table
  static const chatColumnChatName = 'chatName'; // Optional chat name
  static const chatColumnLastMessageTimestamp = 'lastMessageTimestamp';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade); // Add onUpgrade
  }

  Future _onCreate(Database db, int version) async {
    await _createMessageTable(db);
    await _createChatTable(db); // Create the new chat table
  }

  // Handle database upgrades if the version changes
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) { // Example upgrade for version 2 (if needed)
      await _createChatTable(db); // Ensure chat table exists on upgrade
    }
    // Add more upgrade logic for future versions if needed
  }

  Future<void> _createMessageTable(Database db) async {
    await db.execute('''
      CREATE TABLE $messageTable (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnChatId TEXT NOT NULL,
        $columnContent TEXT NOT NULL,
        $columnIsUser INTEGER NOT NULL,
        $columnTimestamp INTEGER NOT NULL
      )
      ''');
  }

  Future<void> _createChatTable(Database db) async {
    final sqlQuery = '''
    CREATE TABLE $chatTable (
      $chatColumnChatId TEXT PRIMARY KEY,
      $chatColumnChatName TEXT,
      $chatColumnLastMessageTimestamp INTEGER
    )
    ''';
    // print("SQL Query being executed for chat table creation: \n$sqlQuery"); // Keep the print for debugging
    await db.execute(sqlQuery);
  }


  // --- New Chat Management Functions ---

  Future<String> createNewChat() async {
    final chatId = const Uuid().v4(); // Generate a unique chatId
    Database? db = await instance.database;
    await db!.insert(
      chatTable,
      {
        chatColumnChatId: chatId,
        chatColumnChatName: 'New Chat', // Default name, can be updated later
        chatColumnLastMessageTimestamp: DateTime.now().millisecondsSinceEpoch, // Initialize timestamp
      },
    );
    return chatId;
  }

  Future<List<Map<String, dynamic>>> getAllChatsMetadata() async {
    Database? db = await instance.database;
    return await db!.query(
      chatTable,
      orderBy: '$chatColumnLastMessageTimestamp DESC', // Display recent chats first
    );
  }

  Future<void> updateChatName(String chatId, String newName) async {
    Database? db = await instance.database;
    await db!.update(
      chatTable,
      {chatColumnChatName: newName},
      where: '$chatColumnChatId = ?',
      whereArgs: [chatId],
    );
  }

  // --- Modified Message Functions (to update chat metadata on message insert) ---

  Future<int> insertMessage(ChatMessage message) async {
    Database? db = await instance.database;
    int id = await db!.insert(messageTable, _messageToMap(message));

    // Update last message timestamp for the chat
    await _updateLastMessageTimestamp(message.chatId);
    return id;
  }


  Future<void> _updateLastMessageTimestamp(String chatId) async {
    Database? db = await instance.database;
    await db!.update(
      chatTable,
      {chatColumnLastMessageTimestamp: DateTime.now().millisecondsSinceEpoch},
      where: '$chatColumnChatId = ?',
      whereArgs: [chatId],
    );
  }


  Future<List<ChatMessage>> getMessages(String chatId) async {
    Database? db = await instance.database;
    final List<Map<String, dynamic>> maps = await db!.query(
      messageTable,
      where: '$columnChatId = ?',
      whereArgs: [chatId],
      orderBy: columnTimestamp,
    );

    return List.generate(maps.length, (i) {
      return _messageFromMap(maps[i]);
    });
  }


  // Helper methods remain same ( _messageToMap, _messageFromMap )
  Map<String, dynamic> _messageToMap(ChatMessage message) {
    return {
      columnChatId: message.chatId,
      columnContent: message.content,
      columnIsUser: message.isUser ? 1 : 0,
      columnTimestamp: message.timestamp.millisecondsSinceEpoch,
    };
  }

  ChatMessage _messageFromMap(Map<String, dynamic> map) {
    return ChatMessage(
      chatId: map[columnChatId],
      content: map[columnContent],
      isUser: map[columnIsUser] == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map[columnTimestamp]),
    );
  }
}