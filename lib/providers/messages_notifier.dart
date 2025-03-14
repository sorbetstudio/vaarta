import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vaarta/models/models.dart'; // Make sure this import is correct

part 'messages_notifier.g.dart';

@riverpod
class MessagesNotifier extends _$MessagesNotifier {
  @override
  List<ChatMessage> build(String chatId) {
    return [];
  }

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void updateMessage(ChatMessage updatedMessage) {
    state = [
      for (final message in state)
        if (message.timestamp == updatedMessage.timestamp) updatedMessage else message,
    ];
  }

  void removeMessage(ChatMessage messageToRemove) {
    state = state.where((message) => message.timestamp != messageToRemove.timestamp).toList();
  }
}