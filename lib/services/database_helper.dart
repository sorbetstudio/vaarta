import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "ChatDatabase.db";
  static const _databaseVersion = 2;

  // Tables
  static const messageTable = 'chat_messages';
  static const chatTable = 'chats';

  // Message Table Columns
  static const columnId = 'id';
  static const columnChatId = 'chatId';
  static const columnContent = 'content';
  static const columnIsUser = 'isUser';
  static const columnTimestamp = 'timestamp';

  // Chat Table Columns
  static const chatColumnChatId = 'chatId';
  static const chatColumnChatName = 'chatName';
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
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await _createMessageTable(db);
    await _createChatTable(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createChatTable(db);
    }
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
    await db.execute('''
      CREATE TABLE $chatTable (
        $chatColumnChatId TEXT PRIMARY KEY,
        $chatColumnChatName TEXT,
        $chatColumnLastMessageTimestamp INTEGER
      )
    ''');
  }
}
