// Represents a single chat message in the app
class ChatMessage {
  final String chatId; // Unique identifier for the chat
  final String content; // Message text
  final bool isUser; // Indicates if the message is from the user
  final DateTime timestamp; // When the message was sent

  ChatMessage({
    required this.chatId,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  // Creates a copy of the message with optional overrides
  ChatMessage copyWith({
    String? chatId,
    String? content,
    bool? isUser,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      chatId: chatId ?? this.chatId,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}