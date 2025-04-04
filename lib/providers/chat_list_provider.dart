// lib/providers/chat_list_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaarta/services/database_helper.dart';
import 'package:logging/logging.dart';

final _logger = Logger('ChatListProvider');

/// Provider that fetches the metadata for all chats from the database.
///
/// It automatically re-fetches when refreshed.
final chatListProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  _logger.info('Fetching chat list metadata...');
  final dbHelper = DatabaseHelper.instance;
  try {
    final chats = await dbHelper.getAllChatsMetadata();
    _logger.info('Successfully fetched ${chats.length} chats.');
    return chats;
  } catch (e) {
    _logger.severe('Error fetching chat list metadata: $e');
    throw Exception('Failed to load chat list: $e');
  }
});
